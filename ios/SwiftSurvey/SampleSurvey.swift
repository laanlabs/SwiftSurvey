//
//  3dScannerAppSurvey.swift
//  SwiftSurvey
//
//  Created by CC Laan on 8/10/21.
//

import Foundation
import SwiftUI
import Combine


typealias MCQ = MultipleChoiceQuestion
typealias MCR = MultipleChoiceResponse



func ImportanceQuestion( _ title : String ) -> MultipleChoiceQuestion {
    return MultipleChoiceQuestion(title: title, answers: [ "Not Important" , "Somewhat Important", "Very Important" ], tag: TitleToTag(title))
}

let SampleSurvey = Survey([
    
    MCQ(title: "What are you primarily using our app for?",
                                          items: [
                                            "Work",
                                            "Fun",
                                            "Just trying it out",
                                            MultipleChoiceResponse("Other", allowsCustomTextEntry: true)
                                          ], multiSelect: true,
                                          tag: "what-using-for"),
    
    
    InlineMultipleChoiceQuestionGroup(title: "What new features are important to you?",
                                      questions: [
                                        
                                        ImportanceQuestion("Faster load times"),
                                        ImportanceQuestion("Dark mode support"),
                                        ImportanceQuestion("Lasers"),
                                      ],
                                      tag: "importance-what-improvements"),
    
    ask_contact_us,
    
    contact_form.setVisibleWhenSelected(ask_contact_us.choices.first!),
    
    ask_comments,
    
    comments_form.setVisibleWhenSelected(ask_comments.choices.first!),
    
    
],
version: "001")


let ask_contact_us =
    BinaryQuestion(title: "Would you like to be contacted about new features?" , answers: ["Yes", "No"],
                    tag: "contact-us")

let contact_form = ContactFormQuestion(title: "Please share your contact info and we will reach out",
                                       tag: "contact-form")



// Some
let ask_comments =
    BinaryQuestion(title: "Do you have any feedback or feature ideas for us?",
                   answers: ["Yes", "No"],
                   autoAdvanceOnChoice: true,
                   tag: "do-you-have-feedback")

let comments_form = CommentsFormQuestion(title: "Tell us your feedback or feature requests",
                                         subtitle: "Optionally leave your email",
                                         tag: "feedback-comments-form")






struct SampleSurvey_Previews: PreviewProvider {
    
    static var previews: some View {
        
        SurveyView(survey: SampleSurvey).preferredColorScheme(.light)
        
    }
}
