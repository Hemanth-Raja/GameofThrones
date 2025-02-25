//
//  Extensions.swift
//  GameofThrones
//
//  Created by Hemanth Raja on 29/11/18.
//  Copyright © 2018 Hemanthraja. All rights reserved.
//

import UIKit

let imagecache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImagesUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        //chech for catched image first
        if let cachedImage = imagecache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //otherwise hit an errorso so lets return out
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error as Any)
                return
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!){
                    imagecache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                    
                }
            }
            
            }.resume()
    }   
}


