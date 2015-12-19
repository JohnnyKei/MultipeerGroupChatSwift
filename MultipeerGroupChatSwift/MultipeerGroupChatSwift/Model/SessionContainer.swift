//
//  SessionContainer.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol SessionContainerDelegate: NSObjectProtocol {
    func receivedTranscript(transcript:Transcript)
    func updateTranscript(transcript:Transcript)
}


class SessionContainer: NSObject, MCSessionDelegate{
    
    private(set) var session: MCSession!
    weak var delegate: SessionContainerDelegate?
    private var advertiserAssistant: MCAdvertiserAssistant?
    
    init(displayName:String, serviceType:String) {
        super.init()
        let peerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        advertiserAssistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
        advertiserAssistant?.start()
    }
    
    deinit {
        advertiserAssistant?.stop()
        session.disconnect()
    }
    
    private func stringForPeerConnectionState(state:MCSessionState) -> String {
        switch state {
            case .Connected:
                return "Connected"
            case .Connecting:
                return "Connecting"
            case .NotConnected:
                return "NotConnected"
        }
    }
    
    //MARK: Public Methods
    
    func sendMessage(message: String) -> Transcript? {
        let messageData = message.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try session.sendData(messageData!, toPeers: session.connectedPeers, withMode: .Reliable)
            return Transcript(peerID: session.myPeerID, message: message, direction: TranscriptDirection.SEND)
        }
        catch let error as NSError{
            print("Error sending message to peers [\(error)]")
            return nil
        }
    }
    
    func sendImage(imageUrl: NSURL) -> Transcript? {
        var progress:NSProgress?
        for peerID in session.connectedPeers {
            progress = session.sendResourceAtURL(imageUrl, withName: imageUrl.lastPathComponent!, toPeer: peerID, withCompletionHandler: { (error) -> Void in
                if (error != nil) {
                    print("Send resource to peer [\(peerID.displayName)] completed with Error [\(error)]")
                }
                else {
                    let transcript = Transcript(peerID: self.session.myPeerID, imageUrl: imageUrl, direction: TranscriptDirection.SEND)
                    self.delegate?.updateTranscript(transcript)
                }
            })
        }
        
        return Transcript(peerID: session.myPeerID, imageName: imageUrl.lastPathComponent, progress: progress, direction: TranscriptDirection.SEND)
    }
    
    
    
    
    //MARK: MCSessionDelegate
    
    // Override this method to handle changes to peer session state
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print("Peer \(peerID.displayName) changed state to \(stringForPeerConnectionState(state))")
        let adminMessage =  "\(peerID.displayName) is \(stringForPeerConnectionState(state))"
        // Create an local transcript
        let transcript = Transcript(peerID: peerID, message: adminMessage, direction: TranscriptDirection.RECEIVE)
        // Notify the delegate that we have received a new chunk of data from a peer
        self.delegate?.receivedTranscript(transcript)
        
    }
    // MCSession Delegate callback when receiving data from a peer in a given session
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        // Decode the incoming data to a UTF8 encoded string
        let recivedMessage = String(data: data, encoding: NSUTF8StringEncoding)
        
        // Create an received transcript
        let transcript = Transcript(peerID: peerID, message: recivedMessage, direction: TranscriptDirection.RECEIVE)
        
        // Notify the delegate that we have received a new chunk of data from a peer
        self.delegate?.receivedTranscript(transcript)
        
    }
    
    // MCSession delegate callback when we start to receive a resource from a peer in a given session
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
        print("Start receiving resource [\(resourceName)] from peer \(peerID.displayName) with progress \(progress)")
        
        // Create a resource progress transcript
        let transcript = Transcript(peerID: peerID, imageName: resourceName, progress: progress, direction: TranscriptDirection.RECEIVE)
        
        // Notify the UI delegate
        self.delegate?.receivedTranscript(transcript)
        
        
    }
    
    // MCSession delegate callback when a incoming resource transfer ends (possibly with error)
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
        // If error is not nil something went wrong
        if error != nil {
            print("Error \(error?.localizedDescription) receiving resource from peer \(peerID.displayName)")
        }
        else {
            // No error so this is a completed transfer.  The resources is located in a temporary location and should be copied to a permenant locatation immediately.
            // Write to documents directory
            
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let copyPath = "\(paths[0])/\(resourceName)"
            do {
                try NSFileManager.defaultManager().copyItemAtPath(localURL.path!, toPath: copyPath)
                let imageUrl = NSURL(fileURLWithPath: copyPath)
                let transcript = Transcript(peerID: peerID, imageUrl: imageUrl, direction: TranscriptDirection.RECEIVE)
                self.delegate?.updateTranscript(transcript)
                
            }catch let error as NSError {
                print("Error copying resource to documents directory \(error.localizedDescription)")
            }
        }
        
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received data over stream with name \(streamName) from peer \(peerID.displayName)")
    }
    
}
