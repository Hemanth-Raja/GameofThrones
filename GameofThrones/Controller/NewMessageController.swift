//
//  NewMessageController.swift
//  GameofThrones
//
//  Created by Hemanth Raja on 27/11/18.
//  Copyright © 2018 Hemanthraja. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class NewMessageController: UITableViewController {
    
    let cellId = "CellId"
    var users = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    func fetchUser() {
        Database.database().reference().child("Users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.id = snapshot.key
                user.Name = dictionary["Name"] as? String
                user.Email = dictionary["Email"] as? String
                user.ProfileImageUrl = dictionary["ProfileImageUrl"] as? String
                
                
                self.users.append(user)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }, withCancel: nil)
    }

    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        cell.textLabel?.text = user.Name
        cell.detailTextLabel?.text = user.Email
        cell.imageView?.contentMode = .scaleAspectFill

        
        if let profileImageUrl = user.ProfileImageUrl {
            
            cell.profileImageView.loadImagesUsingCacheWithUrlString(urlString: profileImageUrl)
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesController: MessagesController?
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            print("Dismissed")
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForuser(user: user)
        }
    }
   
}


