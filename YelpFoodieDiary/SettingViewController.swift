//
//  SettingViewController.swift
//  YelpFoodieDiary
//
//  Created by Owen Hsiao on 2017-06-23.
//  Copyright © 2017 Owen-Hsiao-iOS.com. All rights reserved.
//

import UIKit
import CoreData

enum SortTypes: UInt {
  case BEST_MATCH
  case DISTANCE
  case RATING
  case MOST_REVIEW
}

enum TravelMode: UInt {
  case DRIVING
  case WALKING
  case BICYCLING
}

class ExpendCellDescriptor: NSObject {
  var _heading: String?
  var _name: String?
  var _isExpand: Bool = false
  var _options = [String]()
  var _apiparams = [Int]()
}

// "Set Custom Search Location" & "Show Distance & Duration" & "Travel Mode - ..." cells in Map section
let NUM_OF_SKIP_CELLS_IN_MAP_SECTION = 3
// "Number of Search Results" & "Sort by ..." cells in Filter Search section
let NUM_OF_SKIP_CELLS_IN_FILTER_SECTION = 2
let INDEX_OF_MAP_SETTING_SECTION = 0
let INDEX_OF_FILTER_OF_SEARCH_SECTION = 1

class SettingViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
  @IBOutlet weak var _searchLimitTxtField: UITextField!
  @IBOutlet weak var _customSearchLocationSwitch: UISwitch!
  @IBOutlet weak var _showDistanceAndDurationSwitch: UISwitch!
  
  weak var _settings: NSDictionary?
  var _searchBarString: String?
  var _searchedLimit: UInt = 20
  var _searchCoordinate: CLLocationCoordinate2D?
  var _isCustomSearchLocation = false
  var _isShowDistanceAndDuration = true
  var _searchedLimitPicker: UIPickerView?
  var _searchedLimitArray = [String]()
  var _expendCellDescripors = [ExpendCellDescriptor]()
  var _chosenSortType: UInt = 0
  let _selectedSortCellBgColor = UIColor(red: 1, green: 215/255, blue: 215/255, alpha: 1)
  var _sortItemsDictionary = Dictionary<UInt, String>()
  var _travelModeItemsDictionary = Dictionary<UInt, String>()
  var _chosenTravelMode: UInt = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    _settings = AppDelegate.getSettings()
    _isShowDistanceAndDuration = _settings?.value(forKey: AppDelegate.SETTING_KEY_SHOW_DISTANCE_AND_DURATION) as! Bool
    _chosenSortType = _settings?.value(forKey: AppDelegate.SETTING_KEY_SORT_BY_OPTION) as! UInt
    _chosenTravelMode = _settings?.value(forKey: AppDelegate.SETTING_KEY_TRAVEL_MODE) as! UInt
    _searchedLimit = _settings?.value(forKey: AppDelegate.SETTING_KEY_NUM_OF_SEARCH_RESULT) as! UInt
    
    self.initUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    tableView.delegate = nil
    tableView.dataSource = nil
  }
  
  // Mark: Private Methods
  func initUI() {
    _searchLimitTxtField.delegate = self
    _searchLimitTxtField.text = "\(_searchedLimit)"
    
    //Set the range of Searched Limit for Picker setting
    for num in 1...50 {
      _searchedLimitArray.append("\(num)")
    }
    //Set up searched limit picker
    _searchedLimitPicker = UIPickerView.init(frame: CGRect(x: 0, y: 50,
                                                           width: self.view.frame.size.width,
                                                           height: 150))
    _searchedLimitPicker?.delegate = self
    _searchedLimitPicker?.dataSource = self
    _searchedLimitPicker?.showsSelectionIndicator = true
    _searchedLimitPicker?.selectRow(Int(_searchedLimit-1), inComponent: 0, animated: true)
    
    //Set up "Show Distance & Duration" switch
    _showDistanceAndDurationSwitch.setOn(_isShowDistanceAndDuration, animated: false)
    
    //Set up "Set Custom Search Center" switch
    _customSearchLocationSwitch.setOn(_isCustomSearchLocation, animated: false)
    
    //Set up Travel Mode Setting Items
    let travelMode = ExpendCellDescriptor()
    travelMode._name = "Travel Mode"
    travelMode._heading = "Travel Mode - "
    travelMode._isExpand = false
    travelMode._options = ["Driving", "Walking", "Bicycling"]
    travelMode._apiparams = [0, 1, 2] //This number setting follows UI setting order
    //Set up a dictionary for getting travelMode._options string easilly
    for i in 0..<travelMode._options.count {
      _travelModeItemsDictionary.updateValue(travelMode._options[i], forKey: UInt(travelMode._apiparams[i]))
    }
    _expendCellDescripors.append(travelMode)
    
    //Set up Filter Sort Setting Items
    let sortFilter = ExpendCellDescriptor()
    sortFilter._name = "Sort"
    sortFilter._heading = "Sort By "
    sortFilter._isExpand = false
    sortFilter._options = ["Best Match", "Distance", "Rating", "Most Reviews"]
    sortFilter._apiparams = [0, 1, 2, 3] //This number setting follows UI setting order
    //Set up a dictionary for getting sortFilter._options string easilly
    for i in 0..<sortFilter._options.count {
      _sortItemsDictionary.updateValue(sortFilter._options[i], forKey: UInt(sortFilter._apiparams[i]))
    }
    _expendCellDescripors.append(sortFilter)
  }
  
  // Mark: Keyboard & ScrollView Content move
  func cancelEditTxtFieldWithPad() -> Void {
    //Dismiss Keyboard Pad
    _searchLimitTxtField.text = "\(_searchedLimit)"
    self.dismissKeyboardPad()
  }
  
  func doneEditTxtFieldWithPad() -> Void {
    //Dismiss Keyboard Pad
    self.dismissKeyboardPad()
  }
  
  func dismissKeyboardPad() -> Void {
    _searchLimitTxtField.resignFirstResponder()
  }
  
  // Mark: UIPickerViewDataSource
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    if pickerView == _searchedLimitPicker {
      return 1
    }
    return 0
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if pickerView == _searchedLimitPicker {
      return _searchedLimitArray.count
    }
    return 0
  }
  
  // Mark: UIPickerViewDelegate
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    if pickerView == _searchedLimitPicker {
      return _searchedLimitArray[row]
    }
    return nil
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if pickerView == _searchedLimitPicker {
      _searchLimitTxtField.text = _searchedLimitArray[row]
      
      guard AppDelegate.updateSetting(withKey: AppDelegate.SETTING_KEY_NUM_OF_SEARCH_RESULT,
                                      value: UInt(_searchLimitTxtField.text!)!)
        != false
        else {
          fatalError("Setting Error!")
      }
    }
  }
  
  // Mark: UITextFieldDelegate
  func textFieldDidBeginEditing(_ textField: UITextField) {
    let padToolBar: UIToolbar = UIToolbar.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
    padToolBar.barStyle = .blackTranslucent
    padToolBar.items = [UIBarButtonItem.init(title: "Cancel", style: .plain,
                                             target: self, action: #selector(cancelEditTxtFieldWithPad)),
                        UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil,
                                             action: nil),
                        UIBarButtonItem.init(title: "Done", style: .done,
                                             target: self, action: #selector(doneEditTxtFieldWithPad))]
    padToolBar.sizeToFit()
    
    if textField == _searchLimitTxtField {
      textField.inputView = _searchedLimitPicker
    }
    
    textField.inputAccessoryView = padToolBar
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.dismissKeyboardPad()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
    self.dismissKeyboardPad()
  }
  
  // Mark: UITableViewDataSource
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var numberOfRows: Int = 0
    
    switch section {
    case INDEX_OF_MAP_SETTING_SECTION:
       /* If Travel Mode cells is not expand -> rows number: 3
        * Otherwise, row number: 3 (Number of Search Results + Sort by ...) + _sortFilter._options.count */
      if _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._isExpand == false {
        numberOfRows = NUM_OF_SKIP_CELLS_IN_MAP_SECTION
      } else {
        numberOfRows = NUM_OF_SKIP_CELLS_IN_MAP_SECTION + _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._options.count
      }
      
    case INDEX_OF_FILTER_OF_SEARCH_SECTION:
       /* If Sort By cells is not expand -> rows number: 2
       * Otherwise, row number: 2 (Number of Search Results + Sort by ...) + _sortFilter._options.count */
      if _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._isExpand == false {
        numberOfRows = NUM_OF_SKIP_CELLS_IN_FILTER_SECTION
      } else {
        numberOfRows = NUM_OF_SKIP_CELLS_IN_FILTER_SECTION + _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._options.count
      }
      
    default:
      numberOfRows = 0
    }

    return numberOfRows
  }
  
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    //For Section - INDEX_OF_MAP_SETTING_SECTION
    if indexPath.section == INDEX_OF_MAP_SETTING_SECTION
       && _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._isExpand == false {
      if indexPath.row == 2 {
        let collapsibleCell = cell as! CollapsibleTableViewCell
        collapsibleCell.Label.text = _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._heading! + _travelModeItemsDictionary[_chosenTravelMode]!
      }
    } else {
      if indexPath.section == INDEX_OF_MAP_SETTING_SECTION {
        if indexPath.row == NUM_OF_SKIP_CELLS_IN_MAP_SECTION + Int(_chosenTravelMode) {
          cell.backgroundColor = _selectedSortCellBgColor
        } else {
          cell.backgroundColor = UIColor.white
        }
      }
    }
    //For Section - INDEX_OF_FILTER_OF_SEARCH_SECTION
    if indexPath.section == INDEX_OF_FILTER_OF_SEARCH_SECTION
       && _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._isExpand == false {
      if indexPath.row == 1 {
        let collapsibleCell = cell as! CollapsibleTableViewCell
        collapsibleCell.Label.text = _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._heading! + _sortItemsDictionary[_chosenSortType]!
      }
    } else {
      if indexPath.section == INDEX_OF_FILTER_OF_SEARCH_SECTION {
        if indexPath.row == NUM_OF_SKIP_CELLS_IN_FILTER_SECTION + Int(_chosenSortType) {
          cell.backgroundColor = _selectedSortCellBgColor
        } else {
          cell.backgroundColor = UIColor.white
        }
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == INDEX_OF_MAP_SETTING_SECTION {
      
      if indexPath.row == 0 || indexPath.row == 1 {
        switch indexPath.row {
        case 0: //Set _customSearchLocationSwitch
          _isCustomSearchLocation = !_customSearchLocationSwitch.isOn
          _customSearchLocationSwitch.setOn(_isCustomSearchLocation,
                                            animated: true)
        case 1: //Set _showDistanceAndDurationSwitch
          _isShowDistanceAndDuration = !_showDistanceAndDurationSwitch.isOn
          _showDistanceAndDurationSwitch.setOn(_isShowDistanceAndDuration,
                                               animated: true)
          //Update data of Setting.plist
          guard AppDelegate.updateSetting(withKey: AppDelegate.SETTING_KEY_SHOW_DISTANCE_AND_DURATION,
                                          value: _isShowDistanceAndDuration)
            != false
            else {
              fatalError("Setting Error!")
          }
        default:
          self.tableView.deselectRow(at: indexPath, animated: true)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
        return
      }
      
      if _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._isExpand == false {
        
        _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._isExpand = true
        
      } else {
        let selectOption = indexPath.row - NUM_OF_SKIP_CELLS_IN_MAP_SECTION
        
        if selectOption >= 0 {
          _chosenTravelMode = UInt(selectOption)
          
          //Update data of Setting.plist
          guard AppDelegate.updateSetting(withKey: AppDelegate.SETTING_KEY_TRAVEL_MODE,
                                          value: _chosenTravelMode)
            != false
            else {
              fatalError("Setting Error!")
          }
        }
        
        _expendCellDescripors[INDEX_OF_MAP_SETTING_SECTION]._isExpand = false
      }
      self.tableView.reloadData()
    } else if indexPath.section == INDEX_OF_FILTER_OF_SEARCH_SECTION {
      
      if indexPath.row == 0 { //Set _searchLimitTxtField
        _searchLimitTxtField.becomeFirstResponder()
        self.tableView.deselectRow(at: indexPath, animated: true)
        return
      }
      
      if _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._isExpand == false {
        
        _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._isExpand = true
        
      } else {
        let selectOption = indexPath.row - NUM_OF_SKIP_CELLS_IN_FILTER_SECTION
        
        if selectOption >= 0 {
          _chosenSortType = UInt(selectOption)
          
          //Update data of Setting.plist
          guard AppDelegate.updateSetting(withKey: AppDelegate.SETTING_KEY_SORT_BY_OPTION,
                                          value: _chosenSortType)
            != false
            else {
              fatalError("Setting Error!")
          }
        }
        _expendCellDescripors[INDEX_OF_FILTER_OF_SEARCH_SECTION]._isExpand = false
      }
      self.tableView.reloadData()
    }
    self.tableView.deselectRow(at: indexPath, animated: true)
  }
  
  
  // Mark: IBActions
  @IBAction func onSetCustomSearchLocationSwitch(_ sender: AnyObject) {
    _isCustomSearchLocation = _customSearchLocationSwitch.isOn
  }
  
  @IBAction func onShowDistanceAndDurationSwitch(_ sender: AnyObject) {
    _isShowDistanceAndDuration = _showDistanceAndDurationSwitch.isOn
    
    //Update data of Setting.plist
    guard AppDelegate.updateSetting(withKey: AppDelegate.SETTING_KEY_SHOW_DISTANCE_AND_DURATION,
                                    value: _isShowDistanceAndDuration)
      != false
      else {
        fatalError("Setting Error!")
    }
  }
  
  // Mark: Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "SettingToMapSegue" {
      if let mapViewController = segue.destination as? ViewController {
        mapViewController._searchBarString = _searchBarString
        mapViewController._isCustomSearchLocation = _isCustomSearchLocation
        mapViewController._isShowDistanceAndDuration = _isShowDistanceAndDuration
        mapViewController._searchCoordinate = _searchCoordinate
        mapViewController._chosenSortType = _chosenSortType
        mapViewController._chosenTravelMode = _chosenTravelMode
      }
    }
  }
}
