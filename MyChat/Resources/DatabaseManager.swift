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
    
    static func safeEmail(emailId: String) -> (String) {
        
        var safeEmail = emailId.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
        
    }
    
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
            
            //doing this thing just to lessen the database calls
            //something like graphql implementation
            /*
                users => [
                    [
                        name:
                        email:
                    ],
                    [
                        ...
                    ]
                ]
             */
            
            self.database.child("users").observeSingleEvent(of: .value) { (snapShot) in
                
                if var usersCollection = snapShot.value as? [[String: String]] {
                    //append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                        guard  error == nil  else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    //create that array
                    let newCollection: [[String: String]] = [
                        
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: {error, _ in
                        guard  error == nil  else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            }
        })
    }
    
    public func getAllUser(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        
        database.child("users").observeSingleEvent(of: .value, with: { snapShot in
            
            guard let value = snapShot.value as? [[String: String]] else {
                completion(.failure(DataBaseErrors.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
    
    public enum DataBaseErrors: Error {
        
        case failedToFetch
    }
}

//MARK: - Sending messages/ convo


    /*
    
    "conversation_id" => {
 
        "messages" : [
            "id" :String
            "type":
            "contents":
            "date":
            "sender_email"
            "isRead":
        ]
    }
 
    conversation => [
 
        "conversation_id":
        "other_user_email":
        "latest_message": =>{
            "date": Date()
            "latest_message": "message"
            "isRead": Bool
        }
 
    ]
 
 */

extension DatabaseManager {
    
    //creates new conversation
    public func createNewConversations(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard  let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailId: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value,with: {snapShot in
            
            guard var userNode = snapShot.value as? [String: Any] else{
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
        
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) {[weak self] (error, _) in
                    
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(conversationId: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
                
            }
            else {
                //convo array doesnt exits
                //create
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) {[weak self]  (error, _) in
                    
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(conversationId: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            }
            
        })
        
    }
    
    private func finishCreatingConversations(conversationId: String, firstMessage:Message, completion: @escaping (Bool) -> Void) {
        
//
//        "id" :String
//        "type":
//        "contents":
//        "date":
//        "sender_email"
//        "isRead":
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var content = ""
        
        switch firstMessage.kind {
            
        case .text(let messageText):
            content = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailId: myEmail)

        let message: [String: Any] = [
        
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": content,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                message
            ]
        ]
        
        database.child("\(conversationId)").setValue(value) { (error, _) in
            
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    //fetches the all conversations
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        
    }
    
    //gets a message with target convo
    public func getAllMessagesForConversations(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    //sends a message wit target convo
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
        
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
