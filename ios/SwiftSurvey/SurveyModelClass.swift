//
//  SurveyModelClass.swift
//  SwiftSurvey
//
//  Created by CC Laan on 6/13/21.
//

import Foundation


enum SurveyItemType : Int, Codable {
    
    case multipleChoiceQuestion
    case binaryChoice
    case contactForm
    case inlineQuestionGroup
    case commentsForm
    
}

final class Survey : ObservableObject, Codable {
    
    @Published var questions : [SurveyQuestion]
    
    let version : String
    
    var metadata : [String:String]? // debugging stuff
    
    enum CodingKeys: CodingKey {
        case questions
        case version
        case metadata
    }
    
    init(_ questions : [SurveyQuestion], version : String) {
        self.questions = questions
        self.version = version
        
        var tags : Set<String> = []
        for q in questions {
            //assert(q.tag != nil, "Question tag must be set")
            if tags.contains(q.tag) {
                print("Duplicate tag found: ", q.tag)
            }
            assert( !tags.contains(q.tag), "Duplicate tag found")
            tags.insert(q.tag)
        }
        
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.questions = try container.decode([SurveyItem].self, forKey: .questions).map({$0.question})
        self.version = try container.decode(String.self, forKey: .version)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let wrapped = self.questions.map({ SurveyItem(question: $0) } )
        try container.encode(wrapped, forKey: .questions)
        try container.encode(version, forKey: .version)
        
        if let meta = self.metadata {
            try container.encode(meta, forKey: .metadata)
        }
    }
    
    func choiceWithId( _ id : UUID ) -> MultipleChoiceResponse? {
        // TODO: maybe general class "ChoiceQuestion" that has choices?
        for q in self.questions {
            if let q = q as? MultipleChoiceQuestion {
                for c in q.choices {
                    if c.uuid == id {
                        return c
                    }
                }
            } else if let q = q as? BinaryQuestion {
                for c in q.choices {
                    if c.uuid == id {
                        return c
                    }
                }
            }
        }
        return nil
    }
    
}

final class SurveyItem : Codable {
    
    let type : SurveyItemType
    let question : SurveyQuestion
    
    enum CodingKeys: CodingKey {
        case type, question
    }
    init( question : SurveyQuestion ) {
        self.question = question
        self.type = question.type
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(SurveyItemType.self, forKey: .type)
        
        switch self.type {
        case .multipleChoiceQuestion:
            self.question = try container.decode(MultipleChoiceQuestion.self, forKey: .question)
        case .binaryChoice:
            self.question = try container.decode(BinaryQuestion.self, forKey: .question)
        case .contactForm:
            self.question = try container.decode(ContactFormQuestion.self, forKey: .question)
        case .commentsForm:
            self.question = try container.decode(CommentsFormQuestion.self, forKey: .question)
        case .inlineQuestionGroup:
            self.question = try container.decode(InlineMultipleChoiceQuestionGroup.self, forKey: .question)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.type, forKey: .type)
        
        switch self.type {
        case .multipleChoiceQuestion:
            try container.encode(self.question as! MultipleChoiceQuestion, forKey: .question)
        case .binaryChoice:
            try container.encode(self.question as! BinaryQuestion, forKey: .question)
        case .contactForm:
            try container.encode(self.question as! ContactFormQuestion, forKey: .question)
        case .commentsForm:
            try container.encode(self.question as! CommentsFormQuestion, forKey: .question)
        case .inlineQuestionGroup:
            try container.encode(self.question as! InlineMultipleChoiceQuestionGroup, forKey: .question)
        }
        
    }
}


protocol SurveyQuestion : Codable {
    var title : String { get }
    var uuid : UUID { get }
    var tag : String { get }
    
    var type : SurveyItemType { get }
    var required : Bool { get set }
    var visibilityLogic : VisibilityLogic? { get set }
    
}


extension SurveyQuestion {
    var type : SurveyItemType {
        
        if self is MultipleChoiceQuestion {
            return .multipleChoiceQuestion
        } else if self is BinaryQuestion {
            return .binaryChoice
        } else if self is ContactFormQuestion {
            return .contactForm
        } else if self is InlineMultipleChoiceQuestionGroup {
            return .inlineQuestionGroup
        } else if self is CommentsFormQuestion {
            return .commentsForm
        }
        
        assert(false) // fixme
        return .multipleChoiceQuestion // hmm
        
    }
    
    func isVisible( for survey: Survey ) -> Bool {
        if let logic = self.visibilityLogic {
            if logic.type == .choiceMustBeSelected {
                return survey.choiceWithId(logic.choiceId)?.selected ?? false
            }
        }
        return true // default true
    }
    
    func setVisibleWhenSelected( _ response : MultipleChoiceResponse ) -> Self {
        var new = self
        new.visibilityLogic = VisibilityLogic(type: .choiceMustBeSelected, choiceId: response.uuid)
        return new
    }
    func required( ) -> Self {
        var new = self
        new.required = true
        return new
    }
    func optional() -> Self {
        var new = self
        new.required = false
        return new
    }
//    func setTag( _ tag : String) -> Self {
//        var new = self
//        new.tag = tag
//        return new
//    }
    
}


class InlineMultipleChoiceQuestionGroup : ObservableObject, SurveyQuestion {
    
    let title : String
    let uuid: UUID
    var questions : [MultipleChoiceQuestion]
    
    var visibilityLogic : VisibilityLogic?
    var required: Bool = false
    let tag: String
    
    init(title:String, questions:[MultipleChoiceQuestion], tag: String ) {
        self.title = title
        self.uuid = UUID()
        self.questions = questions
        self.tag = tag
    }
}

class MultipleChoiceQuestion : ObservableObject, SurveyQuestion {
    
    let title : String
    let uuid: UUID
    var choices : [MultipleChoiceResponse]
    
    var visibilityLogic : VisibilityLogic?
    var required: Bool = false
    var allowsMultipleSelection = false
    var tag: String
    
    init(title:String, answers:[String], multiSelect : Bool = false, tag : String ) {
        self.title = title
        self.uuid = UUID()
        self.choices = answers.map({ MultipleChoiceResponse($0) })
        self.allowsMultipleSelection = multiSelect
        self.tag = tag
    }
    
    init(title:String, items: [Any], multiSelect : Bool = false, tag : String ) {
        self.title = title
        self.uuid = UUID()
        
        self.choices = []
        
        for item in items {
            if let item2 = item as? String {
                self.choices.append( MultipleChoiceResponse(item2) )
            } else if let item2 = item as? MultipleChoiceResponse {
                self.choices.append( item2 )
            }
        }
        self.allowsMultipleSelection = multiSelect
        self.tag = tag
    }
    
}

class MultipleChoiceResponse : ObservableObject, Codable {
    let text : String
    let uuid : UUID
    var selected = false
    
    let allowsCustomTextEntry : Bool
    var customTextEntry: String? = nil
    
    init(_ text : String, allowsCustomTextEntry : Bool = false) {
        self.text = text
        self.uuid = UUID()
        self.allowsCustomTextEntry = allowsCustomTextEntry
    }
}

class BinaryQuestion : ObservableObject, SurveyQuestion {
    
    let title: String
    let uuid: UUID
    var choices : [MultipleChoiceResponse]
    
    var required: Bool = false
    
    var visibilityLogic : VisibilityLogic?
    
    var autoAdvanceOnChoice : Bool
    var tag: String
    
    init(title:String, answers: [String], autoAdvanceOnChoice : Bool = true , tag : String ) {
        self.title = title
        self.uuid = UUID()
        self.choices = answers.map({ MultipleChoiceResponse($0) })
        self.autoAdvanceOnChoice = autoAdvanceOnChoice
        self.tag = tag
        assert(self.choices.count == 2)
    }
}

class ContactFormQuestion : ObservableObject, SurveyQuestion {
    
    let title: String
    let uuid: UUID
    
    //var choices : [MultipleChoiceResponse]
    
    var required: Bool = false
    
    var visibilityLogic : VisibilityLogic?
    var tag: String
    
    // Info
    var emailAddress : String = ""
    var name : String = ""
    var company : String = ""
    var phoneNumber : String = ""
    var feedback : String = ""
    
    init(title:String, tag : String ) {
        self.title = title
        self.uuid = UUID()
        self.tag = tag
        //self.choices = answers.map({ MultipleChoiceResponse($0) })
        //assert(self.choices.count == 2)
    }
}

class CommentsFormQuestion : ObservableObject, SurveyQuestion {
    
    let title: String
    let subtitle: String
    let uuid: UUID
    
    var required: Bool = false
    
    var visibilityLogic : VisibilityLogic?
    var tag: String
    
    // Info
    var emailAddress : String = ""
    var feedback : String = ""
    
    init(title:String, subtitle : String, tag: String) {
        self.title = title
        self.uuid = UUID()
        self.subtitle = subtitle
        self.tag = tag
    }
    
}



// Logic

class VisibilityLogic : Codable {
    
    enum LogicType : Int, Codable {
        case choiceMustBeSelected
        case choiceMustNotBeSelected
    }
    let type : LogicType
    let choiceId : UUID
    init(type:LogicType, choiceId:UUID) {
        self.type = type
        self.choiceId = choiceId
    }
    
}


