//
//  ViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 27/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.red
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let value = UserDefaults.standard.bool(forKey: "loggedIn")
        
        if value == false {
            
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            
            present(nav, animated: false)
        }
    }


}

