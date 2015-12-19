//
//  ImageView.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import UIKit

struct ImageViewConstructs {
    static let imageViewHeightMax: CGFloat = 140.0
    static let imagePaddingX: CGFloat = 15.0
    static let nameFontSize: CGFloat = 10.0
    static let bufferWhiteSpace: CGFloat = 14.0
    static let detailTextLabelWidth: CGFloat = 220.0
    static let peerNameHeight: CGFloat = 12.0
    static let nameOffsetAdjust: CGFloat = 4.0
}


class ImageView: UIView {

    
    var transcript:Transcript? {
        didSet {
            // Load the image the specificed resource URL points to.
            let image = UIImage(contentsOfFile: (transcript?.imageUrl?.path)!)
            imageView.image = image
            
            // Get the image size and scale based on our max height (if necessary)
            let imageSize = image?.size
            var height = imageSize?.height
            var scale: CGFloat = 1.0
            
            // Compute scale between the original image and our max row height
            scale = ImageViewConstructs.imageViewHeightMax / height!
            height = ImageViewConstructs.imageViewHeightMax
            
            let width = (imageSize?.width)! * scale
            
            // Compute name size
            let nameText = transcript?.peerID.displayName
            let nameSize = ImageView.labelSize(nameText!, fontSize: ImageViewConstructs.nameFontSize)
            
            // Comput the X,Y origin offsets
            var xOffsetBallon: CGFloat!
            var yOffset: CGFloat!
            
            if transcript?.direction == TranscriptDirection.SEND {
                // Sent images appear or right of view
                xOffsetBallon = 320 - width - ImageViewConstructs.imagePaddingX
                yOffset = ImageViewConstructs.bufferWhiteSpace / 2
                nameLabel.text = ""
            }
            else {
                // Received images appear on left of view with additional display name label
                xOffsetBallon = ImageViewConstructs.imagePaddingX
                yOffset = (ImageViewConstructs.bufferWhiteSpace / 2) + nameSize.height - ImageViewConstructs.nameOffsetAdjust
                nameLabel.text = nameText
            }
            
            
            // Set the dynamic frames
            nameLabel.frame = CGRect(x: xOffsetBallon, y: 1, width: nameSize.width, height: nameSize.height)
            imageView.frame = CGRect(x: xOffsetBallon, y: yOffset, width: width, height: height!)
            
            

        }
    }
    
    // Background image
    private var imageView: UIImageView!
    // Name text (for received messages)
    private var nameLabel: UILabel!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        imageView = UIImageView()
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        imageView.layer.borderWidth = 0.5
        
        nameLabel = UILabel()
        nameLabel.font = UIFont.systemFontOfSize(10.0)
        nameLabel.textColor = UIColor(red: 34.0/255, green: 97.0/255, blue: 221.0/255, alpha: 1.0)
        
        addSubview(imageView)
        addSubview(nameLabel)
        
    }
    
    
    //MARK: - class methods for computing sizes based on strings

    
    class func viewHeight(transcript:Transcript) -> CGFloat {
        // Return dynamic height of the cell based on the particular transcript
        if transcript.direction == TranscriptDirection.RECEIVE {
            return ImageViewConstructs.peerNameHeight + ImageViewConstructs.imageViewHeightMax +  ImageViewConstructs.bufferWhiteSpace - ImageViewConstructs.nameOffsetAdjust
        }
        else {
            // Just the scaled image height and some buffer space
            return ImageViewConstructs.imageViewHeightMax + ImageViewConstructs.bufferWhiteSpace
        }
    }
    
    class func labelSize(string:NSString, fontSize:CGFloat) -> CGSize {
        return string.boundingRectWithSize(CGSize(width: ImageViewConstructs.detailTextLabelWidth, height: 2000), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(fontSize)], context: nil).size
    }

}
