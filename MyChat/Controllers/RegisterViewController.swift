//
//  RegisterViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 27/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2.0
        imageView.layer.borderColor = UIColor.black.cgColor
        return imageView
    }()
    
    private let firstNameField: UITextField = {
        
        let firstNameField = UITextField()
        firstNameField.autocapitalizationType = .none
        firstNameField.autocorrectionType = .no
        firstNameField.returnKeyType = .continue
        firstNameField.layer.cornerRadius = 12
        firstNameField.layer.borderWidth = 1
        firstNameField.layer.borderColor = UIColor.lightGray.cgColor
        firstNameField.placeholder = "First name"
        
        //to add buffer on the left side
        firstNameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        firstNameField.leftViewMode = .always
        
        firstNameField.backgroundColor = .secondarySystemBackground
        return firstNameField
    }()
    
    private let lastNameField: UITextField = {
        
        let lastNameField = UITextField()
        lastNameField.autocapitalizationType = .none
        lastNameField.autocorrectionType = .no
        lastNameField.returnKeyType = .continue
        lastNameField.layer.cornerRadius = 12
        lastNameField.layer.borderWidth = 1
        lastNameField.layer.borderColor = UIColor.lightGray.cgColor
        lastNameField.placeholder = "Last name"
        
        //to add buffer on the left side
        lastNameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        lastNameField.leftViewMode = .always
        
        lastNameField.backgroundColor = .secondarySystemBackground
        return lastNameField
    }()
    
    private let emailField: UITextField = {
        
        let emailField = UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.layer.cornerRadius = 12
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder = "Email Address"
        
        //to add buffer on the left side
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        emailField.leftViewMode = .always
        
        emailField.backgroundColor = .secondarySystemBackground
        return emailField
    }()
    
    private let passwordField: UITextField = {
        
        let passwordField = UITextField()
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.returnKeyType = .done
        passwordField.layer.cornerRadius = 12
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.lightGray.cgColor
        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        
        //to add buffer on the left side
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        passwordField.leftViewMode = .always
        
        passwordField.backgroundColor = .secondarySystemBackground
        return passwordField
    }()
    
    private let registerButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Register"
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
//       navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
//                                                            style: .done ,
//                                                            target: self,
//                                                            action: #selector(didPressRegister))
        
        registerButton.addTarget(self,
                              action: #selector(registerButtonPressed),
                              for: .touchUpInside)
        
        //Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        //want to add profile pic
        let gesture = UITapGestureRecognizer(target: self,
                                          action: #selector(didPressChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        imageView.layer.cornerRadius = imageView.width / 2.0
        
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom + 20,
                                      width: scrollView.width - 60,
                                      height: 52)
        
        lastNameField.frame = CGRect(x: 30,
                                     y: firstNameField.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom + 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 20,
                                   width: scrollView.width - 60,
                                   height: 52)
        
    }
    
    @objc private func didPressChangeProfilePic() {
        //get action sheet
        presentPhotoActionSheet()
    }
    
    @objc private func registerButtonPressed() {
        
        //takes care that no field is empty
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let firstName = firstNameField.text,
            let lastName = lastNameField.text,
            let email = emailField.text,
            let password = passwordField.text,
            !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        
        spinner.show(in: view)
        //Firebase Login
        
        //Check if email exist
        DatabaseManager.shared.userExists(with: email) {[weak self] (exists) in
            
            //adding weak self to kill retention cycle
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                //user exist
                strongSelf.alertUserLoginError(message: "User already exists with same email!")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) {(authResult, error) in
                
                guard authResult != nil, error == nil else{
                    print("Error occured while creating user!")
                    return
                }
                
                let chatUser = ChatAppuser(firstName: firstName,
                                           lastName: lastName,
                                           emailId: email)
                DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                    
                    if success {
                        //upload image
                        guard  let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = chatUser.profilePictureFilename
                        StorageManager.shared.uploadProfilePic(with: data, fileName: fileName) { (result) in
                            
                            switch result {
                                
                            case .success(let downloadURL):
                                UserDefaults.standard.set(downloadURL, forKey: "profilePicURL")
                                print(downloadURL)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        }
                    }
                }
                
                //dissmiss current view
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
                
            }
            
        }
        
    }
    
    func alertUserLoginError(message: String = "Please enter correct info to create new account!")  {
        
        let alert = UIAlertController(title: "Oops!",
                                      message: message,
                                      preferredStyle: .alert)
        //adding action to dissmiss
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
//    @objc private func didPressRegister() {
//        
//        let vc = RegisterViewController()
//        vc.title = "Create Account"
//        navigationController?.pushViewController(vc, animated: true)
//    }
    
}


extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(textField == emailField) {
            //we need to check password
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonPressed()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction (title: "Cancel",
                                             style: .cancel,
                                             handler: nil))
        actionSheet.addAction(UIAlertAction (title: "Take Photo",
                                             style: .default,
                                             handler: { [weak self]_  in
                                                
                                                self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction (title: "Choose Photo",
                                             style: .default,
                                             handler: { [weak self]_ in
                                                self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
        
    }
    
    func presentPhotoPicker() {
        
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{
            return
        }
        self.imageView.image =  selectedImage
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
}
