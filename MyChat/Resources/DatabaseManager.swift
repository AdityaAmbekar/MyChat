//
//  DatabaseManager.swift
//  MyChat
//
//  Created by Aditya Ambekar on 29/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static var shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
}

//MARK: - Account Management

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        //gave error for email containing special char so like '.', '#'
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    public func insertUser(with user: ChatAppuser, completion: @escaping (Bool) -> Void) {
        
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            completion(true)
        })
    }
}


struct ChatAppuser {
    
    let firstName: String
    let lastName: String
    let emailId: String
    
    var safeEmail: String {
        
        var safeEmail = emailId.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFilename: String {
        
        return "\(safeEmail)_Profile_Pic.png"
    }
    
//    let profilePic: String
}
