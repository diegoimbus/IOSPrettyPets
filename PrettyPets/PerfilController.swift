//
//  PerfilController.swift
//  PrettyPets
//
//  Created by Alejandra Landinez on 11/7/17.
//  Copyright © 2017 LordBoxen. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class PerfilController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //variables
    let storage = Storage.storage().reference()
    let databaseRef = Database.database().reference()
    
    //outlets
    @IBOutlet weak var profile_image: UIImageView!
    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var edadLabel: UILabel!
    @IBOutlet weak var generoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser?.uid == nil {
            logout()
        }

        setupProfile()

    }
    //actions
    @IBAction func uploadImageButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    //functions
    func setupProfile(){
        

            profile_image.layer.cornerRadius = profile_image.frame.size.width/2
            profile_image.clipsToBounds = true
           let uid = Auth.auth().currentUser?.uid
            databaseRef.child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dict = snapshot.value as? [String: AnyObject]{
                    self.nombreLabel.text = dict["nombre"] as? String
                    if let profileImageURL = dict["pic"] as? String
                    {
                        let url = URL(string: profileImageURL)
                        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                            if error != nil {
                                print(error!)
                                return
                            }
                            DispatchQueue.main.async {
                                self.profile_image?.image = UIImage(data: data!)
                            }
                        }).resume()
                    }
                }
            })
        

    }
    
    func logout(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "login")
        present(loginViewController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker {
            profile_image.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveChanges(){
        let imageName = NSUUID().uuidString
        
        let storedimage = storage.child("profile_images").child(imageName)
        
        if let uploadData = UIImagePNGRepresentation(self.profile_image.image!){
            storedimage.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    print(error!)
                    return
                }
                storedimage.downloadURL(completion: { (url, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    if let  urlText = url?.absoluteString{
                        self.databaseRef.child("users").child((Auth.auth().currentUser?.uid)!).updateChildValues(["pic" : urlText], withCompletionBlock: { (error, ref) in
                            if error != nil {
                                print(error!)
                                return
                            }
                        })
                    }
                })
            })
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
}
