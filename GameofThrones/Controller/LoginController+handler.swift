//
//  LoginController+handler.swift
//  GameofThrones
//
//  Created by Hemanth Raja on 27/11/18.
//  Copyright © 2018 Hemanthraja. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import NVActivityIndicatorView

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegister() {
        let size = CGSize(width: 30, height: 30)
        startAnimating(size, message: "Loading...", type: NVActivityIndicatorType(rawValue: 1), color: UIColor.blue, fadeInAnimation: nil)
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text
            else {
                print("Form is not valid")
                return
        }
        
        
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            // ...
            //  guard let user = authResult?.user else { return }
            
            if error != nil {
                print(error as Any)
                return
            }
            
            // Successfully Authenticated
            
            let userID = Auth.auth().currentUser!.uid
            let imageName = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference().child("Profile_images").child("\(imageName).png")
            
            let uploadData = self.profileImageView.image!.jpegData(compressionQuality: 0.1)
            
            storageRef.putData(uploadData!, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Upload Error")
                    print(error as Any)
                return
                }
                storageRef.downloadURL(completion: { (url, error) in
                    
                    if error != nil {
                        print("download error")
                        print(error as Any)
                        return
                   }
                    
                    let urll = url!.absoluteString
                    let values = ["Name": name, "Email": email, "ProfileImageUrl": urll]
                    let ref = Database.database().reference()
                    
                    let usersReference = ref.child("Users").child(userID)
                    usersReference.updateChildValues(values) { (err, ref) in
                        if err != nil {
                            print(err as Any)
                            return
                        }
//                        self.messagesController?.navigationItem.title = values["Name"]
                        let user = User()
                        user.Name = values["Name"]
                        user.Email = values["Email"]
                        user.ProfileImageUrl = values["ProfileImageUrl"]
                        self.messagesController?.setupNavBarWithUser(user: user)
                        self.dismiss(animated: true, completion: nil)
                        self.stopAnimating()
                    }
                })
            })
            
        }
        
        
    }
    

    
    @objc func handleProfileImageView() {
       let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker,animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Local variable inserted by Swift 4.2 migrator.
            let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
            
            /*
             Get the image from the info dictionary.
             If no need to edit the photo, use `UIImagePickerControllerOriginalImage`
             instead of `UIImagePickerControllerEditedImage`
             */
            print(info)
            if let editedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage{
                self.profileImageView.image = editedImage
            }
            
            //Dismiss the UIImagePicker after selection
            picker.dismiss(animated: true, completion: nil)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.isNavigationBarHidden = false
            self.dismiss(animated: true, completion: nil)
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
