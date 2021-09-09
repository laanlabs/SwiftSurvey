//
//  SurveyViewController.swift
//  SwiftUISurvey
//
//  Created by CC Laan on 8/10/21.
//


import Foundation
import SwiftUI


class SurveyViewController<ContentView>: UIHostingController<ContentView> where ContentView : View {
    
    // this may not be required...
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //overrideUserInterfaceStyle = .light
    }
    
    // Portrait only for iPhone
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    override var shouldAutorotate: Bool {
        return true
    }
    
    
}

