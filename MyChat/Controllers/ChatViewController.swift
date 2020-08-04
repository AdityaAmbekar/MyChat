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
import SDWebImage
import AVFoundation
import AVKit

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

struct Media: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
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
        messagesCollectionView.messageCellDelegate = self
        setupInputButton()
    }
    
    private func setupInputButton() {
        
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] (_) in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        
        let actionSheet = UIAlertController(title: "Attach media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] (_) in
            self?.presentPhotoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] (_) in
            self?.presentVideoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (_) in
            
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputAction() {
        
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Choose to attach photo from?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] (_) in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        
    }
    
    private func presentVideoInputAction() {
        
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Choose to attach video from?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] (_) in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender else {
                picker.dismiss(animated: true, completion: nil)
                return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            //upload image
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) {[weak self] (result) in
                //send message
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let urlString):
                    //ready to send message
                    print("Uploaded message photo \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {  //sending random place holder
                            return
                    }
                    
                    let mediaItem = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(mediaItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, message: message) { (success) in
                        
                        if success {
                             print("Sent photo message")
                        }
                        else {
                            print("Failed to send photo message!")
                        }
                                                        
                    }
                    
                case .failure(let error):
                    print("Failed to uplaod photo image \(error)")
                }
            }
            
        }
        else if let videoUrl = info[.mediaURL] as? URL{
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //upload video
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) {[weak self] (result) in
                //send message
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let urlString):
                    //ready to send message
                    print("Uploaded message video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {  //sending random place holder
                            return
                    }
                    
                    let mediaItem = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(mediaItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, message: message) { (success) in
                        
                        if success {
                             print("Sent photo message")
                        }
                        else {
                            print("Failed to send photo message!")
                        }
                                                        
                    }
                    
                case .failure(let error):
                    print("Failed to uplaod photo image \(error)")
                }
            }
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
            
            guard  let conversationId = conversationId,
                let name = self.title else {
                    return
            }
            DatabaseManager.shared.sendMessage( to: conversationId, otherUserEmail: otherUserEmail, name: name, message: message) { (success) in
                
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//
//    }
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            
            guard let imageUrl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.aut
            present(vc, animated: true)
        default:
            break
        }
    }
}
