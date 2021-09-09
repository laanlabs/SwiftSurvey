//
//  ViewController.swift
//  SwiftSurvey-Firebase
//
//  Created by jclaan on 9/8/21.
//

import UIKit

class ViewController: UIViewController {

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        
    }

    
    override func viewDidAppear(_ animated:Bool) {
       super.viewDidAppear(true)
   
        
        let survey = SampleSurvey
        
        var surveyView : SurveyView = SurveyView(survey: survey)
        //_=surveyView.preferredColorScheme(.light)
        surveyView.delegate = self
        let vc = SurveyViewController(rootView: surveyView)
        vc.overrideUserInterfaceStyle = .light
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated:true, completion: nil)
        

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
