//
//  DetailViewController.swift
//  YelpFoodieDiary
//
//  Created by Owen Hsiao on 2017-07-05.
//  Copyright © 2017 Owen-Hsiao-iOS.com. All rights reserved.
//

import UIKit

enum AskFromView: UInt {
  case MAP
  case LIST
}

class DetailViewController: UIViewController {
  @IBOutlet weak var _businessImgView: UIImageView!
  @IBOutlet weak var _businessNameLabel: UILabel!
  @IBOutlet weak var _businessPhoneTxtView: UITextView!
  @IBOutlet weak var _businessAddressTxtView: UITextView!
  @IBOutlet weak var _ratingImgView: UIImageView!
  @IBOutlet weak var _reviewLabel: UILabel!
  @IBOutlet weak var _categoriesLabel: UILabel!
  @IBOutlet weak var _yelpUrlButton: UIButton!
  
  var _checkAskForView: UInt!
  var _businessImg: UIImage!
  var _business: YLPBusiness!
  
  var _webView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard _businessImg != nil
      && _business != nil
      else { return }
    
    initUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    switch _checkAskForView {
    case AskFromView.MAP.rawValue:
      let barButtonItem = UIBarButtonItem.init(image: UIImage(named:"map (24*24).png"),
                                               style: .plain,
                                               target: self,
                                               action: #selector(goBack) )
      barButtonItem.title = ""
      barButtonItem.tintColor = UIColor.white
      navigationItem.setLeftBarButton(barButtonItem, animated: true)
      navigationItem.setRightBarButton(nil, animated: false)
      
    case AskFromView.LIST.rawValue:
      let barButtonItem = UIBarButtonItem.init(image: UIImage(named:"list (24*24).png"),
                                               style: .plain,
                                               target: self,
                                               action: #selector(goBack) )
      barButtonItem.title = ""
      barButtonItem.tintColor = UIColor.white
      navigationItem.setLeftBarButton(barButtonItem, animated: true)
    default:
      print("Did not set custom navigationItem")
    }
    navigationController?.navigationBar.tintColor = UIColor.white
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }
  
  // Mark: Private Methods
  func goBack() {
    navigationController?.popViewController(animated: true)
  }
  
  func closeWebView() {
    _webView.removeFromSuperview()
    navigationItem.setRightBarButton(nil, animated: true)
  }
  
  func initUI() {
    //Clear all info on Marker Info View
    _businessNameLabel.text = ""
    _businessPhoneTxtView.text = ""
    _businessAddressTxtView.text = ""
    _ratingImgView.image = nil
    _businessImgView.image = nil
    _reviewLabel.text = ""
    _categoriesLabel.text = ""
    
    _businessImgView.image = _businessImg
    _businessImgView.layer.cornerRadius = 9.0
    _businessImgView.layer.masksToBounds = true
    
    _businessNameLabel.text = _business.name
    _businessPhoneTxtView.text = _business.phone
    
    let strRatingImgName = ViewController.getRatingImageNameString(fromRating: _business.rating, timeSize: 2)
    _ratingImgView.image = UIImage(named: strRatingImgName!)
    
    let reviewCount = _business.reviewCount
    if (reviewCount == 1) {
      _reviewLabel.text = "\(reviewCount) review"
    } else {
      _reviewLabel.text = "\(reviewCount) reviews"
    }
    
    var address: String = ""
    for addr in _business.location.address {
      address.append("\(addr), ")
    }
    if address != "" {
      address = "\(address)\(_business.location.city), \(_business.location.stateCode), \(_business.location.countryCode), "
      address.append("\(_business.location.postalCode)")
    } else {
      address = address.appending("Not Support")
    }
    _businessAddressTxtView.text = address
    
    var strCategories: String? = ""
    for category in _business.categories {
      if category == _business.categories.last {
        strCategories = strCategories! + "\(category.name)"
      } else {
        strCategories = strCategories! + "\(category.name), "
      }
    }
    _categoriesLabel.text = strCategories!
    
    _webView = UIWebView.init(frame: CGRect.init(x: 0, y: 64, width: view.frame.width, height: view.frame.height - 64))
  }
  
  // Mark: IBActions
  @IBAction func onGoToMapButton(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func onOpenYelpWebsiteButton(_ sender: AnyObject) {
    view.addSubview(_webView)
    _webView.loadRequest(URLRequest(url: _business.url))
    let barButtonItem = UIBarButtonItem.init(image: UIImage(named:"close_webview (24*24).png"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(closeWebView) )
    barButtonItem.title = ""
    barButtonItem.tintColor = UIColor.white
    navigationItem.setRightBarButton(barButtonItem, animated: true)
  }
}
