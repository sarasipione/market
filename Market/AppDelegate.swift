//
//  AppDelegate.swift
//  Market
//
//  Created by Sara Sipione on 22/11/2019.
//  Copyright © 2019 Sara Sipione. All rights reserved.
//

import UIKit
import Firebase
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        initializeStripe()
        //initializePayPal()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    //MARK: - Stripe init
    
    func initializeStripe() {
        STPPaymentConfiguration.shared().publishableKey = Constants.publishableKey
        StripeClient.sharedClient.baseURLString = Constants.baseURLString
    }
    

    //MARK: - PayPal Init
    
//    func initializePayPal() {
//        PayPalMobile.initializeWithClientIds(forEnvironments: [PayPalEnvironmentProduction : "ATIW1eQVmoTHNjS-XY-80uYXdF2FS-zP2PTTbLViVBnZOdXoMC7H26b0YCiwdnwH-1vKhL3rUy2uIupY", PayPalEnvironmentSandbox: "sra.sipione@gmail.com"])
//    }
    
    
}

