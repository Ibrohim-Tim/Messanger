//
//  StorageManager.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 05.12.2023.
//

import Foundation
import FirebaseStorage

struct StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = FirebaseStorage.Storage.storage().reference()
    
    private init() {}
}

// MARK: - Profile picture

extension StorageManager {
    
    enum StorageManagerError: Error {
        case uploadPicture
        case downloadUrl
        case uploadVideo
    }
    
    func uploadAvatarImage(data: Data, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child("images/\(filename)")
        
        reference.putData(data) { data, error in
            guard let _ = data, error == nil else {
                completion(
                    .failure(StorageManagerError.uploadPicture)
                )
                return
            }
            reference.downloadURL { url, error in
                guard let url = url, error == nil else {
                    completion(
                        .failure(StorageManagerError.downloadUrl)
                    )
                    return
                }
                
                completion(
                    .success(url)
                )
            }
        }
    }
    
    func uploadMessageImage(data: Data, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child("message_images/\(filename)")
        reference.putData(data) { data, error in
            guard let _ = data, error == nil else {
                completion(
                    .failure(StorageManagerError.uploadPicture)
                )
                return
            }
            
            reference.downloadURL { url, error in
                guard let url = url, error == nil else {
                    completion(
                        .failure(StorageManagerError.downloadUrl)
                    )
                    return
                }
                
                completion(
                    .success(url)
                )
            }
        }
    }
    
    func uploadMessageVideo(url: URL, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child("message_videos/\(filename)")
        
        reference.putFile(from: url) { data, error in
            guard let _ = data, error == nil else {
                completion(
                    .failure(StorageManagerError.uploadVideo)
                )
                return
            }
            
            reference.downloadURL { url, error in
                guard let url = url, error == nil else {
                    completion(
                        .failure(StorageManagerError.downloadUrl)
                    )
                    return
                }
                
                completion(
                    .success(url)
                )
            }
        }
    }
    
    func url(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        storage.child("images/" + path).downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(
                    .failure(StorageManagerError.downloadUrl)
                )
                return
            }
            
            completion(
                .success(url)
            )
        }
    }
}
