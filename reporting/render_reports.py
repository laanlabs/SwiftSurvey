#!/usr/bin/env python
# coding: utf-8


import numpy as np
import firebase_admin
from firebase_admin import credentials

import json
import os
import time
from glob import glob
import copy

from collections import defaultdict
from collections import OrderedDict

from pprint import pprint

from jinja2 import Template
import datetime



Q_MULTIPLE_CHOICE = 0 
Q_BINARY_CHOICE = 1
Q_CONTACT_FORM = 2 
Q_INLINE_GROUP = 3 
Q_COMMENTS_FORM = 4     



def trim_surveys(surveys):
    # Takes the original survey json and simplifies it a bit
    # returns:
    #   [  {"uuid" : "1234", "questions": [] }]
    # 
    # where each question now has a survey_uuid and type at top levels 
    # also flattens out the Inline question groups to be individual questions
    
    surveys_simple = []
    for uuid, survey_response in surveys.items():

        questions = []

        if 'createdAt' in survey_response:
            created_at = datetime.datetime.strptime(survey_response['createdAt'], '%Y-%m-%dT%H:%M:%SZ')
        else:
            created_at = datetime.datetime(2020, 1, 1)

        survey_out = {"uuid" : uuid, "questions": questions, "created" : created_at}
        surveys_simple.append(survey_out)
        
        for question in survey_response['response']['questions']:
            qtype = question['type']
            if qtype == Q_INLINE_GROUP:
                for sub_question in question['question']['questions']:
                    sub_question['survey_uuid'] = uuid
                    sub_question['type'] = qtype
                    sub_question['created'] = created_at
                    questions.append(sub_question)
            else:
                question = question['question']
                question['survey_uuid'] = uuid
                question['type'] = qtype
                question['created'] = created_at
                questions.append(question)
                
    return surveys_simple             


def annotate_answered_questions(surveys):
    # In-place adds "answered" : Bool key/val to each question in the survey 
    # NOTE: only applies to multiple choice / binary / importance 
    num_unanswered = 0
    total_questions = 0

    for survey in surveys:
        for question in survey['questions']:
            total_questions += 1
            if 'choices' not in question:
                assert( question['type'] in (Q_COMMENTS_FORM, Q_CONTACT_FORM) )
                continue
            num_selected = sum( c['selected'] for c in question['choices'] )
            question["answered"] = num_selected > 0
            if num_selected == 0:
                num_unanswered += 1

    print(f"{num_unanswered} / {total_questions} unanswered")


def get_stats_for_surveys(surveys):
    assert len(surveys) > 0, "No surveys"
    
    surveys = copy.deepcopy(surveys)
    annotate_answered_questions(surveys)
    
    def init_accum(q):
        for c in q['choices']:
            c['selected_count'] = 0 
            if c['allowsCustomTextEntry']:
                c['all_text'] = []
        q['answered_count'] = 0
        q['count'] = 0 
        q['total_selection_count'] = 0
        return q
    
    
    # Get all unique question tags
    unique_questions_by_tag = {}
    for s in surveys:
        for q in s['questions']:
            unique_questions_by_tag[q['tag']] = q
    

    base_questions = copy.deepcopy( list(unique_questions_by_tag.values()) )
    base_questions = list(filter( lambda q : 'choices' in q, base_questions))

    base_questions = list(map(init_accum, base_questions))
    
    for base_q in base_questions:
        for s in surveys:
            for q in s['questions']:

                if base_q['uuid'] == q['uuid']:

                    base_q['count'] += 1

                    if q['answered']:
                        base_q['answered_count'] += 1
                    else:
                        continue

                    for base_c, c in zip(base_q['choices'], q['choices']):
                        assert base_c['uuid'] == c['uuid']

                        base_c['selected_count'] += int(c['selected'])
                        base_q['total_selection_count'] += int(c['selected'])

                        if c['allowsCustomTextEntry'] and c['selected'] and 'customTextEntry' in c:
                            base_c['all_text'].append(c['customTextEntry'])


            # update percentages
            for base_c in base_q['choices']:
#                 if base_q['total_selection_count'] > 0:
#                     base_c['selection_percent'] = base_c['selected_count'] / base_q['total_selection_count']
                if base_q['answered_count'] > 0:
                    base_c['selection_percent'] = base_c['selected_count'] / base_q['answered_count']
                else:
                    base_c['selection_percent'] = 0


            base_q['answered_percent'] = base_q['answered_count'] / base_q['count']
        
    return base_questions
    


def get_choice(question, contains_text=None, with_uuid=None):
    for c in question['choices']:
        if contains_text is not None:
            if contains_text.lower() in c['text'].lower():
                return c
        elif with_uuid is not None:
            if with_uuid.lower() == c['uuid'].lower():
                return c
    assert False, "No choice found"
                
    
def get_question(survey, tag):
    for q in survey['questions']:
        if q['tag'].lower() == tag.lower():
            return q
    assert False, "No question found"
        



HTML_TEMPLATE_STATS = """
<!DOCTYPE html>


<html>
  <head>
    <title>{{title}}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="http://netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" rel="stylesheet" media="screen">
    <style type="text/css">
      .container {
        max-width: 840px;
        padding: 40px;
        background-color: #fff;
      }
      body {
          background-color: #f6f6fa;
      }
      
    </style>
  </head>
  <body>

    <script>      
      setTimeout(function(){
       window.location.reload(1);
        }, 200000);
      </script>
      
    <div class="container">
        
        <h1 style='padding: 4px; border-bottom: 4px solid #ffcc00; background-color: #fff5db;'>{{title}}</h1>
        
        
        <h3 style='color: #888;'> {{ num_surveys }} Surveys </h3>
        <br/>
    
        
        {% if comments is defined %}

            <h2 style='padding: 4px; border-bottom: 4px solid #03fc88; background-color: #cfffe8;'> Comments / feedback - {{ comments | length }} </h2>
            
            {% for question in comments %}
                <div
                style='padding: 12px; margin-bottom: 12px; border-top: 2px; border: 1px solid #ddd; border-radius: 8px;'> 
                    {% if 'link' in question %}
                    <div> <b>UUID: </b> <a href='{{ question['link'] }}'>{{ question['survey_uuid'] }}</a> </div>
                    {% else %}
                    <div> <b>UUID: </b> {{ question['survey_uuid'] }} </div>
                    {% endif %}
                    
                    <div> <b>Email: </b> {{ question['emailAddress'] }} </div>
                    <div> <b>Date: </b> {{ question['created'] }} </div>
                    <div> <b>Feedback: </b> {{ question['feedback'] }} </div>
                </div>
            {% endfor %}
        <br/>
        {% endif %}
            
        
        
        {% if contacts is defined %}

            <h2 style='padding: 4px; border-bottom: 4px solid #fc03a1; background-color: #ffdbf2;'> Contact Forms - {{ contacts | length }}</h2>
            
            {% for question in contacts %}
                <div style='padding: 12px; margin-bottom: 12px; border-top: 2px; border: 1px solid #ddd; border-radius: 8px;'> 
                    
                    {% if 'link' in question %}
                    <div> <b>UUID: </b> <a href='{{ question['link'] }}'>{{ question['survey_uuid'] }}</a> </div>
                    {% else %}
                    <div> <b>UUID: </b> {{ question['survey_uuid'] }} </div>
                    {% endif %}
                    
                    
                    <div> <b>Email: </b> {{ question['emailAddress'] }} </div>
                    <div> <b>Date: </b> {{ question['created'] }} </div>
                    <div> <b>Name: </b> {{ question['name'] }} </div>
                    <div> <b>Company: </b> {{ question['company'] }} </div>
                    <div> <b>Phone: </b> {{ question['phoneNumber'] }} </div>
                    <div> <b>Feedback: </b> {{ question['feedback'] }} </div>
                </div>
            {% endfor %}
        
        <br/>
        
        {% endif %}


        <h2 style='padding: 4px; border-bottom: 4px solid #0377fc; background-color: #c4e0ff;'>Questions - {{ questions|length }}</h2> 
        
        {% for question in questions %}
        
          <div style='padding: 20px; margin-bottom: 20px; border-top: 2px; border: 1px solid #ddd; border-radius: 12px;'> 
              <h3> {{question['title']}}</h3>
              <i style='margin-left:15px;'> {{ "%.0f%%"|format(question['answered_percent']*100) }} users answered</i>

              {% for choice in question['choices'] %}
                  
                  <div style='padding-left: 20px; padding-top: 10px;'>
                     <h4> • {{ choice['text'] }} </h4>
                  </div>
                  
                    <div style='margin-left:34px; padding: 4px;'>
                        <b>{{ "%.0f%%"|format(choice['selection_percent']*100) }}</b>
                             <span style='padding-left:10px; color: #888;'> ( {{choice['selected_count']}} users ) </span>
                    </div>
                    
                  <div class="progress" style='margin-left: 34px;'>
                      <div class="progress-bar" role="progressbar" aria-valuenow="70"
                      aria-valuemin="0" aria-valuemax="100" style="width:{{ choice['selection_percent']*100 }}%">                        
                      </div>
                  </div>
                  
                  {% if choice.allowsCustomTextEntry %}
                  
                      {% for other_text in choice.all_text %}
                        <div style='padding-left:45px;'> • {{other_text}} </div>
                      {% endfor %}
                  
                  {% endif %}

                  
              {% endfor %}
              
          </div>
        {% endfor %}
              
    </div>
    <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
    <script src="http://netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js"></script>
  </body>
</html>
"""



def render_all_reports(surveys, open=True):
    
    base_dir = time.strftime("report_%m-%d_%H-%M-%S")
    os.makedirs(base_dir, exist_ok=1)
    
    
    contact_info_surveys = list(filter( has_contact_info, surveys))
    feedback_surveys = list(filter( has_feedback, surveys))
    
    
    
    
    # Render a report for contacts
    contacts_dir = os.path.join(base_dir, "contacts")
    os.makedirs(contacts_dir, exist_ok=1)
    
    contacts = []
    for survey in contact_info_surveys:
        filename = os.path.join(contacts_dir, survey['uuid'] + ".html")
        
        contact_q = get_question(survey, tag="contact-form")
        
        render_report([survey], filename=filename, show_comments=1, show_contacts=1, title="Single Survey")
        
        # add link info 
        contact_q = copy.deepcopy(contact_q)
        contact_q['link'] = os.path.relpath(filename, base_dir)
        contacts.append(contact_q)
    
    
    # Render all feedback/comments
    feedback_dir = os.path.join(base_dir, "feedback")
    os.makedirs(feedback_dir, exist_ok=1)
    comments = []
    for survey in feedback_surveys:
        filename = os.path.join(feedback_dir, survey['uuid'] + ".html")
        
        feedback_q = get_question(survey, tag="feedback-comments-form")
        
        render_report([survey], filename=filename, show_comments=1, show_contacts=1, title="Single Survey")
        
        # add link info 
        feedback_q = copy.deepcopy(feedback_q)
        feedback_q['link'] = os.path.relpath(filename, base_dir)
        comments.append(feedback_q)
    
    
    
    links = OrderedDict()
    
    # Render Stats for all surveys 
    filename = os.path.join(base_dir, "report.html")
    render_report(surveys, filename=filename, contacts=contacts, comments=comments, open=open, links=links )
    
        

def render_report(surveys, filename="report.html", title="Survey Results", 
                  show_comments=False, show_contacts=False,
                  open=False, **kwargs):
    
    question_stats = get_stats_for_surveys(surveys)
    
    if show_comments:
        comments = []
        for s in surveys:
            if has_feedback(s):
                q = get_question(s, tag="feedback-comments-form")
                comments.append(q)
                #comments.append( dict(email=q['emailAddress'], feedback=q['feedback']) )
        if len(comments):
            kwargs['comments'] = comments
        
    if show_contacts:
        contacts = []
        for s in surveys:
            if has_contact_info(s):
                contacts.append(get_question(s, tag="contact-form"))
        if len(contacts):
            kwargs['contacts'] = contacts

    render_template(HTML_TEMPLATE_STATS, filename, questions=question_stats, 
                    title=title, num_surveys=len(surveys), **kwargs)
    if open:
        os.system(f"open {filename}")
        
def render_template(template, filename, **kwargs):
    html = Template(template).render(**kwargs)
    with open(filename, "w") as f:
        f.write(html)
    #display(HTML(html))


# ## Basic filters 

def has_feedback(survey):
    q = get_question(survey, tag="feedback-comments-form")
    return len(q['emailAddress']) or len(q['feedback'])

def has_contact_info(survey):
    q = get_question(survey, tag="contact-form")
    return len(q['emailAddress']) or len(q['company']) or            len(q['name']) or len(q['phoneNumber']) or            len(q['feedback'])


def get_firebase_surveys():

    cred = credentials.Certificate(CREDENTIALS_JSON)
    default_app = firebase_admin.initialize_app(cred, {'databaseURL':FIREBASE_DATABASE_URL })

    from firebase_admin import db
    ref = db.reference("/surveys")

    # Retrieve surveys from db
    surveys = ref.get()

    # ## Flatten out data a bit
    surveys_all = trim_surveys(surveys)
    return surveys_all


def get_sample_surveys():

    # these are json files as output by encoding the Survey directly via Codable in swift 

    survey_files = glob("./sample_responses/*.json")
    surveys = list(map( lambda s : json.load(open(s, "r")) , survey_files ))

    # modify to look like our firebase data by adding 'uuid' so we can reuse this function
    surveys = { os.path.basename(path) : {"response" : survey} for survey , path in zip(surveys, survey_files)}

    return trim_surveys(surveys)


def run_all():

    #surveys_all = get_firebase_surveys()
    surveys_all = get_sample_surveys()

    # Sort by newest first
    surveys_all = sorted(surveys_all, key = lambda s : -s['created'].timestamp())

    # ## Render All Reports 
    # ( makes new directory each time fyi )
    render_all_reports(surveys_all, open=True)



if __name__ == '__main__':
    run_all()



