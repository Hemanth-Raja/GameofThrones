//
//  ViewController.swift
//  GameofThrones
//
//  Created by Hemanth Raja on 24/11/18.
//  Copyright © 2018 Hemanthraja. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController  {
    
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogOut))
        
        let image = UIImage(named: "edit")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
//        observeMessages()
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //print(indexPath.row)
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue { (error, reg) in
                if error != nil {
                    print("Faild to delete message" , error ?? "")
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfData()
                
                //this is one way updating the table, but its actually not that safe
                /* self.messages.remove(at: indexPath.row)
                 self.tableView.deleteRows(at: [indexPath], with: .automatic)*/
                
            }
        }
    }
    

    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessageWithId(messageId: messageId)
                
            }, withCancel: nil)

        }, withCancel: nil)
        ref.observe(.childRemoved, with: { (snapshot) in
            //print(snapshot.key)
            //print(self.menssageDiccionary)
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfData()
            
        }, withCancel: nil)
    }
    
    private func attemptReloadOfData() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
        
        
    }
    
    private func fetchMessageWithId(messageId: String) {
        let messagereference = Database.database().reference().child("Messages").child(messageId)
        messagereference.observe(.value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary)
//                message.toId = dictionary["toId"] as? String
//                message.fromId = dictionary["fromId"] as? String
//                message.text = dictionary["text"] as? String
//                message.timestamp = dictionary["timestamp"] as? NSNumber
                //                self.messages.append(message)
                if let chatPartnerId = message.chatPartnerId() {
                    self.messagesDictionary[chatPartnerId] = message
                    
                }
                
                self.attemptReloadOfData()
            }
        }, withCancel: nil)
    }
    
    var timer: Timer?
    
    @objc func handleReloadTable() {
        
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            return message1.timestamp?.intValue > message2.timestamp?.intValue
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let messages = self.messages[indexPath.row]
        cell.messages = messages
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("Users").child(chatPartnerId)
        ref.observe(.value, with: { (snapshot) in
           print(snapshot)
            
            guard let dictionary = snapshot.value as? [String: AnyObject]
                else {
                    return
            }
            
            let user = User()
            user.id = chatPartnerId
            user.Name = dictionary["Name"] as? String
            user.Email = dictionary["Email"] as? String
            user.ProfileImageUrl = dictionary["ProfileImageUrl"] as? String
            self.showChatControllerForuser(user: user)
            
        }, withCancel: nil)
//        print(message.text, message.toId, message.fromId)
    }
    
    @objc func handleNewMessage() {
        
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
        
    }
    
    func checkIfUserIsLoggedIn() {
        // user is not logged in
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogOut), with: nil, afterDelay: 0)
        }
        else {
            fetchUserAndSetNavBarTitle()
        }
        
    }
    
    func fetchUserAndSetNavBarTitle() {
        
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("Users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.Name = dictionary["Name"] as? String
                user.Email = dictionary["Email"] as? String
                user.ProfileImageUrl = dictionary["ProfileImageUrl"] as? String
                self.setupNavBarWithUser(user: user)
            }
            
        }, withCancel: nil)
        
    }
    
    func setupNavBarWithUser(user: User) {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()


        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(showChatController))
//        zoomTap.numberOfTapsRequired = 1
//        titleView.addGestureRecognizer(zoomTap)
//        titleView.isUserInteractionEnabled = true
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(containerView)
        
        let profilreImageView = UIImageView()
        profilreImageView.translatesAutoresizingMaskIntoConstraints = false
        profilreImageView.contentMode = .scaleAspectFill
        profilreImageView.layer.cornerRadius = 20
        profilreImageView.clipsToBounds = true
        if let profilerUmageUrl = user.ProfileImageUrl {
            profilreImageView.loadImagesUsingCacheWithUrlString(urlString: profilerUmageUrl)
        }
        
        containerView.addSubview(profilreImageView)
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        nameLabel.text = user.Name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profilreImageView.leftAnchor.constraint(equalTo: titleView.leftAnchor),
            profilreImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            profilreImageView.heightAnchor.constraint(equalTo: titleView.heightAnchor) ,
            profilreImageView.widthAnchor.constraint(equalToConstant: 40),
            nameLabel.leftAnchor.constraint(equalTo: profilreImageView.rightAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: profilreImageView.centerYAnchor),
            nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            nameLabel.heightAnchor.constraint(equalTo : profilreImageView.heightAnchor),
            containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor)
            ])
        
        self.navigationItem.titleView = titleView

        
        
    }
    
    @objc func showChatControllerForuser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
        
        
    }
    
    @objc func handleLogOut() {
        let loginController = LoginController()
        
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        loginController.messagesController = self
        present(loginController, animated:  true, completion: nil)
    }


}


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
