//
//  RegisterViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 27/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
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
        
        firstNameField.backgroundColor = UIColor.white
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
        
        lastNameField.backgroundColor = UIColor.white
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
        
        emailField.backgroundColor = UIColor.white
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
        
        passwordField.backgroundColor = UIColor.white
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
        
        view.backgroundColor = UIColor.white
        title = "Register"
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done ,
                                                            target: self,
                                                            action: #selector(didPressRegister))
        
        registerButton.addTarget(self,
                              action: #selector(loginButtonPressed),
                              for: .touchUpInside)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        
        //Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        //want to add profile pic
        let gesture = UIGestureRecognizer(target: self,
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
        
        
    }
    
    @objc private func loginButtonPressed() {
        
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
        
        //Firebase Login
        
    }
    
    func alertUserLoginError()  {
        
        let alert = UIAlertController(title: "Oops!",
                                      message: "Please enter correct info to create new account !",
                                      preferredStyle: .alert)
        //adding action to dissmiss
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc private func didPressRegister() {
        
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(textField == emailField) {
            //we need to check password
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonPressed()
        }
        
        return true
    }
}
