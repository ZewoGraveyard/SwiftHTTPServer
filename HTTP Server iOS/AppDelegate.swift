//
//  AppDelegate.swift
//  HTTP Server iOS
//
//  Created by Paulo Faria on 7/7/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        print(NSBundle.mainBundle().resourcePath)
        
        Server().start()
        return true
        
    }

}

