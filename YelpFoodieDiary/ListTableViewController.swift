//
//  ListViewController.swift
//  YelpFoodieDiary
//
//  Created by Owen Hsiao on 2017-06-23.
//  Copyright © 2017 Owen-Hsiao-iOS.com. All rights reserved.
//

import UIKit

enum LoadImageError: String, Error {
  case NoImageData = "ERROR: no image data"
}

class ListTableViewController: UITableViewController {
  
  var _searchedBusinesses = [YLPBusiness]()
  var _searchedBusinessImgs = Dictionary<Int, UIImage>()
  var _choseMarkerIndex = -1
  let SegueDetailViewController = "SegueListToDetail"
  var _canCleanAllMembers = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    //Auto-Scroll table view to the row whose index is _choseMarkerIndex
    if _choseMarkerIndex != -1 {
      let indexPath = IndexPath(row: _choseMarkerIndex, section: 0)
      self.tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    if _canCleanAllMembers == true {
      _searchedBusinesses.removeAll()
      _searchedBusinessImgs.removeAll()
      tableView.reloadData()
      tableView.delegate = nil
      tableView.dataSource = nil
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print("Low Memory!!!")
  }
  
  deinit {
    print("deinit")
  }
  
  // Mark: UITableViewDataSource
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return _searchedBusinesses.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //print("Table View do cellForRowAt")
    let cell = tableView.dequeueReusableCell(withIdentifier: "YelpBusinessCellID") as! YelpBusinessTableViewCell
    
    guard _searchedBusinesses.count > 0 else {
      return cell
    }
    
    cell.backgroundColor = UIColor.white
    if _choseMarkerIndex != -1 && indexPath.row == _choseMarkerIndex {
      cell.backgroundColor = UIColor(red: 255/255,
                                     green: 130/255,
                                     blue: 120/255,
                                     alpha: 1)
    }
    
    weak var business = _searchedBusinesses[indexPath.row]
    
    cell.nameLabel.text = "\(indexPath.row + 1). \(business?.name ?? "")"

    cell.ratingImage.image = UIImage(named: ViewController.getRatingImageNameString(fromRating: (business?.rating)!)!)
    
    let reviewCount = business?.reviewCount
    if (reviewCount == 1) {
      cell.reviewLabel.text = "\(reviewCount ?? 0) review"
    } else {
      cell.reviewLabel.text = "\(reviewCount ?? 0) reviews"
    }
    
    var strAddress: String? = ""
    for address in (business?.location.address)! {
      strAddress = strAddress?.appending("\(address), ")
    }
    cell.addressLabel.text = strAddress
    
    var strCategories: String? = ""
    for category in (business?.categories)! {
      strCategories = strCategories! + "\(category.name), "
    }
    cell.categoriesLabel.text = strCategories!
    
    cell.previewImage.image = _searchedBusinessImgs[indexPath.row]
   
    cell.previewImage.layer.cornerRadius = 9.0
    cell.previewImage.layer.masksToBounds = true
    
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // Perform Segue
    performSegue(withIdentifier: SegueDetailViewController, sender: self)
    
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  // Mark: IBActions
  @IBAction func onGoBackToMapButton(_ sender: AnyObject) {
    _canCleanAllMembers = true
    self.dismiss(animated: true, completion: nil)
  }
  
  // Mark: Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == SegueDetailViewController {
      if let indexPath = tableView.indexPathForSelectedRow {
        if let detailViewController = segue.destination as? DetailViewController {
          detailViewController._checkAskForView = AskFromView.LIST.rawValue
          detailViewController._businessImg = _searchedBusinessImgs[indexPath.row]
          detailViewController._business = _searchedBusinesses[indexPath.row]
        }
      }
    }
  }
}
