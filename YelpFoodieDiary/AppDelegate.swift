//
//  AppDelegate.swift
//  YelpFoodieDiary
//
//  Created by Owen Hsiao on 2017-06-20.
//  Copyright © 2017 Owen-Hsiao-iOS.com. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  static let SETTING_KEY_NUM_OF_SEARCH_RESULT = "NumberOfSearchResult"
  static let SETTING_KEY_SORT_BY_OPTION = "SortByOption"
  static let SETTING_KEY_SHOW_DISTANCE_AND_DURATION = "ShowDistanceAndDuration"
  static let SETTING_KEY_TRAVEL_MODE = "TravelMode"
  
  var window: UIWindow?
  var _yelpClient: YLPClient?
  var _googleMapAPIKey: String?
  var _settingPlistPath: String?
  var _settingsDictionary: NSMutableDictionary?
  
  // Mark: Class Methods
  class func redoAuthorizeYelp() {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.authorizeYelp()
  }
  
  class func shareYelpClient() -> YLPClient? {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    return appDelegate._yelpClient
  }
  
  class func getGoogleAPIKey() -> String? {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    return appDelegate._googleMapAPIKey
  }
  
  class func updateSetting(withKey key: String, value: Any?) -> Bool {
    var setRes = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    guard appDelegate._settingsDictionary != nil else {
      fatalError("You did not load setting before, call appDelegate.loadSettings() first!")
    }
    let checkValue = appDelegate._settingsDictionary?[key]
    guard checkValue != nil else {
      fatalError("Setting Key Error! Check if setting key entered is correct. ")
    }
    appDelegate._settingsDictionary?.setObject(value!, forKey: key as NSCopying)
    setRes = true
    
    return setRes
  }
  
  class func getSettings() -> NSDictionary? {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    return appDelegate._settingsDictionary
  }
  
  // Mark: Private Mathods
  func loadSettings() {
    let initialFileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "Setting", ofType: "plist")!)
    let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    let writableFileURL = documentDirectoryURL.appendingPathComponent("Setting.plist", isDirectory: false)
    
    do {
      //Copy Setting.plist from app's bundle to document directory
      //Because plist in bundle could not be modified
      try FileManager.default.copyItem(at: initialFileURL, to: writableFileURL)
    } catch {
      print("Copying file failed with error : \(error)")
    }
    print(writableFileURL)
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate._settingPlistPath = writableFileURL.path
    appDelegate._settingsDictionary = NSMutableDictionary(contentsOf: writableFileURL)
  }
  
  func authorizeYelp() {
    guard _yelpClient == nil else {
      return
    }
    
    //Set up GoogleMaps and Yelp Service
    let dictAPIKeys: NSDictionary?
    
    if let APIKeysPath = Bundle.main.path(forResource: "API_Keys", ofType: "plist") {
      dictAPIKeys = NSDictionary(contentsOfFile: APIKeysPath)
      
      //Set Yelp API ID and Secret to YLPClient for doing authorization
      if let strYelpAPIID = dictAPIKeys?.object(forKey: "Yelp_API_ID"),
        let strYelpAPISecret = dictAPIKeys?.object(forKey: "Yelp_API_Secret"),
        String(describing: strYelpAPIID) != "",
        String(describing: strYelpAPISecret) != "" {
        
        YLPClient.authorize(withAppId: strYelpAPIID as! String, secret: strYelpAPISecret as! String,
                            completionHandler: { (client: YLPClient?, error: Error?) -> Void in
          guard error == nil else {
            print(error as Any)
            return
          }
          self._yelpClient = client
        })
      } else {
        print("You didn't support Yelp API ID or Secret in API_Keys.plist")
      }
    }
  }
  
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    /* Check if Network is reachable */
    do {
      Network.reachability = try NetworkReachability(hostname: "www.google.com")
      do {
        try Network.reachability?.start()
      } catch let error as Network.Error {
        print(error)
      } catch {
        print(error)
      }
    } catch {
      print(error)
    }
    
    //Set up GoogleMaps Service
    let dictAPIKeys: NSDictionary?
    
    if let APIKeysPath = Bundle.main.path(forResource: "API_Keys", ofType: "plist") {
      dictAPIKeys = NSDictionary(contentsOfFile: APIKeysPath)
      
      //Set GoogleMaps API Key to GMSServices (GoogleMaps)
      if let strGoogleMapAPIKey = dictAPIKeys?.object(forKey: "GoogleMap_API_Key"),
        String(describing: strGoogleMapAPIKey) != "" {
        _googleMapAPIKey = strGoogleMapAPIKey as? String
        GMSServices.provideAPIKey(strGoogleMapAPIKey as! String)
      } else {
        print("You didn't support GoogleMap API Key in API_Keys.plist")
      }
    }
    
    //Authorize Yelp & Get Yelp Client
    authorizeYelp()
    
    //Load Setting Info.
    loadSettings()
    
    let attrs = [
      NSForegroundColorAttributeName: UIColor.white,
      NSFontAttributeName: UIFont(name: "Georgia-Bold", size: 24)!
    ]
    
    UINavigationBar.appearance().titleTextAttributes = attrs
    
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    //When app enter background, save settings to Setting.plist
    guard _settingsDictionary?.write(toFile: _settingPlistPath!, atomically: false) == true
      else {
        fatalError("Error: Saving Setting.plist failed")
    }
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    
    //When app is about to terminate, save settings to Setting.plist
    guard _settingsDictionary?.write(toFile: _settingPlistPath!, atomically: false) == true
      else {
      fatalError("Error: Saving Setting.plist failed")
    }
    //Core Data
    self.saveContext()
  }

  // MARK: - Core Data stack

  lazy var persistentContainer: NSPersistentContainer = {
      /*
       The persistent container for the application. This implementation
       creates and returns a container, having loaded the store for the
       application to it. This property is optional since there are legitimate
       error conditions that could cause the creation of the store to fail.
      */
      let container = NSPersistentContainer(name: "YelpFoodieDiary")
      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
          if let error = error as NSError? {
              // Replace this implementation with code to handle the error appropriately.
              // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
               
              /*
               Typical reasons for an error here include:
               * The parent directory does not exist, cannot be created, or disallows writing.
               * The persistent store is not accessible, due to permissions or data protection when the device is locked.
               * The device is out of space.
               * The store could not be migrated to the current model version.
               Check the error message to determine what the actual problem was.
               */
              fatalError("Unresolved error \(error), \(error.userInfo)")
          }
      })
      return container
  }()

  // MARK: - Core Data Saving support

  func saveContext () {
      let context = persistentContainer.viewContext
      if context.hasChanges {
          do {
              try context.save()
          } catch {
              // Replace this implementation with code to handle the error appropriately.
              // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
              let nserror = error as NSError
              fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
          }
      }
  }

}

