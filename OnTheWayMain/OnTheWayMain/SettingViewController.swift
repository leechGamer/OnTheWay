//
//  SettingViewController.swift
//  OnTheWayMain
//
//  Created by junwoo on 2017. 5. 15..
//  Copyright © 2017년 junwoo. All rights reserved.
//

import UIKit
import RealmSwift
import FBSDKLoginKit
import UserNotifications

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var serverManager = ServerManager()
    let imagePicker = UIImagePickerController()
    var settingList = SettingList()
    var items = [Setting]()
    var realm: Realm!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBAction func logoutButton(_ sender: Any) {
        serverManager.logout()
        print("logout")
        let storyboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "loginVC")
        self.present(loginVC, animated: false, completion: nil)
        UserManager.sharedInstance.removeUser()
        UserSettingManager.sharedInstance.removeSetting()
    }
    
    @IBOutlet weak var settingTableView: UITableView!

    // Data model: These strings will be the data for the table view cells
    
    var settings: [String:[String:String]] = ["profile": ["username": "name", "image": "choose photo"], "dailyGoal": ["dailyStep": "10000"], "notification": ["notification": "On"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (setting) in
            if(setting.authorizationStatus == .authorized)
            {
                self.settings["notification"]?.updateValue("On", forKey: "notification")
            }
            else
            {
                self.settings["notification"]?.updateValue("Off", forKey: "notification")
            }
        }

        
        NotificationCenter.default.addObserver(self, selector: #selector(drawAndSave), name: Notification.Name("settingChanged"), object: nil)
        
        
        settingTableView.delegate = self
        settingTableView.dataSource = self
        imagePicker.delegate = self
        
        //로그인한 유저의 username 가져오기
        if UserManager.sharedInstance.getUser().count != 0 {
            let existingUser = UserManager.sharedInstance.getUser()[0]
            settings["profile"]?.updateValue(existingUser.username, forKey: "username")
            profileImageView.setImage(with: existingUser.image)
        }
        
        //로그인한 유저의 setting 정보 가져오기
        if UserSettingManager.sharedInstance.getUserSetting().items.count != 0 {
            let existingUserSetting = UserSettingManager.sharedInstance.getUserSetting()
            settings["dailyGoal"]?.updateValue((existingUserSetting.items.last?.dailyGoal)!, forKey: "dailyStep")
            settings["notification"]?.updateValue((existingUserSetting.items.last?.notification)!, forKey: "notification")
        }
        
    }
    
    //설정 변경될때마다 tableView 다시 뿌리고 realm에 저장
    func drawAndSave(_ notification: Notification) {
        settingTableView.reloadData()
        let realm = try? Realm() // Create realm pointing to default file
        realm?.beginWrite()
        let setting = Setting()
        setting.dailyGoal = (settings["dailyGoal"]?["dailyStep"]!)!
        setting.notification = (settings["notification"]?["notification"]!)!
        settingList.items.append(setting)
        settingList.email = UserManager.sharedInstance.getUser()[0].email
        realm?.add(setting)
        realm?.add(settingList)
        try! realm?.commitWrite()
        print("save setting into realm")
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let categoryValues = Array(settings.values)[section]
        return categoryValues.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell = self.settingTableView.dequeueReusableCell(withIdentifier: "MyCell") as UITableViewCell!

        let categoryValue = Array(settings.values)[indexPath.section]

        let title = Array(categoryValue.keys)[indexPath.row]

        cell.textLabel?.text = title

        let detail = Array(categoryValue.values)[indexPath.row]
        cell.detailTextLabel?.text = "\(detail)"

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(settings.keys)[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //First check whether the right cell is being selected.
        
        let selectedIndexPath = tableView.indexPathForSelectedRow
        let title = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let detail = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text
        //If the selected row is not in the first section the method returns without doing anything.
        
        if title == "notification" {
            
            if detail == "On" {
                self.settings["notification"]?.updateValue("Off", forKey: "notification")
                NotificationCenter.default.post(name: Notification.Name("notificationOff"), object: nil)
                
            }
            if detail == "Off" {
                self.settings["notification"]?.updateValue("On", forKey: "notification")
                NotificationCenter.default.post(name: Notification.Name("notificationOn"), object: nil)

            }
            NotificationCenter.default.post(name: Notification.Name("settingChanged"), object: nil)

            
        }
        
        if title == "dailyStep" {
        
            //The first row is selected and here the user can change the string in an alert sheet.
            let firstRowEditAction = UIAlertController(title: "Edit Title", message: "Please edit the title", preferredStyle: .alert)
            firstRowEditAction.addTextField(configurationHandler: { (newTitle) -> Void in
                newTitle.text = detail
            })
            
            //The cancel action will do nothing.
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
                
                //self.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            
            //The Okay action will change the title that is typed in.
            let okayAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                
                self.settings["dailyGoal"]?.updateValue((firstRowEditAction.textFields?.first?.text)!, forKey: "dailyStep")
                print("user = \(UserManager.sharedInstance.getUser())")
                UserSettingManager.sharedInstance.updateUserSetting(user: UserManager.sharedInstance.getUser()[0], dailyGoal: (firstRowEditAction.textFields?.first?.text)!, notification: (self.settings["notification"]?["notification"])!)
                print("setting = \(UserSettingManager.sharedInstance.getUserSetting())" )
                NotificationCenter.default.post(name: Notification.Name("settingChanged"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("goalChanged"), object: nil)
            })
            
            firstRowEditAction.addAction(okayAction)
            firstRowEditAction.addAction(cancelAction)
            self.present(firstRowEditAction, animated: true, completion: nil)
            
        }

        
        if title == "username" {
            
            //The first row is selected and here the user can change the string in an alert sheet.
            let firstRowEditAction = UIAlertController(title: "Edit Title", message: "Please edit the title", preferredStyle: .alert)
            firstRowEditAction.addTextField(configurationHandler: { (newTitle) -> Void in
                newTitle.text = detail
            })
            
            //The cancel action will do nothing.
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
                
                //self.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            
            //The Okay action will change the title that is typed in.
            let okayAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                
                self.settings["profile"]?.updateValue((firstRowEditAction.textFields?.first?.text)!, forKey: "username")
                //Do some other stuff that you want to do
                
                let user = UserManager.sharedInstance.getUser()
                self.serverManager.profileUpdate(userId: user[0].id, username: (firstRowEditAction.textFields?.first?.text)!, password: user[0].password) { (user) in
                    print("username updated")
                }
                UserManager.sharedInstance.updateUsername(username: (firstRowEditAction.textFields?.first?.text)!)
                NotificationCenter.default.post(name: Notification.Name("settingChanged"), object: nil)
                
            })
            
            firstRowEditAction.addAction(okayAction)
            firstRowEditAction.addAction(cancelAction)
            self.present(firstRowEditAction, animated: true, completion: nil)
                
        }
        
        if title == "image" {
            
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        }
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profileImageView?.contentMode = .scaleAspectFit
            profileImageView?.image = pickedImage
            serverManager.uploadImage(pickedImage: pickedImage, userId: UserManager.sharedInstance.getUser()[0].id) { user in
                print("user is \(user)")
            }
            
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    

}

