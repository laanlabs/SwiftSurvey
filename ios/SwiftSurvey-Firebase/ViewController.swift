//
//  ViewController.swift
//  SwiftSurvey-Firebase
//
//  Created by jclaan on 9/8/21.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    var remoteConfig: RemoteConfig!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        
    }

    
    override func viewDidAppear(_ animated:Bool) {
       super.viewDidAppear(true)
   
        
        //OPTION 1 : open survey from data
        //var survey = SampleSurvey
        //showSurvey(survey: survey)

        //OPTION 2 : load from json on firebase
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        //remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        fetchRemoteConfig()
        
        
        //OPTION 3 : open survey from json file
        /*
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let jsonUrl = documentsDirectory.appendingPathComponent("sample_survey.json")
        try? Survey.SaveToFile(survey: survey, url: jsonUrl)
        print( " Saved survey to: \n" , jsonUrl.path )
        
        if let loadedSurvey = try? Survey.LoadFromFile(url: jsonUrl) {
            print(" Loaded survey from:\n ", jsonUrl)
            survey = loadedSurvey
        }
        */

   }
    
    
    func showSurvey(survey: Survey) {
     
        
        var surveyView : SurveyView = SurveyView(survey: survey)
        //_=surveyView.preferredColorScheme(.light)
        surveyView.delegate = self
        let vc = SurveyViewController(rootView: surveyView)
        vc.overrideUserInterfaceStyle = .light
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated:true, completion: nil)
        
    }
    
    
    //MARK: - REMOTE_CONFIG

      func fetchRemoteConfig() {
          
          
          
        // [START fetch_config_with_callback]
        remoteConfig.fetch() { (status, error) -> Void in
          if status == .success {
              
            self.remoteConfig.activate() { (changed, error) in
                  
 
                  
                  //try to get survey from
                  let surveyRemoteJsonkey : String = "SURVEY_DATA"
                  
                  
                  if let remoteSurveyJsonString = self.remoteConfig[surveyRemoteJsonkey].stringValue {
                      if let surveyFromRemote : Survey = Survey.getSurveyFromString(jsonString: remoteSurveyJsonString) {
                          
                        DispatchQueue.main.async {

                            self.showSurvey(survey: surveyFromRemote)
                        }

                      } else {
                          print("remote survey not loaded")

                      }
                      
                  }
                  
    

            }
          } else {
           
            print("remote config fetch failed")

          }
          
        }
        // [END fetch_config_with_callback]
      }
    
    
    

}

extension ViewController : SurveyViewDelegate {
    
    func surveyCompleted(with survey: Survey) {
        
        var meta : [String : String] = [:]
        
        
        meta["app_version"] = Bundle.main.releaseVersionNumber
        meta["build"] = Bundle.main.buildVersionNumber
        
        survey.metadata = meta
        
        Survey.saveResponseToServer(survey: survey) { success in
            
            DispatchQueue.main.async {
                
                
                if success {
                    print(" Survey submitted successfully ")
                } else {
                    print( " Survey FAILED to submit ")
                }
                
            }
            
        }
        
        
        
    }
    
    func surveyDeclined() {
        
    }
    
    func surveyRemindMeLater() {
    
    }
    
}
