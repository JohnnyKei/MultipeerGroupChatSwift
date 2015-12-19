//
//  MainViewController.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class MainViewController: UITableViewController, SettingsViewControllerDelegate, SessionContainerDelegate, MCBrowserViewControllerDelegate, UIActionSheetDelegate , UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{

    let kNSDefaultDisplayName = "displayNameKey"
    let kNSDefaultServiceType = "serviceTypeKey"
    
    // Text field used for typing text messages to send to peers
    @IBOutlet weak var messageComposeTextField:UITextField!
    // Button for executing the message send.
    @IBOutlet weak var sendMessageButton:UIBarButtonItem!
    
    // Display name for local MCPeerID
    var displayName: String? = ""
    // Service type for discovery
    var serviceType: String? = ""
    // MC Session for managing peer state and send/receive data between peers
    var sessionContainer: SessionContainer!
    // TableView Data source for managing sent/received messagesz
    var transcripts: [Transcript] = []
    // Map of resource names to transcripts array index
    var imageNameIndex: [String: AnyObject] = [:]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        displayName = defaults.objectForKey(kNSDefaultDisplayName) as? String
        serviceType = defaults.objectForKey(kNSDefaultServiceType) as? String
        
        if (displayName != nil) && (serviceType != nil) {
            // Show the service type (room name) as a title
            self.navigationItem.title = serviceType
            // create the session
            createSession()
        }
        else {
            self.performSegueWithIdentifier("Room Create", sender: self)
        }
        
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Listen for will show/hide notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop listening for keyboard notifications
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Room Create" {
            // Prepare the settings view where the user inputs the 'serviceType' and local peer 'displayName'
            let navController = segue.destinationViewController as! UINavigationController
            let settingsViewController = navController.topViewController as! SettingsViewController
            settingsViewController.delegate = self
            // Pass the existing properties (if any) so the user can edit them.
            settingsViewController.displayName = self.displayName
            settingsViewController.serviceType = self.serviceType
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    //MARK: -SettingsViewControllerDelegate
    func didCreateChatRoom(controller: SettingsViewController, displayName: String, serviceType: String) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        
        // Dismiss the modal view controller
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // Cache these for MC session creation and changing later via the "info" button
        self.displayName = displayName
        self.serviceType = serviceType
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(displayName, forKey: kNSDefaultDisplayName)
        defaults.setObject(serviceType, forKey: kNSDefaultServiceType)
        
        // Set the service type (aka Room Name) as the view controller title
        self.navigationItem.title = serviceType
        
        // Create the session
        self.createSession()
    }
    
    //MARK: - MCBrowserViewControllerDelegate
    func browserViewController(browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        return true
    }
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - SessionContainerDelegate
    func receivedTranscript(transcript: Transcript) {
        // Add to table view data source and update on main thread
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.insertTranscript(transcript)
        }
        
    }
    
    func updateTranscript(transcript: Transcript) {
        // Find the data source index of the progress transcript
        let index = imageNameIndex[transcript.imageName!] as! NSNumber
        let idx = Int(index.unsignedLongValue)
        // Replace the progress transcript with the image transcript
        self.transcripts[idx] = transcript
        
        // Reload this particular table view row on the main thread
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let indexPath = NSIndexPath(forRow: idx, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    
    
    //MARK: - Private Methods
    
    // Private helper method for the Multipeer Connectivity local peerID, session, and advertiser.  This makes the application discoverable and ready to accept invitations
    private func createSession() {
        // Create the SessionContainer for managing session related functionality.
        self.sessionContainer = SessionContainer(displayName: self.displayName!, serviceType: self.serviceType!)
        // Set this view controller as the SessionContainer delegate so we can display incoming Transcripts and session state changes in our table view.
        self.sessionContainer.delegate = self
        
    }
    
    // Helper method for inserting a sent/received message into the data source and reload the view.
    // Make sure you call this on the main thread
    private func insertTranscript(transcript: Transcript) {
        // Add to the data source
        transcripts.append(transcript)
        // If this is a progress transcript add it's index to the map with image name as the key
        if transcript.progress != nil {
            let transcriptIndex = NSNumber(integer: transcripts.count - 1)
            self.imageNameIndex[transcript.imageName!] = transcriptIndex
        }
        
        // Update the table view
        let newIndexPath = NSIndexPath(forRow: self.transcripts.count - 1, inSection: 0)
        tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        
        // Scroll to the bottom so we focus on the latest message
        let numberOfRows = self.tableView.numberOfRowsInSection(0)
        if numberOfRows != 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfRows - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        
    }
    
    

    // MARK: - Table view data source
    
    // Only one section in this example
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // The numer of rows is based on the count in the transcripts arrays
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcripts.count
    }
    
    // The individual cells depend on the type of Transcript at a given row.  We have 3 row types (i.e. 3 custom cells) for text string messages, resource transfer progress, and completed image resource
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get the transcript for this row
        let transcript = self.transcripts[indexPath.row]
        
        // Check if it's an image progress, completed image, or text message
        var cell: UITableViewCell?
        if transcript.imageUrl != nil {
            // It's a completed image
            cell = tableView.dequeueReusableCellWithIdentifier("Image Cell", forIndexPath: indexPath)
            // Get the image view
            let imageView = cell?.viewWithTag(100) as! ImageView
            // Set up the image view for this transcript
            imageView.transcript = transcript
           
            
        }
        else if transcript.progress != nil {
            // It's a resource transfer in progress
            cell = tableView.dequeueReusableCellWithIdentifier("Progress Cell", forIndexPath: indexPath)
            let progressView = cell?.viewWithTag(101) as! ProgressView
            // Set up the progress view for this transcript
            progressView.transcript = transcript
        }
        else {
            // Get the associated cell type for messages
            cell = tableView.dequeueReusableCellWithIdentifier("Message Cell", forIndexPath: indexPath)
            // Get the message view
            let messageView = cell?.viewWithTag(99) as! MessageView
            // Set up the message view for this transcript
            messageView.transcript = transcript
        }
        
        return cell!
    }
    
    // Return the height of the row based on the type of transfer and custom view it contains
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Dynamically compute the label size based on cell type (image, image progress, or text message)
        let transcript = self.transcripts[indexPath.row]
        if transcript.imageUrl != nil {
            return ImageView.viewHeight(transcript)
        }
        else if transcript.progress != nil {
            return ProgressView.viewHeight(transcript)
        }
        else {
            return MessageView.viewHeight(transcript)
        }

        
    }
    
    
    //MARK: - IBAction methods
    
    // Action method when pressing the "browse" (search icon).  It presents the MCBrowserViewController: a framework UI which enables users to invite and connect to other peers with the same room name (aka service type).
    
    @IBAction func browseForPeers(sender:AnyObject) {
        print(__FUNCTION__)
        // Instantiate and present the MCBrowserViewController

        let browserViewController = MCBrowserViewController(serviceType: self.serviceType!, session: self.sessionContainer.session)
        browserViewController.delegate = self
        browserViewController.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers
        browserViewController.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers
        
        self.presentViewController(browserViewController, animated: true, completion: nil)
        
    }
    
    
    // Action method when user presses "send"
    @IBAction func sendMessage(sender:AnyObject) {
        // Dismiss the keyboard.  Message will be actually sent when the keyboard resigns.
        self.messageComposeTextField.resignFirstResponder()
    }

    // Action method when user presses the "camera" photo icon.
    @IBAction func photoButtonTapped(sender:AnyObject) {
        // Preset an action sheet which enables the user to take a new picture or select and existing one.
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Take Photo","Choose Existing")
        // Show the action sheet
        actionSheet.showFromToolbar((self.navigationController?.toolbar)!)
        
        
    }
    
    
    //MARK: - UIActionSheetDelegate methods
    
    // Override this method to know if user wants to take a new photo or select from the photo library
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let imagePickerController = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            imagePickerController.delegate = self
            if buttonIndex == 0 {
                imagePickerController.sourceType = .Camera
            }
            else if buttonIndex == 1 {
                imagePickerController.sourceType = .PhotoLibrary
            }
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        }
        else {
            // Problem with camera, alert user
            let alert = UIAlertView(title: "No Camera", message: "Please use a camera enabled device", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    //MARK: - UIImagePickerViewControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        // Don't block the UI when writing the image to documents
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            // We only handle a still image
            let imageToSave = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            // Save the new image to the documents directory
            let pngData = UIImageJPEGRepresentation(imageToSave, 1.0)
            
            // Create a unique file name
            let inFormat = NSDateFormatter()
            inFormat.dateFormat = "yyMMdd-HHmmss"
            let imageName = "image-\(inFormat.stringFromDate(NSDate())).JPG"
            // Create a file path to our documents directory
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let filePath = (paths[0] as NSString!).stringByAppendingPathComponent(imageName)
             // Write the file
            pngData?.writeToFile(filePath, atomically: true)
            // Get a URL for this file resource
            let imageUrl = NSURL(fileURLWithPath: filePath)
            
            // Send the resource to the remote peers and get the resulting progress transcript
            let transcript = self.sessionContainer.sendImage(imageUrl)
            
            // Add the transcript to the data source and reload

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.insertTranscript(transcript!)
            })

            
            
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - UITextFieldDelegate methods
    // Override to dynamically enable/disable the send button based on user typing
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let length = (messageComposeTextField.text?.characters.count)! - range.length + string.characters.count
        if length > 0 {
            sendMessageButton.enabled = true
        }
        else
        {
            sendMessageButton.enabled = false
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // Check if there is any message to send
        if messageComposeTextField.text?.characters.count > 0 {
            // Resign the keyboard
            textField.resignFirstResponder()
            // Send the message
            let transcript = sessionContainer.sendMessage(messageComposeTextField.text!)
            if transcript != nil {
                // Add the transcript to the table view data source and reload
                insertTranscript(transcript!)
            }
            // Clear the textField and disable the send button
            messageComposeTextField.text = ""
            sendMessageButton.enabled = false
            
        }
    }
    
    //MARK: - Toolbar animation helpers
    // Helper method for moving the toolbar frame based on user action
    private func moveToolBarUp(up:Bool, notification:NSNotification) {
        let userInfo = notification.userInfo
        // Get animation info from userInfo
        let animationDuration = (userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).floatValue
        let animationCurveNumber = (userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue
        let keyboardFrame = (userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
//        userInfo![UIKeyboardAnimationCurveUserInfoKey]?.getValue(&animationCurveNumber)
//        userInfo![UIKeyboardAnimationDurationUserInfoKey]?.getValue(&animationDuration)
//        userInfo![UIKeyboardFrameEndUserInfoKey]?.getValue(&keyboardFrame)
        
        
        // Animate up or down
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(NSTimeInterval(animationDuration))
        let animationCurve = UIViewAnimationCurve(rawValue: animationCurveNumber << 16)
        UIView.setAnimationCurve(animationCurve!)
        navigationController?.toolbar.frame = CGRect(x: (navigationController?.toolbar.frame.origin.x)!, y: (navigationController?.toolbar.frame.origin.y)! + (keyboardFrame.size.height * (up ? -1 : 1)), width: (navigationController?.toolbar.frame.width)!, height: (navigationController?.toolbar.frame.height)!)
        UIView.commitAnimations()
        
        
    }
    
    
    func keyboardWillShow(notification:NSNotification) {
        moveToolBarUp(true, notification: notification)
    }
    
    func keyboardWillHide(notification:NSNotification) {
        moveToolBarUp(false, notification: notification)
    }
    
}
