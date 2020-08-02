//
//  ChatViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 30/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoUrl: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender?  {
        
        guard  let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailId: email)
        
        return Sender(photoUrl: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    init(email:String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        
        DatabaseManager.shared.getAllMessagesForConversations(with: id) {[weak self] (result) in
            
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                //need to update the messages
                self?.messages = messages
                
                DispatchQueue.main.async {
                    //if new message comes we dont want to scroll all the way up so this
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
                
                
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
        
    }

}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageId = createMessageId()else {
            return
        }
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        //Send message
        if isNewConversation {
            //create convo in database
            DatabaseManager.shared.createNewConversations(with: otherUserEmail,
                                                          name: self.title ?? "User",
                                                          firstMessage: message) {[weak self] (success) in
                
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }
                else {
                    print("failed to send message")
                }
            }
        }
        else {
            //append convo in database
            
            guard  let conversationId = conversationId else {
                return
            }
            DatabaseManager.shared.sendMessage( to: conversationId, message: message) { (success) in
                
                if success {
                    print("message sent")
                }
                else {
                   print("Failed to sent message")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        //data, otheruseremail, ownemail, randomint
        let dateString = Self.dateFormatter.string(from: Date())
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailId: myEmail)
        
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        print(newIdentifier)
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        
        if let sender = selfSender {
            return sender
        }
        fatalError("Slef Senderis nil email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    
}
