//
//  StorageManager.swift
//  MyChat
//
//  Created by Aditya Ambekar on 30/07/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /// Takes in bytes and uploads pic to firebase and return urlstring to download
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] (metaData, error) in
            
            
            guard error == nil else {
            
                print("Failed to upload profile pic to firebase storage!")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("images/\(fileName)").downloadURL { (url, error) in
                
                guard let url = url, error == nil else {
                    print("Failed to download profile url from firebase")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("\(url)")
                completion(.success(urlString))
            }
            
        })
    }
    
    /// DownloadUrl based on path to fill the profile image in view
    public func downloadURLForPath(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let reference = storage.child(path)
        
        reference.downloadURL { (url, error) in
            
            guard let url = url, error == nil else{
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                print("Failed to download image for profile view")
                return
            }
            completion(.success(url))
        }
    }
    
    /// Upload image that will be sent in conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        storage.child("messsage_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] (metaData, error) in
            
            guard error == nil else {
            
                print("Failed to upload profile pic to firebase storage!")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("messsage_images/\(fileName)").downloadURL { (url, error) in
                
                guard let url = url, error == nil else {
                    print("Failed to download profile url from firebase")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("\(url)")
                completion(.success(urlString))
            }
            
        })
    }
    
    /// Upload video that will be sent in conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        storage.child("messsage_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: {[weak self] (metaData, error) in
            
            guard error == nil else {
            
                print("Failed to upload video file to firebase storage!")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("messsage_videos/\(fileName)").downloadURL { (url, error) in
                
                guard let url = url, error == nil else {
                    print("Failed to download profile url from firebase")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("\(url)")
                completion(.success(urlString))
            }
            
        })
    }
    
    /// Defining custom errors
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToDownloadURL
        case failedToGetDownloadURL
    }
}
