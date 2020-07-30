//
//  LoginViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 27/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    private let loginButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        
        let button = FBLoginButton()
        button.permissions = ["email,public_profile"]
        return button
    }()
    
    private let orLabel: UILabel = {
        
        let label = UILabel()
        label.text = "--OR--"
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        return label
    }()
    
    private let googleLoginButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification,
                                                               object: nil,
                                                               queue: .main) {[weak self] (notification) in
                                                                
                                                                guard let strongSelf = self else {
                                                                    return
                                                                }
                                                                
                                                                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                                                                
        }
        
        view.backgroundColor = UIColor.white
        title = "Log In"
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //Facbook delegate
        facebookLoginButton.delegate = self
        
        //googleSignIn delegate
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done ,
                                                            target: self,
                                                            action: #selector(didPressRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonPressed),
                              for: .touchUpInside)
        
        //Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(orLabel)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    //func do destroy observer for google signin to save space
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 20,
                                   width: scrollView.width - 60,
                                   height: 52)
        orLabel.frame = CGRect(x: 30,
                               y: loginButton.bottom + 20,
                               width: scrollView.width - 60,
                               height: 52)
        
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: orLabel.bottom + 20,
                                           width: scrollView.width - 60,
                                           height: 52)
        
        googleLoginButton.frame = CGRect(x: 30,
                                           y: facebookLoginButton.bottom + 20,
                                           width: scrollView.width - 60,
                                           height: 52)
        
    }
    
    @objc private func loginButtonPressed() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        
        spinner.show(in: self.view)
        
        //Firebase Login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) {[weak self] (authResult, error) in
            
            //weak self added to kill retrntion cycle
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                //dissmiss spinner
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Failed to login the user!")
                return
            }
            
            let user = result.user
            print("User logged in \(user)")
            
            //need to dismiss this view
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertUserLoginError()  {
        
        let alert = UIAlertController(title: "Oops!",
                                      message: "Please enter correct info!",
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


extension LoginViewController: UITextFieldDelegate {
    
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

extension LoginViewController:  LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
        //no operation to be done as we are already loggedin
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            print("User failed to login with Facebook!")
            return
        }
        
        //need to get those credentials to add into db
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email,  name" ],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { (_, result, error) in
            
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make FB graph req")
                return
            }
            
            guard let username = result["name"] as? String,
                let email = result["email"] as? String else{
                    print("Failed to get email from FB!")
                    return
            }
            
            let nameComponents = username.components(separatedBy: " ")
            guard nameComponents.count == 2 else {
                return
            }
            
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            DatabaseManager.shared.userExists(with: email) { (exists) in
                
                if !exists  {
                    DatabaseManager.shared.insertUser(with: ChatAppuser(firstName: firstName,
                                                                        lastName: lastName,
                                                                        emailId: email))
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
                
                //weak self added to kill retrntion cycle
                guard let strongSelf = self else {
                    return
                }
                
                guard  authResult != nil, error == nil else{
                    print("Error while logging with facebook with credentials!")
                    return
                }
                
                print("Logged in via FB!")
                //need to dismiss this view
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            }
            
        }
        
    }
   
}
