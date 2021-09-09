# SwiftSurvey

Very basic SwiftUI iOS Survey using Codable with demo firebase / html report

*Light mode only currently*



### WARNING ###

> This project was created quickly over 1-2 days to get something working for our use case.
> It's also our first SwiftUI project. There will be bugs and poor coding choices.
> Feel free to submit pull requests, or fork and refactor.


<img src="/media/survey-animation.gif" width="270"/>


### Why? ###
We evaluated a few web based surveys; none of them satisfied all of our needs, and most cost money.

Rough Goals:
- Simple to use / setup
- Native iOS
- Open source / customizable 
    -  Custom question types / UI
- Access to survey results locally on device
- Basic logic to show additional questions based on answers to previous questions
- Free

Since we are developers, we did not bother with a GUI to create the survey, defining it in Swift is fairly easy to do.


## Installation ## 

Clone or download this repo; the only files you need are: 
- SurveyHelper.swift
- SurveyModelClass.swift
- SurveyView.swift



## Usage ## 

Currently the only way to create a survey is with Swift code or JSON. 
You can create the survey in Swift and save it to a JSON file for loading from disk / server.


### Define a Survey ### 

With Swift code:
```swift
let SampleSurvey = Survey([
    
    MultipleChoiceQuestion(title: "What are you primarily using our app for?",
                                          items: [
                                            "Work",
                                            "Fun",
                                            "Just trying it out",
                                            MultipleChoiceResponse("Other", allowsCustomTextEntry: true)
                                          ], multiSelect: true,
                                          tag: "what-using-for"),
                                          
                                          
    BinaryQuestion(title: "Would you like to be contacted about new features?" , answers: ["Yes", "No"],
                    tag: "contact-us")
                    
                                          
                                          
])

```

With JSON:

```json
{
  "version" : "001",
  "questions" : [
    {
      "type" : 0,
      "question" : {
        "tag" : "what-using-for",
        "allowsMultipleSelection" : true,
        "title" : "What are you primarily using our app for?",
        "required" : false,
        "choices" : [
          {
            "uuid" : "D0E16757-CA82-4882-8C1B-5B773DFB33A5",
            "selected" : false,
            "allowsCustomTextEntry" : false,
            "text" : "Work"
          },
          {
            "uuid" : "6D05B7DD-95B8-4C49-97CD-665163DBA754",
            "selected" : false,
            "allowsCustomTextEntry" : false,
            "text" : "Fun"
          },
          {
            "uuid" : "54741F4B-A95F-4990-9B49-9AEBDA352096",
            "selected" : false,
            "allowsCustomTextEntry" : true,
            "text" : "Other"
          }
        ],
        "uuid" : "7F77E248-8429-463E-9291-241B94BEE4F8"
      }
    },
  ]
}

```

### Show Survey ###

#### From UIKit ####
```swift
guard let survey = try? Survey.LoadFromFile(url: jsonUrl) else { return }
let surveyView = SurveyView(survey: survey, delegate: self)
let vc = UIHostingController(rootView: surveyView)
vc.overrideUserInterfaceStyle = .light // light mode only for now
self.present(vc, animated:true, completion: nil)
```


## Question Types ##

Currently only 5 question types exist, but it's pretty easy to add new ones.

Question Type | Preview 
------------ | ------------- 
Multiple Choice | <img src="/media/multiple-choice.png" width="200"/>
**Binary Choice** | <img src="/media/binary-choice.png" width="200"/>
Inline Multiple Choice Group | <img src="/media/inline-mc.png" width="200"/>
Contact Form | <img src="/media/contact-form.png" width="200"/>
Feedback Form | <img src="/media/feedback-form.png" width="200"/>

Inline Multiple Choice Group is hard-coded for 'importance' style question with 3 choices.
It should be easy to modify or refactor for other styles.


### Visibility Logic ###
Very basic logic for conditionally showing a question based on whether another question's choice has been selected ( or not selected. ) 
A shortcut to add visibility logic is `setVisibleWhenSelected`

```swift

let ask_contact_us =
    BinaryQuestion(title: "Would you like to be contacted about new features?" , answers: ["Yes", "No"],
                    tag: "contact-us")

let contact_form = ContactFormQuestion(title: "Please share your contact info and we will reach out",
                                       tag: "contact-form")
                                       .setVisibleWhenSelected(ask_contact_us.choices.first!)
                                       
  
```


## Server ## 


### Using Firebase ###

This project supports using Firebase to retrieve a survey and save survey reponses to.
* [Readme](./README-Firebase.md) with overview on setting up Firebase for integration
* Sample XCode Project in ios folder "SwiftSurvey-Firebase.xcodeproj"
* [Readme](../main/reporting/Readme-Firebase-Reporting.md) on retrieving survey responses into report via firebase


## Report ## 
We made a very basic HTML report using python / jinja templates. 
You will probably want to modify this for your needs.
If you run:
```
python render_report.py
```
You will see a sample report using the sample survey from the XCode project. 

<img src="/media/report.png" width="500"/>


## Notes ## 

* Dark mode is not supported, so we call `vc.overrideUserInterfaceStyle = .light` 

* Visibility logic is not taken into account for the label "Question 1/5" 

* Textfield & keyboard issues
  * We used some custom UIViewRepresentable to add 'Done' button and other logic. 
  * iOS 15 seems to provide lots of similar functionality, so we can probably remove all of that. 

* Question/choice UUIDs vs Tags 
  * Question UUIDs will be re-generated each time the Swift code defining a survey is executed 
  * Use tags when aggregrating questions for reporting 





## TODO 

- [ ] swift package or pod install 





