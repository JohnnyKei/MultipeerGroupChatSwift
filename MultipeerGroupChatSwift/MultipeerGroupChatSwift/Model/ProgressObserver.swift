//
//  ProgressObserver.swift
//  MultipeerGroupChatSwift
//
//  Created by SatoKei on 2015/11/14.
//  Copyright © 2015年 Kei Sato. All rights reserved.
//

import Foundation


protocol ProgressObserverDelegate: NSObjectProtocol{
    func observerDidChange(observer:ProgressObserver)
    func observerDidCancel(observer:ProgressObserver)
    func observerDidComplete(observer:ProgressObserver)
}

class ProgressObserver :NSObject{
    
    let kProgressCancelledKeyPath = "cancelled"
    let kProgressCompletedUnitCountKeyPath = "completedUnitCount"
    
    
    private(set) var name: String!
    private(set) var progress: NSProgress!
    weak var delegate:ProgressObserverDelegate?
    
    init(name: String, progress:NSProgress) {
        super.init()
        self.name = name.copy() as! String
        self.progress = progress
        self.progress.addObserver(self, forKeyPath: kProgressCancelledKeyPath, options: .New, context: nil)
        self.progress.addObserver(self, forKeyPath: kProgressCompletedUnitCountKeyPath, options: .New, context: nil)
    }
    
    deinit {
        self.progress.removeObserver(self, forKeyPath: kProgressCancelledKeyPath)
        self.progress.removeObserver(self, forKeyPath: kProgressCompletedUnitCountKeyPath)
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        let progress = object as! NSProgress
        
        if keyPath == kProgressCancelledKeyPath {
            self.delegate?.observerDidCancel(self)
        } else if keyPath == kProgressCompletedUnitCountKeyPath {
            self.delegate?.observerDidChange(self)
            if progress.completedUnitCount == progress.totalUnitCount {
                self.delegate?.observerDidComplete(self)
            }
        }
    }
}
