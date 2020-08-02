//
//  AppDelegate.swift
//  MyChat
//
//  Created by Aditya Ambekar on 27/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
  
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        //Firebase configuration
        FirebaseApp.configure()
        
        //Google SigIn
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        ApplicationDelegate.shared.application(
                  application,
                  didFinishLaunchingWithOptions: launchOptions
              )

        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )

        return GIDSignIn.sharedInstance().handle(url)
    }
    
    //Google SignIn setup
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        guard error == nil else {
            print("Failed to signIn with Google \(error!)")
            return
        }
        
        print("Did signIn with google")
        
        //check if user exists in db
        guard let email = user.profile.email,
            let firstName = user.profile.givenName,
            let lastName = user.profile.familyName else {
                return
        }
        
        //save user deafault to cache
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        DatabaseManager.shared.userExists(with: email) { (exists) in
            
            if !exists {
                //insert into DB
                let chatUser = ChatAppuser(firstName: firstName,
                                           lastName: lastName,
                                           emailId: email)
                DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                    
                    if success {
                        //check if user have google image
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                print("Error in getting image from google")
                                return
                            }
                            
                            //download the image
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                                
                                guard let data = data else {
                                    return
                                }
                                
                                //upload image
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
                                
                            }).resume()
                        }
                        
                    }
                }
            }
        }
        
        guard let authentication = user.authentication else {
            print("Missing auth obj from google")
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        
        Firebase.Auth.auth().signIn(with: credential) { (authResult, error) in
            
            guard authResult != nil, error == nil else {
                print("Missing credentials: \(error!)")
                return
            }
            
            print("Logged in with google")
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        
        print("Google user was disconnected: \(error!)")
    }

}

    

