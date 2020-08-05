//
//  DatabaseManager.swift
//  MyChat
//
//  Created by Aditya Ambekar on 29/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    
    static var shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailId: String) -> (String) {
        
        var safeEmail = emailId.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
        
    }
    
}

extension DatabaseManager {
    
    public func getData(for path: String, completion: @escaping (Result<Any,  Error>) -> Void) {
        
        self.database.child("\(path)").observeSingleEvent(of: .value) { (snapShot) in
            
            guard let value = snapShot.value else {
                completion(.failure(DataBaseErrors.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
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
    public func createNewConversations(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard  let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentUserName = UserDefaults.standard.value(forKey: "name") as? String  else {
                return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailId: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value,with: { [weak self] snapShot in
            
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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            let recipientNewConversationData: [String: Any] = [
                
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentUserName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            //update other users convo
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] (snapShot) in
                
                if var conversations = snapShot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue([conversationId])
                }
                else {
                    //create new convo
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            }
            
            //update current users convo
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) {[weak self] (error, _) in
                    
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(name:name,
                                                     conversationId: conversationId,
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
                    self?.finishCreatingConversations(name: name,
                                                      conversationId: conversationId,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                }
            }
            
        })
        
    }
    
    private func finishCreatingConversations(name: String, conversationId: String, firstMessage:Message, completion: @escaping (Bool) -> Void) {
        
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
            "is_read": false,
            "name": name
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
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        
        database.child("\(email)/conversations").observe(.value) { (snapShot) in
            
            guard let value = snapShot.value as? [[String: Any]] else {
                completion(.failure(DataBaseErrors.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otheruserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        
                        return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                
                
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otheruserEmail,
                                    latestMessage: latestMessageObject)
            })
            
            //didnt add completion here :(
            completion(.success(conversations))
        }
        
    }
    
    //gets a message with target convo
    public func getAllMessagesForConversations(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        
        database.child("\(id)/messages").observe(.value) { (snapShot) in
            
            guard let value = snapShot.value as? [[String: Any]] else {
                completion(.failure(DataBaseErrors.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageId = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let type = dictionary["type"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    
                    guard let imageUrl = URL(string: content),
                        let placeholder = UIImage(systemName: "plus") else {
                            return nil
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else  if type == "video" {
                    
                    guard let videoUrl = URL(string: content),
                        let placeholder = UIImage(systemName: "plus") else {
                            return nil
                    }
                    //need to add thumbnail as placeholder need to see that
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                    
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoUrl: "",
                                    senderId: senderEmail,
                                    displayName: name)
        
                return Message(sender: sender ,
                               messageId: messageId,
                               sentDate: date,
                               kind: finalKind)
            })
            
            //didnt add completion here :(
            completion(.success(messages))
        }
        
    }
    
    //sends a message wit target convo
    public func sendMessage(to conversationId: String, otherUserEmail: String, name: String, message: Message, completion: @escaping (Bool) -> Void) {
        
        //add new message to messages
        //update sender latest message
        //update recipient message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailId: myEmail)
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value) {[weak self] (snapShot) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapShot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            //append new message
            
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var content = ""
            
            switch message.kind {
                
            case .text(let messageText):
                content = messageText
                break
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    content = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    content = targetUrlString
                }
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

            let newMessage: [String: Any] = [
            
                "id": message.messageId,
                "type": message.kind.messageKindString,
                "content": content,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(newMessage);
            
            strongSelf.database.child("\(conversationId)/messages").setValue(currentMessages) { (error , _) in
                
                guard error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (snapShot) in
                    
                    guard var currentUserConversation = snapShot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
//                    find conversation latest and upadte the latest message
                    let updatedValue: [String: Any] = [
                       "date": dateString,
                       "is_read": false,
                       "message": content
                    ]
                    
                    var targetConversation: [String: Any]?
                    var position = 0

                    for conversation in currentUserConversation {

                        if let currentId = conversation["id"] as? String, currentId == conversationId {
                            targetConversation = conversation
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedValue

                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversation[position] = finalConversation
                    
                    strongSelf.database.child("\(currentUserEmail)/conversations").setValue(currentUserConversation) { (error, _) in
                        
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        //update latest message in receipient convo as well
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapShot) in
                            
                            guard var otherUserConversation = snapShot.value as? [[String: Any]] else {
                                completion(false )
                                return
                            }
                            
//                            find conversation latest and upadte the latest message
                            let updatedValue: [String: Any] = [
                               "date": dateString,
                               "is_read": false,
                               "message": content
                            ]

                            var targetConversation: [String: Any]?
                            var position = 0

                            for conversation in otherUserConversation {

                                if let currentId = conversation["id"] as? String, currentId == conversationId {
                                    targetConversation = conversation
                                    break
                                }
                                position += 1
                            }

                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversation[position] = finalConversation
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversation) { (error, _) in
                                
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> (Void)) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailId: email)
        
        print("Deleting conversation!!")
        //Get conversation for current users
        //Delete conversation in collection with target id
        //reset thoseconversations in database
        let ref = database.child("\(safeEmail)/conversations")
        
        ref.observeSingleEvent(of: .value) { (snapShot) in
            
            if var conversations = snapShot.value as? [[String: Any]] {
                var positionToRemove = 0
                
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        break
                    }
                    positionToRemove += 1
                }
                
                conversations.remove(at: positionToRemove)
                
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("Failed to update the deleted conversation")
                        return
                    }
                    print("Deleted the conversations !!")
                    completion(true)
                })
            }
        }
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
