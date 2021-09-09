//
//  SurveyHelper+Firebase.swift
//  SwiftSurvey-Firebase
//
//  Created by jclaan on 9/8/21.
//

import Foundation
import FirebaseDatabase


extension Survey {

    //MARK: - Save to Server
    
    //static func saveResponseToServer(survey:Survey) -> Bool {
    static func saveResponseToServer(survey:Survey, completion: ((_ success: Bool)->())? ) {
        
        var ref: DatabaseReference!
        
        ref = Database.database().reference()
        
        let UUID : UUID = UUID()
        let uuid_string = "\(UUID)"
        
        let dateFormatter = ISO8601DateFormatter()
        let timeStampString = dateFormatter.string(from: Date())

        
        
        let jsonData = Survey.getJsonDataForSurvey(survey: survey)
        
        do {
        
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments) as? [String: Any]
            else { completion?(false); return }


            ref.child("surveys").child(uuid_string).setValue([ "response": dictionary, "createdAt": timeStampString]) { error, db in
                if error != nil {
                    completion?(false)
                } else {
                    completion?(true)
                }
            }
            
        } catch {
            
            print(error.localizedDescription)
            completion?(false)
            
        }
        
        
    }
    
    
    //MARK: - JSON
    
    static func getJsonStringFromData( jsonData: Data)->String? {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            
            //print("JSON OUTPUT")
            //print(jsonString)
            
            return jsonString
        }
        
        return nil
    }
    
    
    static func getJsonDataForSurvey(survey: Survey)->Data? {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(survey)

            return jsonData
            
            

            
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
        
    }
    
    
    static func getSurveyFromString(jsonString: String) -> Survey? {
        
        do {
            
            let jsonData = jsonString.data(using: .utf8)!
            let survey = try JSONDecoder().decode(Survey.self, from: jsonData)
            return survey
            
        } catch {
            print(error)
        }
        
        return nil
        
    }
    
    
    
    
    
}
