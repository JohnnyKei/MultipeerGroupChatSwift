//
//  MessageView.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import UIKit


struct MessageViewConstants {
    // Constants for view sizing and alignment
    static let messageFontSize: CGFloat = 17.0
    static let nameFontSize: CGFloat = 10.0
    static let bufferWhiteSpace: CGFloat = 14.0
    static let detailTextLabelWidth: CGFloat = 220.0
    static let nameOffsetAdjust: CGFloat = 4.0
    static let ballonInsetTop: CGFloat = 30.0 / 2
    static let ballonInsetLeft: CGFloat = 36.0 / 2
    static let ballonInsetBottom: CGFloat = 30.0 / 2
    static let ballonInsetRight: CGFloat = 46.0 / 2
    static var ballonInsetWidth: CGFloat{ return ballonInsetLeft + ballonInsetRight }
    static var ballonInsetHeight: CGFloat { return ballonInsetTop + ballonInsetBottom }
    static let ballonMiddleWidth: CGFloat = 30.0 / 2
    static let ballonMiddleHeight: CGFloat = 6.0 / 2
    static var ballonMinHeight: CGFloat { return ballonInsetHeight + ballonMiddleHeight }
    static let ballonHeightPadding: CGFloat = 10.0
    static let ballonWidthPadding: CGFloat = 30.0
}

class MessageView: UIView {
    
    //Global Variables
    var transcript:Transcript? {
        didSet {
            let messageText = transcript?.message
            messageLabel?.text = messageText
            
            let labelSize = MessageView.labelSize(messageText!, fontSize: MessageViewConstants.messageFontSize)
            let ballonSize = MessageView.ballonSize(labelSize)
            let nameText = transcript?.peerID.displayName
            let nameSize = MessageView.labelSize(nameText!, fontSize: MessageViewConstants.nameFontSize)
            
            
            var xOffsetLabel: CGFloat!
            var xOffsetBallon: CGFloat!
            var yOffset: CGFloat!
            
            if transcript?.direction == TranscriptDirection.SEND {
                // Sent messages appear or right of view
                xOffsetLabel = 320 - labelSize.width - (MessageViewConstants.ballonWidthPadding / 2) - 3
                xOffsetBallon = 320 - ballonSize.width
                yOffset = MessageViewConstants.bufferWhiteSpace / 2
                nameLabel?.text = ""
                messageLabel?.textColor = UIColor.whiteColor()
                ballonView?.image = ballonImageRight?.resizableImageWithCapInsets(ballonInsetsRight!)

            }
            else {
                // Received messages appear on left of view with additional display name label
                xOffsetBallon = 0
                xOffsetLabel = (MessageViewConstants.ballonWidthPadding / 2) + 3
                yOffset = (MessageViewConstants.bufferWhiteSpace / 2) + nameSize.height - MessageViewConstants.nameOffsetAdjust
                if transcript?.direction == TranscriptDirection.LOCAL {
                    nameLabel.text = "Session Admin"
                }
                else {
                    nameLabel.text = nameText
                }
                
                messageLabel.textColor = UIColor.darkTextColor()
                ballonView.image = ballonImageLeft?.resizableImageWithCapInsets(ballonInsetsLeft!)
            }
            
            messageLabel.frame = CGRect(x: xOffsetLabel, y: yOffset + 5, width: labelSize.width, height: labelSize.height)
            ballonView.frame = CGRect(x: xOffsetBallon, y: yOffset, width: ballonSize.width, height: ballonSize.height)
            nameLabel.frame = CGRect(x: xOffsetLabel - 2, y: 1, width: nameSize.width, height: nameSize.height)
        }
    }

    
    
    
    
    
    // Background image
    private var ballonView: UIImageView!
    // Message text string
    private var messageLabel: UILabel!
    // Name text (for received messages)
    private var nameLabel: UILabel!
    // Cache the background images and stretchable insets
    private var ballonImageLeft: UIImage!
    private var ballonImageRight: UIImage!
    private var ballonInsetsLeft: UIEdgeInsets!
    private var ballonInsetsRight: UIEdgeInsets!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        ballonView = UIImageView()
        messageLabel = UILabel()
        messageLabel?.numberOfLines = 0
        
        nameLabel = UILabel()
        nameLabel?.font = UIFont.systemFontOfSize(MessageViewConstants.nameFontSize)
        nameLabel?.textColor = UIColor(red: 34.0/255, green: 97.0/255, blue: 221.0/255, alpha: 1.0)
        
        ballonImageLeft = UIImage(named: "bubble-left")
        ballonImageRight = UIImage(named: "bubble-right")
        
        ballonInsetsLeft = UIEdgeInsets(top: MessageViewConstants.ballonInsetTop, left: MessageViewConstants.ballonInsetRight, bottom: MessageViewConstants.ballonInsetBottom, right: MessageViewConstants.ballonInsetLeft)
        ballonInsetsRight = UIEdgeInsets(top: MessageViewConstants.ballonInsetTop, left: MessageViewConstants.ballonInsetLeft, bottom: MessageViewConstants.ballonInsetBottom, right: MessageViewConstants.ballonInsetRight)

        addSubview(ballonView!)
        addSubview(messageLabel!)
        addSubview(nameLabel!)
        
        
        
        
    }

    //MARK: - class methods for computing sizes based on strings
    class func viewHeight(transcript:Transcript) -> CGFloat {
        let labelHeight = ballonSize(labelSize(transcript.message! as NSString, fontSize: MessageViewConstants.messageFontSize)).height
        if transcript.direction != TranscriptDirection.SEND {
            let nameHeight: CGFloat = labelSize(transcript.peerID.displayName, fontSize: MessageViewConstants.nameFontSize).height
            return labelHeight + nameHeight + MessageViewConstants.bufferWhiteSpace - MessageViewConstants.nameOffsetAdjust
            
        }
        else {
            return labelHeight + MessageViewConstants.bufferWhiteSpace
        }
        
    }
    
    
    private class func labelSize(string:NSString, fontSize:CGFloat) -> CGSize {
        return string.boundingRectWithSize(CGSize(width: MessageViewConstants.detailTextLabelWidth, height: 2000), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(fontSize)], context: nil).size
    }
    
    private class func ballonSize(labelSize:CGSize) -> CGSize {
        var ballonSize: CGSize = CGSizeZero  //should initilize
        if labelSize.height < MessageViewConstants.ballonInsetHeight {
            ballonSize.height = MessageViewConstants.ballonMinHeight
        }
        else {
            ballonSize.height = labelSize.height + MessageViewConstants.ballonHeightPadding
        }
        ballonSize.width = labelSize.width + MessageViewConstants.ballonWidthPadding
        
        
        return ballonSize
    }
    
    
    
    
    
}
