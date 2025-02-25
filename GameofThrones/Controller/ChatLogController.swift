//
//  ChatLogController.swift
//  GameofThrones
//
//  Created by Hemanth Raja on 30/11/18.
//  Copyright © 2018 Hemanthraja. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var user: User? {
        didSet {
            navigationItem.title = user?.Name
            observeMessages()
        }
    }
    
    
    var messages = [Message]()
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("Messages").child(messageId)
            messageRef.observe(.value, with: { (snapshot) in
                
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                let message = Message(dictionary: dictionary)
//                message.text = dictionary["text"] as? String
//                message.fromId = dictionary["fromId"] as? String
//                message.toId = dictionary["toId"] as? String
//                message.imageHeight = dictionary["imageHeight"] as? NSNumber
//                message.imageWidth = dictionary["imageWidth"] as? NSNumber
//                message.imageUrl = dictionary["imageUrl"] as? String

                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                        let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
                        self.collectionView.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                    }
                   
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    lazy var inputTextField:UITextField = {
        let inputTextfield = UITextField()
        inputTextfield.placeholder = "Enter Message.. "
        inputTextfield.translatesAutoresizingMaskIntoConstraints = false
        inputTextfield.delegate = self
        return inputTextfield
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.title = "Chat Log Controller"
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView : UIView = {
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        let uploadImageView  = UIImageView()
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.image = UIImage(named: "uploadimage")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadtap)))
        containerView.addSubview(uploadImageView)
        // Constraints
        
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        
        // Constraints
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        
        //Constraints
        
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        containerView.addSubview(separatorLineView)
        
        //x,y,w,h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        
        return containerView
    }()
    
    @objc func handleUploadtap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String , kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        
        if let videoUrl = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? NSURL {
            // print("Here's the file url: " , videoUrl)
            //we selected a video
            hadleVideoSelectedForUrl(url : videoUrl)
        } else {
            //we selected an image
            hadleImageSelectedForInfo(info: info as [String : AnyObject])
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func hadleVideoSelectedForUrl(url : NSURL){
        let filename = NSUUID().uuidString + ".mov"
        let ref = Storage.storage().reference().child("message_movies").child(filename)
        let uploadTask = ref.putFile(from: url as URL, metadata: nil) { (metadata, error) in
            if error != nil {
                print("Failed upload of video:" , error ?? "")
                return
            }
            ref.downloadURL { (url, error) in
                guard url != nil else {
                    // Uh-oh, an error occurred!
                    print("error url: " , error ?? "")
                    return
                }
                //print(url?.absoluteString ?? "")
                if let videoUrl = url?.absoluteString {
                    if let thumbnailImage = self.thumbnailImagenForFileUrl(urlString : videoUrl) {
                        print("uploaded")
                        self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                            let properties = ["imageUrl" : imageUrl , "imageWidth" : thumbnailImage.size.width , "imageHeight" : thumbnailImage.size.height , "videoUrl" : videoUrl ] as [String : Any]
                            self.sendMessageWithProperties(properties: properties as [String : AnyObject])
                        })
                    }
                }
            }
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.Name
        }
    }
    
//    private func thumbnailImagenForFileUrl(url: String) -> UIImage? {
//        let asset = AVAsset(url: URL(string: url)!)
//        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
//        assetImgGenerate.appliesPreferredTrackTransform = true
//        //Can set this to improve performance if target size is known before hand
//        //assetImgGenerate.maximumSize = CGSize(width,height)
//        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
//        do {
//            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
//            let thumbnail = UIImage(cgImage: img)
//            return thumbnail
//        } catch {
//            print(error.localizedDescription)
//            return nil
//        }
//    }
    
    func thumbnailImagenForFileUrl(urlString: String) -> UIImage? {
        let filePath = URL(string: urlString)?.absoluteURL
        print("filepath", filePath as Any)
        let asset = AVURLAsset(url: filePath!, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = false
        
        do {
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail
            
        } catch let error {
            print("*** Error generating thumbnail: \(error)")
            return UIImage(named: "black")
        }
    }

    
    private func hadleImageSelectedForInfo(info : [String : AnyObject]){
        //print("we selected an image")
        var selectedImagenFromPicker : UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImagenFromPicker = editedImage
        } else if let imagenOrigin = info["UIImagePickerControllerOriginalImage"]  as? UIImage {
            selectedImagenFromPicker = imagenOrigin
        }
        
        if let selectedImage = selectedImagenFromPicker {
            //uploadToFirebaseStorageUsingImage(image : selectedImage)
            uploadToFirebaseStorageUsingImage(image: selectedImage) { (imageUrl) in
                self.sendMessaegWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            }
        }
    }
    
    //private func uploadToFirebaseStorageUsingImage(image : UIImage){
    private func uploadToFirebaseStorageUsingImage(image : UIImage , completion : @escaping ( _ imageURL : String ) -> ()) {
        // print("Upload to FIREBASE!!")
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        if let uploadData = image.jpegData(compressionQuality: 0.2) {
            ref.putData(uploadData , metadata : nil , completion : { (metadata , error) in
                if error != nil {
                    print("Faild to upload image:" , error ?? "")
                    return
                }
                ref.downloadURL { (url, error) in
                    guard url != nil else {
                        // Uh-oh, an error occurred!
                        print(error ?? "")
                        return
                    }
                    //print(url?.absoluteString)
                    if let imageUrl = url?.absoluteString {
                        //self.sendMessageWithImageUrl(imageUrl : imageUrl , image : image)
                        completion(imageUrl)
                    }
                }
            })
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.isNavigationBarHidden = false
        self.dismiss(animated: true, completion: nil)
    }
   
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
        let indexPath = NSIndexPath(item: messages.count - 1, section: 0)
        collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboarDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)
      
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        UIView.animate(withDuration: keyboarDuration) {
            self.view.layoutIfNeeded()
        }

    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboarDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboarDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        cell.message = message
        cell.textView.text = message.text
        setupCell(cell: cell, message: message)
        
        if let text = message.text{
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        cell.playButton.isHidden = message.videoUrl == nil
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if let profileImageUrl = self.user?.ProfileImageUrl {
            cell.profileImageView.loadImagesUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        
        
        if message.fromId == Auth.auth().currentUser?.uid {
            //Blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        } else {
            //Gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImagesUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        let message = messages[indexPath.item]
        if let text = message.text{
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat((imageHeight / imageWidth) * 200)
        }
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    
    @objc func handleSend() {
        
        let properties =  ["text": inputTextField.text!] as [String : Any]
        sendMessageWithProperties(properties: properties as [String : AnyObject])
    }
    
    private func sendMessaegWithImageUrl(imageUrl: String, image: UIImage) {
        let properties =  ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        sendMessageWithProperties(properties: properties as [String : AnyObject])
        
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        let ref = Database.database().reference().child("Messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = NSDate().timeIntervalSince1970 as NSNumber
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        
        // Key $0 values $1
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error as Any)
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            guard let messageId = childRef.key else {
                return
            }
            userMessagesRef.updateChildValues([messageId: true])
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessageRef.updateChildValues([messageId: true])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    var startingFrame : CGRect?
    var backgrounView : UIView?
    var startingImageView : UIImageView?
    
    func performZoomInForStartingImageView(startingImageView : UIImageView){
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        //print("Performing zoom in logic in controller")
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, from: nil)
        //print(startingFrame)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        //zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(hadleZoomOut))
        zoomTap.numberOfTapsRequired = 1
        zoomingImageView.addGestureRecognizer(zoomTap)
        zoomingImageView.isUserInteractionEnabled = true
        
        if let keyWindow = UIApplication.shared.keyWindow {
            backgrounView = UIView(frame: keyWindow.frame)
            backgrounView?.backgroundColor = UIColor.white
            backgrounView?.alpha = 0
            keyWindow.addSubview(backgrounView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.backgrounView?.alpha = 1
                self.inputContainerView.alpha = 0
                // math?
                // h2 / w2 = h1 / w1
                // h2 = h1 /w1 * w2
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }) { (completed) in
                //do nothing
            }
        }
    }
    
    @objc func hadleZoomOut(tapGesture : UITapGestureRecognizer){
        //print("Zooming out...")
        if let zoomOutImageView = tapGesture.view {
            //neef to animate back out controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.backgrounView?.alpha = 0
                self.inputContainerView.alpha = 1
            }) { (completion) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            }
        }
    }
}




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
