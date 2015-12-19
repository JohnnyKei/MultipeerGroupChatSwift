//
//  SettingsViewController.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol SettingsViewControllerDelegate: NSObjectProtocol {
    func didCreateChatRoom(controller:SettingsViewController, displayName:String, serviceType:String)
}


enum MyError: ErrorType {
    case None
    case Exeption
}


class SettingsViewController: UIViewController, UITextFieldDelegate {

    let MCNearbyServiceMaxServiceTypeLength = 15
    
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var serviceTypeTextField: UITextField!
    
    weak var delegate: SettingsViewControllerDelegate?
    var displayName: String?
    var serviceType: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayNameTextField.text = displayName
        serviceTypeTextField.text = serviceType
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func isDisplayNameAndServiceType() -> Bool {
        var peerID: MCPeerID?
        do {
            peerID = MCPeerID(displayName: self.displayNameTextField.text!)
            if peerID == nil {
                throw MyError.Exeption
            }
        } catch {
            return false
        }
        
        var advertiser: MCNearbyServiceAdvertiser?
        do {
            advertiser = MCNearbyServiceAdvertiser(peer: peerID!, discoveryInfo: nil, serviceType: self.serviceTypeTextField.text!)
            if advertiser == nil {
                throw MyError.Exeption
            }
        } catch {
            return false
        }
        
        return true
    }
    
    
    @IBAction func doneTapped(sender:AnyObject) {
        if isDisplayNameAndServiceType() {
            self.delegate?.didCreateChatRoom(self, displayName: self.displayNameTextField.text!, serviceType: self.serviceTypeTextField.text!)
        }
        else {
            let alert = UIAlertView(title: "Error", message: "You must set a valid room name and your display name", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.view.endEditing(true)
    }
    

}
