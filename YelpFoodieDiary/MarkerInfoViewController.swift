//
//  MarkerInfoViewController.swift
//  YelpFoodieDiary
//
//  Created by Owen Hsiao on 2017-07-01.
//  Copyright © 2017 Owen-Hsiao-iOS.com. All rights reserved.
//

import UIKit

class MarkerInfoViewController: UIViewController {
  @IBOutlet weak var _businessImgView: UIImageView!
  @IBOutlet weak var _ratingImgView: UIImageView!
  @IBOutlet weak var _businessNameLabel: UILabel!
  @IBOutlet weak var _phoneLabel: UILabel!
  @IBOutlet weak var _addressTxtView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  // Mark: Private Methods
  func placeView(withFrame frame: CGRect) {
    self.view.frame = frame
  }
  
  func placeView(withMarkerPosition point: CGPoint) {
    self.view.frame = CGRect(x: point.x - self.view.frame.size.width/2,
                             y: point.y - self.view.frame.size.height,
                             width: self.view.frame.width,
                             height: self.view.frame.size.height)
  }
  
  // Mark: Private Methods
  func getRatingImageNameString(fromRating: Double) -> String? {
    var ratingImageName: String? = ""
    switch fromRating {
    case 0:
      ratingImageName = "small_0.png"
    case 1.5:
      ratingImageName = "small_1_half.png"
    case 2:
      ratingImageName = "small_2.png"
    case 2.5:
      ratingImageName = "small_2_half.png"
    case 3:
      ratingImageName = "small_3.png"
    case 3.5:
      ratingImageName = "small_3_half.png"
    case 4:
      ratingImageName = "small_4.png"
    case 4.5:
      ratingImageName = "small_4_half.png"
    case 5:
      ratingImageName = "small_5.png"
    default:
      ratingImageName = ""
    }
    return ratingImageName
  }
  
  // Mark: IBActions
  @IBAction func onCloseButton(_ sender: AnyObject) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func onDetailButton(_ sender: AnyObject) {
    
  }
}
