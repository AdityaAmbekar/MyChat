//
//  ProfileViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 27/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Log out"]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self ,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    

    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailId: email)
        let fileName = "\(safeEmail)_Profile_Pic.png"
        let path = "images/" + fileName
        
        
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURLForPath(for: path) {[weak self] ( result) in
            
            switch result {
            case .success(let url):
                 self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download URL \(error)")
            }
        }
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }.resume()
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = NSTextAlignment.center
        cell.textLabel?.textColor = UIColor.red
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "",
                                      message: "",
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Log Out",
                                      style: .destructive,
                                      handler: {[weak self] (_) in
                                        
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        
                                        //Log out from FB
                                        FBSDKLoginKit.LoginManager().logOut()
                                        
                                        //Log out from google
                                        GIDSignIn.sharedInstance()?.signOut()
                                        
                                        do {
                                            try FirebaseAuth.Auth.auth().signOut()
                                            
                                            let vc = LoginViewController()
                                            let nav = UINavigationController(rootViewController: vc)
                                            nav.modalPresentationStyle = .fullScreen
                                            
                                            strongSelf.present(nav, animated: false)
                                        }
                                        catch {
                                            print("Failed to logout!")
                                        }
                                        
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel,
                                      handler: nil ))
        
        present(alert, animated: true)
        
    }
    
}
