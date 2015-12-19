//
//  ProgressView.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import UIKit


struct ProgressViewConstructs {
    static let progressViewHeight: CGFloat = 15.0
    static let paddingX :CGFloat = 15.0
    static let nameFontSize :CGFloat = 10.0
    static let bufferWhiteSpace: CGFloat = 14.0
    static let progressViewWidth: CGFloat = 140.0
    static let peerNameHeight: CGFloat = 14.0
    static let nameOffsetAdjust: CGFloat = 4.0
    
}

class ProgressView: UIView, ProgressObserverDelegate {

    
    var transcript:Transcript? {
        didSet {
            // Create the progress observer
            observer = ProgressObserver(name: (transcript?.imageName)!, progress: (transcript?.progress)!)
            // Listen for progress changes
            observer.delegate = self
            // Compute name size
            let nameText = transcript?.peerID.displayName
            let nameSize = ProgressView.labelSize(nameText!, fontSize: ProgressViewConstructs.nameFontSize)
            
            // Comput the X,Y origin offsets
            var xOffset: CGFloat!
            var yOffset: CGFloat!
            
            if transcript?.direction == TranscriptDirection.SEND {
                // Sent images appear or right of view
                xOffset = 320 - ProgressViewConstructs.paddingX - ProgressViewConstructs.progressViewWidth
                yOffset = ProgressViewConstructs.bufferWhiteSpace / 2
                displayNameLabel.text = ""
            }
            else {
                // Received images appear on left of view with additional display name label
                xOffset = ProgressViewConstructs.paddingX
                yOffset = (ProgressViewConstructs.bufferWhiteSpace / 2) + nameSize.height - ProgressViewConstructs.nameOffsetAdjust
                displayNameLabel.text = nameText
            }
            
            // Set the dynamic frames
            displayNameLabel.frame = CGRect(x: xOffset, y: 1, width: nameSize.width, height: nameSize.height)
            progressView.frame = CGRect(x: xOffset, y: yOffset + 5, width: ProgressViewConstructs.progressViewWidth, height: ProgressViewConstructs.progressViewHeight)
            
        }
    }
    
    // View for showing resource send/receive progress
    private var progressView: UIProgressView!
    // View for displaying sender name (received transcripts only)
    private var displayNameLabel: UILabel!
    // KVO progress observer for updating the progress bar based on NSProgress changes
    private var observer: ProgressObserver!
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // Initialization the sub views
        progressView = UIProgressView(progressViewStyle: .Default)
        progressView.progress = 0.0
        
        displayNameLabel = UILabel()
        displayNameLabel.font = UIFont.systemFontOfSize(10.0)
        displayNameLabel.textColor = UIColor(red: 34.0/255, green: 97.0/255, blue: 221.0/255, alpha: 1.0)
        
        // Add to parent view
        addSubview(displayNameLabel)
        addSubview(progressView)
        
    }
    
    //MARK: - class methods for computing sizes based on strings
    
    class func viewHeight(transcript:Transcript) -> CGFloat {
        // Return dynamic height of the cell based on the particular transcript
        if transcript.direction == TranscriptDirection.RECEIVE {
            // The senders name height is included for received messages
            return ProgressViewConstructs.peerNameHeight + ProgressViewConstructs.progressViewHeight + ProgressViewConstructs.bufferWhiteSpace - ProgressViewConstructs.nameOffsetAdjust
        }
        else{
            // Just the scaled image height and some buffer space
            return ProgressViewConstructs.progressViewHeight + ProgressViewConstructs.bufferWhiteSpace
        }
    }
    
    class func labelSize(string:NSString, fontSize:CGFloat) -> CGSize {
        return string.boundingRectWithSize(CGSize(width: ProgressViewConstructs.progressViewWidth, height: 2000), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(fontSize)], context: nil).size
    }
    
    
    //MARK: - ProgressObserver delegate methods
    
    func observerDidChange(observer: ProgressObserver) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            // Update the progress bar with the latest completion %
            self.progressView.progress = Float(observer.progress.fractionCompleted)
            print("progress changed completedUnitCount[\(observer.progress.completedUnitCount)]")
        }
    }
    
    func observerDidCancel(observer: ProgressObserver) {
        print("progress canceled")
    }
    func observerDidComplete(observer: ProgressObserver) {
        print("progress completed")
    }


}
