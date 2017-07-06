//
//  ViewController.swift
//  YelpFoodieDiary
//
//  Created by Owen Hsiao on 2017-06-20.
//  Copyright © 2017 Owen-Hsiao-iOS.com. All rights reserved.
//

import UIKit

enum JSONError: String, Error {
  case NoData = "ERROR: no data"
  case ConversionFailed = "ERROR: conversion from JSON failed"
}

let CUSTOM_SEARCH_LOCATION_MARKER_FILE_NAME = "search_location(32*52).png"
let CUSTOM_SEARCH_LOCATION_BUTTON_ON_FILE_NAME = "search_location_on_bg.png"
let CUSTOM_SEARCH_LOCATION_BUTTON_OFF_FILE_NAME = "location_bg.png"
let DIRECT_FROM_CURRENT_LOCATION_ON_FILE_NAME = "direction_from_current_location_ON.png"
let DIRECT_FROM_CURRENT_LOCATION_OFF_FILE_NAME = "direction_from_current_location_OFF.png"
let MARKER_ICON_HEIGHT: CGFloat = 45

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UISearchBarDelegate {
  @IBOutlet weak var _googleMapContainerView: UIView!
  @IBOutlet weak var _navigationItem: UINavigationItem!
  @IBOutlet weak var _currentLocationButton: UIButton!
  @IBOutlet weak var _searchLocationSettingButton: UIButton!
  @IBOutlet weak var _listTableViewBarButtonItem: UIBarButtonItem!
  @IBOutlet weak var _markerInfoView: UIView!
  @IBOutlet weak var _travellingInfoView: UIView!
  @IBOutlet weak var _fromCurrentLocationButton: UIButton!
  
  //In Marker Info View
  @IBOutlet weak var _businessImgView: UIImageView!
  @IBOutlet weak var _ratingImgView: UIImageView!
  @IBOutlet weak var _businessNameLabel: UILabel!
  @IBOutlet weak var _phoneLabel: UILabel!
  @IBOutlet weak var _addressTxtView: UITextView!
  
  //In Travelling Info View
  @IBOutlet weak var _travelModeLabel: UILabel!
  @IBOutlet weak var _infoOfDistanceAndDurationLabel: UILabel!
  
  //For Network Reachability
  var _isNetworkReachable = true
  var _noticeTimer: Timer?
  //For Google Map & Google Direction
  var _googleMapView: GMSMapView?
  var _gmsPolyline: GMSPolyline?
  var _locationManager: CLLocationManager?
  var _currentLocation: CLLocation?
  var _searchCoordinate: CLLocationCoordinate2D?
  var _isCustomSearchLocation = false
  var _isShowDistanceAndDuration = true
  var _travelMode = "Driving"
  var _isDirectFromCurrentLocation = false
  //For Yelp Filter Searching
  weak var _sharedYelpClient: YLPClient?
  var _searchedLimit: UInt = 20
  var _searchBarString: String? = ""
  var _searchedBusinesses = [YLPBusiness]()
  var _searchBar: UISearchBar!
  var _searchedSortType: YLPSortType?
  //For Waiting Cursor
  var _activityIndicator = UIActivityIndicatorView()
  var _activityIndicatorLabel = UILabel()
  let _effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
  var _isSearching = false
  //For List Page
  var _searchedBusinessImgs = Dictionary<Int, UIImage>()
  /***
   Use _isOpenNotSettingView to check whether need to release all members in viewDidAppear()
   Since go to setting view and then come back, need to clear all searched results for updating searching filter
   ***/
  var _isOpenNotSettingView = false
  var _choseMarkerIndex = -1
  //For Setting Page
  weak var _settings: NSDictionary?
  var _chosenSortType: UInt = 0
  var _chosenTravelMode: UInt = 0
  //For Marker Info View
  var _isMarkerTapped = false
  var _isCameraMoving = false
  var _isIdleAfterMovement = false
  var _currentlyTappedMarker: GMSMarker?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //Add NotificationCenter Observer to update Network status occasionally
    NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: nil)
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(statusManager),
                                           name: .flagsChanged, object: Network.reachability)
    interactWithNetworkStatus()
    
    initUI()
  }
  
  deinit {
    print("ViewController deinit")
    NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    /*** Init location manager for current location Authorization and updating ***/
    if _locationManager == nil {
      _locationManager = CLLocationManager.init()
    }
    
    _locationManager?.delegate = self
    _locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    _locationManager?.distanceFilter = kCLDistanceFilterNone
    
    checkLocationAuthorization()
    
    _locationManager?.startUpdatingLocation()
    
    /*** Get App Setting Info. ***/
    _settings = AppDelegate.getSettings()
    _isShowDistanceAndDuration = _settings?.value(forKey: AppDelegate.SETTING_KEY_SHOW_DISTANCE_AND_DURATION) as! Bool
    _searchedLimit = _settings?.value(forKey: AppDelegate.SETTING_KEY_NUM_OF_SEARCH_RESULT) as! UInt
    _chosenSortType = _settings?.value(forKey: AppDelegate.SETTING_KEY_SORT_BY_OPTION) as! UInt
    switch _chosenSortType {
    case SortTypes.BEST_MATCH.rawValue:
      _searchedSortType = .bestMatched
    case SortTypes.DISTANCE.rawValue:
      _searchedSortType = .distance
    case SortTypes.RATING.rawValue:
      _searchedSortType = .highestRated
    case SortTypes.MOST_REVIEW.rawValue:
      _searchedSortType = .mostReviewed
    default:
      _searchedSortType = .bestMatched
    }
    _chosenTravelMode = _settings?.value(forKey: AppDelegate.SETTING_KEY_TRAVEL_MODE) as! UInt
    switch _chosenTravelMode {
    case TravelMode.DRIVING.rawValue:
      _travelMode = "Driving"
    case TravelMode.WALKING.rawValue:
      _travelMode = "Walking"
    case TravelMode.BICYCLING.rawValue:
      _travelMode = "Bicycling"
    default:
      _travelMode = "Driving"
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    _isOpenNotSettingView = false
    
    if _isCustomSearchLocation != true {
      _searchCoordinate = _currentLocation?.coordinate
    }
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    /**************************************************************************************
      If open one of view controller that is contained in another navigation controller
      Don't need to do memory control.
      Ex: In this App, it's List Table View
      Otherwise, you need to clear members' memory and disconeect delegate. 
      (especially for googleMaps - GMSMapView )
     
      P.s. 1. If doing segue back to another view controller using performSegueWithIdentifier:
              This will actually create a new instance of the view controller and
              push it onto the navigation stack
              (and retain the existing instance of it leading to memory woes).
     
           2. _googleMapView?.removeFromSuperview() is necessary!
    **************************************************************************************/
    if _isOpenNotSettingView == false {
      _searchedBusinesses.removeAll()
      _searchedBusinessImgs.removeAll()
      _markerInfoView.removeFromSuperview()
      _travellingInfoView.removeFromSuperview()
      _googleMapView?.clear()
      _googleMapView?.removeFromSuperview()
      _googleMapView?.delegate = nil
      _googleMapView = nil
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print("Low Memory!!!")
  }
  
  // Mark: Class Methods
  class func getRatingImageNameString(fromRating: Double, timeSize: Int = 1) -> String? {
    var ratingImageName: String! = ""
    var strTimeSize: String = ""
    
    if timeSize > 1 {
      strTimeSize = "@\(timeSize)x"
    }
    switch fromRating {
    case 0:
      ratingImageName = "small_0\(strTimeSize).png"
    case 1:
      ratingImageName = "small_1\(strTimeSize).png"
    case 1.5:
      ratingImageName = "small_1_half\(strTimeSize).png"
    case 2:
      ratingImageName = "small_2\(strTimeSize).png"
    case 2.5:
      ratingImageName = "small_2_half\(strTimeSize).png"
    case 3:
      ratingImageName = "small_3\(strTimeSize).png"
    case 3.5:
      ratingImageName = "small_3_half\(strTimeSize).png"
    case 4:
      ratingImageName = "small_4\(strTimeSize).png"
    case 4.5:
      ratingImageName = "small_4_half\(strTimeSize).png"
    case 5:
      ratingImageName = "small_5\(strTimeSize).png"
    default:
      ratingImageName = ""
    }
    return ratingImageName
  }
  
  // Mark: Private Methods
  func initUI() -> Void {
    /*** Google Map ***/
    _googleMapView = GMSMapView.map(withFrame: _googleMapContainerView.bounds,
                                    camera: GMSCameraPosition.init())
    _googleMapView?.isMyLocationEnabled = true
    _googleMapView?.delegate = self
  
    _googleMapContainerView.addSubview(_googleMapView!);
  
    _googleMapContainerView.bringSubview(toFront: _currentLocationButton)
    _googleMapContainerView.bringSubview(toFront: _searchLocationSettingButton)
    
    /*** Search Bar ***/
    _searchBar = UISearchBar()
    _searchBar.delegate = self
    _searchBar.placeholder = "e.g. restaurant, Japan"

    _navigationItem.titleView = _searchBar
    
    /*** Custom Search Location Button ***/
    //When navigate back to Map view controller, the setting maight set using custom search location
    if _isCustomSearchLocation == true {
      _searchLocationSettingButton.setBackgroundImage(UIImage(named: CUSTOM_SEARCH_LOCATION_BUTTON_ON_FILE_NAME),
                                                      for: .normal)
      _fromCurrentLocationButton.isHidden = false

      _googleMapView?.clear() //Clear all markers on map
      _googleMapView?.animate(with: GMSCameraUpdate.setTarget(_searchCoordinate!))
      setMapMarkerWithoutTitleAndSnippet(iconName: CUSTOM_SEARCH_LOCATION_MARKER_FILE_NAME,
                                         position: _searchCoordinate!)
    } else {
      _searchLocationSettingButton.setBackgroundImage(UIImage(named: CUSTOM_SEARCH_LOCATION_BUTTON_OFF_FILE_NAME),
                                                      for: .normal)
      _fromCurrentLocationButton.isHidden = true
    }
    /*** Set up Marker Info View ***/
    _googleMapContainerView.bringSubview(toFront: _markerInfoView!)
    _markerInfoView.isHidden = true
    
    /*** Set up Travelling Info View ***/
    _googleMapContainerView.bringSubview(toFront: _travellingInfoView!)
    _travellingInfoView.isHidden = true
    
    /*** Set up Google Map's Poly Line ***/
    _gmsPolyline = GMSPolyline()
    _gmsPolyline?.strokeWidth = 5
    _gmsPolyline?.strokeColor = UIColor.init(red: 0.0,
                                             green: 0.0,
                                             blue: 1.0,
                                             alpha: 0.5)
    /*** Clean up Travelling Info View ***/
    _travelModeLabel.text = ""
    _infoOfDistanceAndDurationLabel.text = ""
  }
  
  func checkLocationAuthorization() -> Void {
    var claStatus: CLAuthorizationStatus?
    claStatus = CLLocationManager.authorizationStatus()
    
    if claStatus == .denied {
      var strTitle: String?
      strTitle = (claStatus == .denied) ? "Location services are off" : "Background location is not enabled";
      let strMessage = "To use background location you must turn on 'Always' or 'While Using the App' in the Location Services Settings";
      
      let alert = UIAlertController.init(title: strTitle,
                                         message: strMessage,
                                         preferredStyle: .alert)
      
      let cancelButton = UIAlertAction.init(title: "Cancel",
                                            style: .cancel,
                                            handler: nil)

      let settingButton = UIAlertAction.init(title: "Setting",
                                             style: .default, handler: {
                                              action -> Void in
        /**************************************************************************
         Go to Settings lets user set location authorization.
         Remember that you should add NSLocationAlwaysUsageDescription and
         NSLocationWhenInUseUsageDescription in Info.plist, 
         so that App Settings would show 'Always' and 'While Using the App' options.
         **************************************************************************/
         let settingsURL = URL.init(string: UIApplicationOpenSettingsURLString)
         UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
         
      })
      
      alert.addAction(cancelButton)
      alert.addAction(settingButton)
      
      DispatchQueue.main.async(execute: {
        self.present(alert, animated: true, completion: nil)
      })
    } else if claStatus == .authorizedWhenInUse {
      _locationManager?.requestWhenInUseAuthorization()
    } else if claStatus == .authorizedAlways || claStatus == .notDetermined {
      _locationManager?.requestAlwaysAuthorization()
    }
  }
  
  func interactWithNetworkStatus() {
    guard let status = Network.reachability?.status else { return }
    switch status {
    case .unreachable:
      _isNetworkReachable = false
      let strTitle = "No Internet Connection"
      let strMessage = "Use Wi-Fi to access Data or Turn Off Airplan Mode.";
      
      let alert = UIAlertController.init(title: strTitle,
                                         message: strMessage,
                                         preferredStyle: .alert)
      
      let cancelButton = UIAlertAction.init(title: "Cancel",
                                            style: .cancel,
                                            handler: nil)
      
      let settingButton = UIAlertAction.init(title: "Setting",
                                             style: .default, handler: {
                                              action -> Void in
        /************************************************************
         Go to Settings lets user turn off Airplan Mode or use Wi-Fi.
         ************************************************************/
        if #available(iOS 10.0, *) {
          UIApplication.shared.open(URL(string: "App-Prefs:root=")!)
        } else {
          UIApplication.shared.open(URL(string: "prefs:root=")!)
        }
      })
      alert.addAction(cancelButton)
      alert.addAction(settingButton)
      
      DispatchQueue.main.async(execute: {
        self.present(alert, animated: true, completion: nil)
      })
      setActivityIndicator(isStart: true, title: "No Internet Connection...",
                           viewAlpha: 1.0, width: 230, height: 46)
      fadeIn(WithView: _effectView, finished: _isNetworkReachable)
    case .wifi:
      _isNetworkReachable = true
    case .wwan:
      _isNetworkReachable = true
    }
    
    /*
     If Network is reachable but yelp client is nil, redo Authorize GoogleMap And Yelp.
     Because it might happen, the network is unreachable while AppDelegate is doing Authorization
     */
    if _isNetworkReachable == true {
      if _sharedYelpClient == nil {
        AppDelegate.redoAuthorizeYelp()
      }
      
      fadeOut(WithView: _effectView, finished: _isNetworkReachable)
      setActivityIndicator(isStart: false)
    }
    
  }
  
  func statusManager(_ notification: NSNotification) {
    interactWithNetworkStatus()
  }
  
  func setActivityIndicator(isStart: Bool, title: String = "",
                            viewAlpha: CGFloat = 0.8, width: CGFloat = 160, height: CGFloat = 46) {
    _isSearching = isStart
    _listTableViewBarButtonItem.isEnabled = !_isSearching //If doing searching, avoid going list table view
    
    if isStart == false {
      _activityIndicator.stopAnimating()
      _activityIndicatorLabel.removeFromSuperview()
      _activityIndicator.removeFromSuperview()
      _effectView.removeFromSuperview()
    } else {
      _activityIndicatorLabel.text = ""
      _activityIndicatorLabel = UILabel(frame: CGRect(x: 50, y: 0, width: width, height: height))
      _activityIndicatorLabel.text = title
      _activityIndicatorLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
      _activityIndicatorLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
      
      _effectView.frame = CGRect(x: view.frame.midX - _activityIndicatorLabel.frame.width/2,
                                  y: view.frame.midY - _activityIndicatorLabel.frame.height/2 ,
                                  width: width, height: height)
      _effectView.layer.cornerRadius = 15
      _effectView.layer.masksToBounds = true
      _effectView.alpha = viewAlpha
      
      _activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
      _activityIndicator.frame = CGRect(x: 0, y: 0, width: height, height: height)
      _activityIndicator.startAnimating()
      
      _effectView.addSubview(_activityIndicator)
      _effectView.addSubview(_activityIndicatorLabel)
      view.addSubview(_effectView)
      view.bringSubview(toFront: _effectView)
    }
  }
  
  func getMarkerRatingIconNameString(fromRating: Double) -> String? {
    var ratingImageName: String? = ""
    switch fromRating {
    case 0:
      ratingImageName = "yelp_marker_star_0.png"
    case 1:
      ratingImageName = "yelp_marker_star_1.png"
    case 1.5:
      ratingImageName = "yelp_marker_star_1_half.png"
    case 2:
      ratingImageName = "yelp_marker_star_2.png"
    case 2.5:
      ratingImageName = "yelp_marker_star_2_half.png"
    case 3:
      ratingImageName = "yelp_marker_star_3.png"
    case 3.5:
      ratingImageName = "yelp_marker_star_3_half.png"
    case 4:
      ratingImageName = "yelp_marker_star_4.png"
    case 4.5:
      ratingImageName = "yelp_marker_star_4_half.png"
    case 5:
      ratingImageName = "yelp_marker_star_5.png"
    default:
      ratingImageName = ""
    }
    return ratingImageName
  }
  
  func setUpMarkerInfoView(withBusinessArrayIndex index: Int) {
    //Clear all info on Marker Info View
    _businessNameLabel.text = ""
    _phoneLabel.text = ""
    _addressTxtView.text = ""
    _ratingImgView.image = nil
    _businessImgView.image = nil
    
    guard _searchedBusinesses.count > 0 && index < _searchedBusinesses.count else {
      return
    }
    
    _businessNameLabel.text = _searchedBusinesses[index].name
    _phoneLabel.text = _searchedBusinesses[index].phone
    
    let strRatingImgName = ViewController.getRatingImageNameString(fromRating: _searchedBusinesses[index].rating)
    _ratingImgView.image = UIImage(named: strRatingImgName!)
    
    var address: String = "Address: \n"
    for addr in (_searchedBusinesses[index].location.address) {
      address.append("\(addr)\n")
    }
    address = (address != "Address: \n") ? "\(address)" : address.appending("Not Support")
    _addressTxtView.text = address
    
    _businessImgView.image = _searchedBusinessImgs[index]
  }
  
  /***
   func fadeInOnce() is used for _travellingInfoView show up as fade-in.
   ***/
  func fadeInOnce(WithView view: UIView) {
    view.alpha = 0
    UIView.animate(withDuration: 1.0, delay: 0.0,
                   options: UIViewAnimationOptions.curveEaseIn, animations: {
      view.alpha = 1.0
    }, completion: nil)
  }
  
  /***
   func fadeIn(WithView view:, finished:) & fadeOut(WithView view:, finished:) 
   is used for showing a keeping fadeIn & fadeOut view until finished sets true.
   ***/
  func fadeIn(WithView view: UIView, finished: Bool) {
    guard finished != true else {
      return
    }
    UIView.animate(withDuration: 1.0, delay: 0.5,
                   options: UIViewAnimationOptions.curveEaseIn,
                   animations: { view.alpha = 1.0 } ,
                   completion: { (Bool) -> () in
                    self.fadeOut(WithView: view,
                                 finished: finished)
    })
  }
  func fadeOut(WithView view: UIView, finished: Bool) {
    guard finished != true else {
      return
    }
    UIView.animate(withDuration: 1.0, delay: 1.5,
                   options: UIViewAnimationOptions.curveEaseOut,
                   animations: { view.alpha = 0 } ,
                   completion: { (Bool) -> () in
                    self.fadeIn(WithView: view,
                                finished: finished)
    })
  }
  
  func preparDoSearch() {
    _googleMapView?.clear()
    _markerInfoView.isHidden = true
    _travellingInfoView.isHidden = true
    _choseMarkerIndex = -1
    if _isCustomSearchLocation == true {
      self.setMapMarkerWithoutTitleAndSnippet(iconName: CUSTOM_SEARCH_LOCATION_MARKER_FILE_NAME,
                                              position: _searchCoordinate!)
    }
    //Move Map camera to the custom search Center
    _googleMapView?.animate(with: GMSCameraUpdate.setTarget(_searchCoordinate!))
  }
  
  func doSearch(term: String, limit: UInt = 20, sort: YLPSortType = .bestMatched, offset: UInt = 0) {
    self.setActivityIndicator(isStart: true, title: "Searching...", viewAlpha: 0.9)

    guard _isNetworkReachable == true else {
      self.setActivityIndicator(isStart: false)
      interactWithNetworkStatus()
      return
    }
    _searchBar.text = term
    _searchBar.resignFirstResponder() //Dismiss keyboard
    _searchedBusinesses.removeAll()
    _searchedBusinessImgs.removeAll()
    
    if term == "" {
      self.setActivityIndicator(isStart: false)
      return
    }
    
    guard let yelpClient = AppDelegate.shareYelpClient() else {
      print("There is no shared yelp client...")
      AppDelegate.redoAuthorizeYelp()
      self.setActivityIndicator(isStart: false)
      return
    }

    _sharedYelpClient = yelpClient
    let searchYelpCoordinate = YLPCoordinate.init(latitude: (_searchCoordinate?.latitude)!,
                                                  longitude: (_searchCoordinate?.longitude)!)
    
    _sharedYelpClient?.search(with: searchYelpCoordinate,
                              term: term,
                              limit: limit,
                              offset: offset,
                              sort: sort,
                              completionHandler: { (search: YLPSearch?, error: Error?) -> Void in
                                
      self._searchedBusinesses = (search?.businesses)!
                                
      guard search != nil && (search?.total)! > 0 else {
        print("Can not find any matched result")
        
        //Auto-disappear alert
        let strMessage = "Cannot find any matched result..."+"\n"+"Please choose another keyword"
        let alert = UIAlertController.init(title: "Sorry", message: strMessage, preferredStyle: .alert)
        DispatchQueue.main.async(execute: {
          self.present(alert, animated: true, completion: nil)
        })
        //After 3 sec. -> dismiss alert
        let time = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: time){
          alert.dismiss(animated: true, completion: nil)
        }
        return
      }
                                
      for (index, business) in (search?.businesses)!.enumerated() {
        //Set up Map Markers
        if business.location.coordinate != nil {
          let marker = GMSMarker.init()
          
          marker.position = CLLocationCoordinate2DMake(business.location.coordinate!.latitude,
                                                       business.location.coordinate!.longitude)
          marker.title = business.identifier
          marker.snippet = "\(index)"
          marker.appearAnimation = .pop
          marker.map = self._googleMapView
          marker.icon = UIImage(named: self.getMarkerRatingIconNameString(fromRating: business.rating)!)
        }
        /* Get Business's photo and add into _searchedBusinessImgs array */
        // If configuration uses .default, there would be memory leak
        if business.imageURL == nil { //business imageURL might be nil
          self._searchedBusinessImgs[index] = UIImage(named: "default_business(90*90).png")
        } else {
          let session = URLSession(configuration: .ephemeral)
          let task = session.dataTask(with: business.imageURL!,
                                      completionHandler: { [index](data, response, error) in
            if data != nil {
              DispatchQueue.main.async {
                self._searchedBusinessImgs[index] = UIImage(data: data!)
                
                // If business images count = businesses count -> dismiss Activity Indicator
                if self._searchedBusinessImgs.count == self._searchedBusinesses.count {
                  self.setActivityIndicator(isStart: false)
                }
              }
            }
          })
          task.resume()
        }
      }
    })
  }
  
  func setMapMarkerWithoutTitleAndSnippet(iconName: String, position: CLLocationCoordinate2D) {
    let marker = GMSMarker.init()
    marker.icon = UIImage.init(named: iconName)
    marker.position = position
    marker.appearAnimation = .pop
    marker.map = _googleMapView
  }
  
  func drawPolylineOnMap(FromCoordinate:CLLocationCoordinate2D?,
                         ToCoordinate: CLLocationCoordinate2D?,
                         onMap mapView: GMSMapView?) {

    guard _isShowDistanceAndDuration == true else {
      return
    }
    
    guard FromCoordinate != nil
      && ToCoordinate != nil
      && mapView !== nil else {
      return
    }

    /***
     To avoid a bug:
     Sometimes override func mapView(_ mapView:, idleAt position:) seems to have never called.
     In this situation, when user has not moved map or tap another marker, 
     then keeps tapping the same marker, the _markerInfoView would not be shown.
     ***/
    if _isMarkerTapped == true && _isCameraMoving == false {
      _markerInfoView.isHidden = false
      _travellingInfoView.isHidden = false
    }
    fadeInOnce(WithView: _travellingInfoView)
    
    self._gmsPolyline?.map = nil //Clear polyline which shown on the map before

    /* Using GoogleMaps Direction API to show a path between searched location and target marker
     GoogleMaps Direction API - using RESTful way */
    var urlString: String = "https://maps.googleapis.com/maps/api/directions/json"
    urlString.append("?origin=\(FromCoordinate?.latitude ?? 0)")
    urlString.append(",\(FromCoordinate?.longitude ?? 0)")
    urlString.append("&destination=\(ToCoordinate?.latitude ?? 0)")
    urlString.append(",\(ToCoordinate?.longitude ?? 0)")
    urlString.append("&mode=\(_travelMode.lowercased())")
    //urlString.append("&key=\(AppDelegate.getGoogleAPIKey() ?? "")") // Don't need API Key
    //print(urlString)
    
    guard let url = URL(string: urlString) else {
      print("Error: cannot create URL")
      return
    }
    let urlRequest = URLRequest(url: url)
    
    // If configuration uses .default, there would be memory leak
    let session = URLSession(configuration: .ephemeral)
    let task = session.dataTask(with: urlRequest,
                                completionHandler: { (data, response, error) in
      do {
        guard data != nil else {
          throw JSONError.NoData
        }
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
          throw JSONError.ConversionFailed
        }
        //print(json)
        
        guard json["status"] as? String == "OK" else {
          DispatchQueue.main.async(execute: {
            self._travelModeLabel.text = self._travelMode + " ( Inestimable )"
            self._infoOfDistanceAndDurationLabel.text = "Inestimable"
          })
          return
        }
        
        var strDistance: String? = ""
        var strDuration: String? = ""
        if let array = json["routes"] as? NSArray {
          if let routes = array[0] as? NSDictionary {
            if let overview_polyline = routes["overview_polyline"] as? NSDictionary {
              if let points = overview_polyline["points"] as? String {
                //print(points)
                // Use DispatchQueue.main for main thread for handling UI
                DispatchQueue.main.async {
                  // show polyline
                  guard self._gmsPolyline?.map == nil else {
                    return
                  }
                  self._gmsPolyline?.map = nil
                  self._gmsPolyline?.path = GMSPath(fromEncodedPath:points)
                  self._gmsPolyline?.map = mapView
                }
              }
            }
            
            if let legArray = routes["legs"] as? NSArray {
              if let legs = legArray[0] as? NSDictionary {
                if let duration = legs["duration"] as? NSDictionary {
                  if let text = duration["text"] as? String{
                    strDuration = text
                  }
                }
                if let distance = legs["distance"] as? NSDictionary {
                  if let text = distance["text"] as? String{
                    strDistance = text
                  }
                }
              }
            }
          }
        }
        DispatchQueue.main.async(execute: {
          self._travelModeLabel.text = self._travelMode + " (" + strDistance! + ")"
          self._infoOfDistanceAndDurationLabel.text = strDuration!
        })
      } catch let error as JSONError {
        print("JSONError: \(error.rawValue)")
      } catch let error as NSError {
        print("NSError: \(error.debugDescription)")
      }
                                  
    })
    task.resume()

  }
  
  // Mark: IBActions
  @IBAction func onCloseMarkerInfoButton(_ sender: AnyObject) {
    _markerInfoView.isHidden = true
    _travellingInfoView.isHidden = true
    _choseMarkerIndex = -1
    _gmsPolyline?.map = nil
  }
  
  @IBAction func onYelpSearchButton(sender: AnyObject) {
    preparDoSearch()
    doSearch(term: _searchBar.text!, limit: _searchedLimit, sort: _searchedSortType!)
  }
  
  @IBAction func onLocationButton(sender: AnyObject) {
    if _currentLocation != nil {
      _googleMapView?.animate(with: GMSCameraUpdate.setTarget((_currentLocation?.coordinate)!))
    }
  }
  
  @IBAction func onSetSearchLocationButton(sender: AnyObject) {
    if _isCustomSearchLocation == false {
      _searchLocationSettingButton.setBackgroundImage(UIImage.init(named: CUSTOM_SEARCH_LOCATION_BUTTON_ON_FILE_NAME),
                                                      for: .normal)
      _isCustomSearchLocation = true
      _fromCurrentLocationButton.isHidden = false
    } else {
      _searchLocationSettingButton.setBackgroundImage(UIImage.init(named: CUSTOM_SEARCH_LOCATION_BUTTON_OFF_FILE_NAME),
                                                      for: .normal)
      _searchCoordinate = _currentLocation?.coordinate
      _googleMapView?.clear()
      _isCustomSearchLocation = false
      _fromCurrentLocationButton.isHidden = true

      _googleMapView?.animate(with: GMSCameraUpdate.setTarget((_currentLocation?.coordinate)!))
      doSearch(term: _searchBar.text!, limit: _searchedLimit, sort: _searchedSortType!)
    }
  }
  
  @IBAction func onOpenListTableViewButton(sender: AnyObject) {
    
    _isOpenNotSettingView = true
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    let listNavigationController = storyBoard.instantiateViewController(withIdentifier: "listNavigationControllerID") as! UINavigationController
    
    let listViewController = listNavigationController.viewControllers.first as! ListTableViewController
    
    listViewController._searchedBusinesses = _searchedBusinesses
    listViewController._searchedBusinessImgs = _searchedBusinessImgs
    listViewController._choseMarkerIndex = _choseMarkerIndex
    
    self.present(listNavigationController, animated: true, completion: nil)
  }
  
  @IBAction func onOpenDetailViewButton(_ sender: AnyObject) {
    _isOpenNotSettingView = true
  }
  
  @IBAction func onFromCurrentLocationButton(_ sender: AnyObject) {
    if _isDirectFromCurrentLocation == false {
      _isDirectFromCurrentLocation = true
      _fromCurrentLocationButton.setImage(UIImage(named: DIRECT_FROM_CURRENT_LOCATION_ON_FILE_NAME),
                                          for: .normal)
      drawPolylineOnMap(FromCoordinate: _currentLocation?.coordinate,
                        ToCoordinate: _currentlyTappedMarker?.position,
                        onMap: _googleMapView)
    } else {
      _isDirectFromCurrentLocation = false
      _fromCurrentLocationButton.setImage(UIImage(named: DIRECT_FROM_CURRENT_LOCATION_OFF_FILE_NAME),
                                          for: .normal)
      drawPolylineOnMap(FromCoordinate: _searchCoordinate,
                        ToCoordinate: _currentlyTappedMarker?.position,
                        onMap: _googleMapView)
    }
  }
  
  
  // Mark: CLLocationManagerDelegate
  final func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    //Do this for allowing maps would zoom in to current location
    if _currentLocation == nil {
      _currentLocation = locations.last;
      
      /*** GoogleMap camera setting ***/
      let camera: GMSCameraPosition?
      if _isCustomSearchLocation == false {
        camera = GMSCameraPosition.camera(withLatitude: (_currentLocation?.coordinate.latitude)!,
                                          longitude: (_currentLocation?.coordinate.longitude)!,
                                          zoom: 11)
      } else {
        camera = GMSCameraPosition.camera(withLatitude: (_searchCoordinate?.latitude)!,
                                          longitude: (_searchCoordinate?.longitude)!,
                                          zoom: 11)
      }
      _googleMapView?.camera = camera!;
      
      //First time to do filter search (start app) -> must set search location as current location
      if _isCustomSearchLocation != true {
        _searchCoordinate = _currentLocation?.coordinate
      }
      if _searchBarString != "" {
        doSearch(term: _searchBarString!, limit: _searchedLimit, sort: _searchedSortType!)
      }
    }
    _currentLocation = locations.last;
    
    
    if _isCustomSearchLocation != true {
      _searchCoordinate = _currentLocation?.coordinate
    }
  }
  
  // Mark: GMSMapViewDelegate
  /*** When touch mapView(Tap, Move, Drag), dismiss search bar's keyboard pad ***/
  
  final func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    _searchBar.resignFirstResponder() //Dismiss keyboard pad
    
    /* If the map is tapped on any non-marker coordinate, reset the currentlyTappedMarker and hide
     marker info view */
    if _currentlyTappedMarker != nil {
      _currentlyTappedMarker = nil;
      _markerInfoView.isHidden = true
      _travellingInfoView.isHidden = true
      _choseMarkerIndex = -1
      _gmsPolyline?.map = nil
    }
    
    /*
      If set Custom Search Location, when user taps map -> set custom search location marker on
      the map where user taps at, and then do search.
      However, if app is still doing searching, don't allow user to set a new searching target.
     */
    if _isCustomSearchLocation == true && _isSearching != true {
      _searchCoordinate = coordinate
      _googleMapView?.clear()
      self.setMapMarkerWithoutTitleAndSnippet(iconName: CUSTOM_SEARCH_LOCATION_MARKER_FILE_NAME,
                                              position: _searchCoordinate!)
      self.doSearch(term: _searchBar.text!, limit: _searchedLimit, sort: _searchedSortType!)
    }
  }
  
  final func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
    _searchBar.resignFirstResponder() //Dismiss keyboard pad
  }
  
  final func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
    _searchBar.resignFirstResponder() //Dismiss keyboard pad
  }
  
  final func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    if _isMarkerTapped == true {
      _isCameraMoving = true;
      _gmsPolyline?.map?.isHidden = true
    } else {
      _gmsPolyline?.map = nil
      _choseMarkerIndex = -1
    }
    
    _markerInfoView.isHidden = true
    _travellingInfoView.isHidden = true
  }

  // This method gets called whenever the map was moving but has now stopped
  final func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    
    if _isMarkerTapped == true && _isCameraMoving == true {
      // Reset our state first
      _isCameraMoving = false;
      _isMarkerTapped = false;
      
      // Show up the _gmsPolyline and travelling Info View
      if _isShowDistanceAndDuration != false {
        _gmsPolyline?.map?.isHidden = false
        _travellingInfoView.isHidden = false
        fadeInOnce(WithView: _travellingInfoView)
      }
      /*** Show up Marker Info View
       _googleMapView!.projection.point(for:) takes a lat/lng
       and converts it into that lat/lngs current equivalent screen point.
       Use this point to offset the display of the bottom of the custom info window
       so it doesn't overlap the marker icon.
       ***/
      let markerPoint: CGPoint = _googleMapView!.projection.point(for: _currentlyTappedMarker!.position)
      _markerInfoView.frame = CGRect(x: markerPoint.x - _markerInfoView.frame.size.width/2,
                                     y: markerPoint.y - _markerInfoView.frame.size.height - MARKER_ICON_HEIGHT,
                                     width: _markerInfoView.frame.width,
                                     height: _markerInfoView.frame.height)
      
      setUpMarkerInfoView(withBusinessArrayIndex: _choseMarkerIndex)
      
      _travellingInfoView.frame = CGRect(x:_markerInfoView.frame.origin.x,
                                         y:_markerInfoView.frame.origin.y - _travellingInfoView.frame.size.height,
                                         width: _travellingInfoView.frame.width,
                                         height: _travellingInfoView.frame.height)
      _markerInfoView.isHidden = false
    }
  }
  
  /* 
    Return true -> Don't show default marker info window of GoogleMap,
    but it also makes mapView NOT animate the camera to center on marker position directly.
    Thus, you need to move the map camera center by yourself
   */
  final func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    
    //If still doing searching, don't do anything while user is tapping a marker
    guard _isSearching == false else {
      return true
    }
    
    /*
       If marker's title and snippet are nil, it means it's not a business marker
       -> Don't do anything
     */
    guard marker.title != nil && marker.snippet != nil else {
      return true
    }
    
    self._gmsPolyline?.map = nil //Clear polyline which shown on the map before
    
    // A marker has been tapped, so set that state flag
    _isMarkerTapped = true;
    
    // If a marker has previously been tapped and stored in currentlyTappedMarker, then nil it out
    if _currentlyTappedMarker != nil {
      _currentlyTappedMarker = nil;
    }
  
    // make this marker our currently tapped marker
    _currentlyTappedMarker = marker;
    _choseMarkerIndex = Int(marker.snippet!)! //marker.snippet records the index of _searchedBusinesses array
    
    /* Animate the camera to center on the currently tapped marker, which causes
     mapView:didChangeCameraPosition: to be called */
    _googleMapView?.animate(with: GMSCameraUpdate.setTarget(marker.position))
    
    var directionFromCoordinate: CLLocationCoordinate2D?
    if _isDirectFromCurrentLocation == true {
      directionFromCoordinate = _currentLocation?.coordinate
    } else {
      directionFromCoordinate = _searchCoordinate
    }
    
    /* Do draw Polyline (Direction) on Map & show travelling distance and duration */
    self.drawPolylineOnMap(FromCoordinate: directionFromCoordinate,
                           ToCoordinate: marker.position,
                           onMap: mapView)
    
    return true
  }
  // Mark: UISearchBarDelegate
  final func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    _searchBarString = searchBar.text
    preparDoSearch()
    doSearch(term: searchBar.text!, limit: _searchedLimit, sort: _searchedSortType!)
  }
  
  final func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText == "" {
      _searchBarString = ""
      _googleMapView?.clear()
      _searchedBusinesses.removeAll()
      _searchedBusinessImgs.removeAll()
      _markerInfoView.isHidden = true
      _travellingInfoView.isHidden = true
      _choseMarkerIndex = -1
      
      if _isCustomSearchLocation == true {
        self.setMapMarkerWithoutTitleAndSnippet(iconName: CUSTOM_SEARCH_LOCATION_MARKER_FILE_NAME,
                                                position: _searchCoordinate!)
      }
    }
  }
  
  // Mark: Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {    
    if segue.identifier == "SettingSegue" {
      if let settingViewController = segue.destination as? SettingViewController {
        settingViewController._searchBarString = _searchBarString
        settingViewController._isCustomSearchLocation = _isCustomSearchLocation
        settingViewController._searchCoordinate = _searchCoordinate
      }
    }
    if segue.identifier == "SegueMapToDetail" {
      if let detailViewController = segue.destination as? DetailViewController {
        detailViewController._checkAskForView = AskFromView.MAP.rawValue
        detailViewController._businessImg = _searchedBusinessImgs[_choseMarkerIndex]
        detailViewController._business = _searchedBusinesses[_choseMarkerIndex]
      }
    }
  }
}

