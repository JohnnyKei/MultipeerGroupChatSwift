//
//  Transcript.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum TranscriptDirection :Int{
    case SEND = 0
    case RECEIVE
    case LOCAL
}

class Transcript: NSObject {
    
    private(set) var direction: TranscriptDirection!
    private(set) var peerID: MCPeerID!
    private(set) var message: String?
    private(set) var imageUrl: NSURL?
    private(set) var imageName: String?
    private(set) var progress: NSProgress?
    
    
    init(peerID: MCPeerID, message: String?, direction: TranscriptDirection) {
        super.init()
        initlize(peerID, message: message, imageName: nil, imageUrl: nil, progress: nil, direction: direction)
    }
    
    init(peerID: MCPeerID, imageUrl: NSURL?, direction: TranscriptDirection) {
        super.init()
        initlize(peerID, message: nil, imageName: imageUrl?.lastPathComponent, imageUrl: imageUrl, progress: nil, direction: direction)
    }
    
    init(peerID: MCPeerID, imageName: String?, progress: NSProgress?, direction: TranscriptDirection) {
        super.init()
        initlize(peerID, message: nil, imageName: imageName, imageUrl: nil, progress: progress, direction: direction)
    }
    
    private func initlize (peerID: MCPeerID, message: String?, imageName: String?, imageUrl: NSURL?, progress:NSProgress?, direction: TranscriptDirection) {
        self.peerID = peerID
        self.message = message
        self.imageName = imageName
        self.imageUrl = imageUrl
        self.progress = progress
        self.direction = direction
    }
}
