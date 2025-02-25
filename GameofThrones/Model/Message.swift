//
//  Message.swift
//  GameofThrones
//
//  Created by Hemanth Raja on 30/11/18.
//  Copyright © 2018 Hemanthraja. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var toId : String?
    var text : String?
    var fromId : String?
    var timestamp : NSNumber?
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    var videoUrl : String?
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }

    init(dictionary : [String : AnyObject]){
        super.init()
        
        toId = dictionary["toId"] as? String
        text = dictionary["text"] as? String
        fromId = dictionary["fromId"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }
}
