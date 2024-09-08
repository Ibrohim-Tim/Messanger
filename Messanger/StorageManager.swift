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
        case uploadPictureError
        case downloadUrlError
    }
    
    func uploadAvatarImage(data: Data, filename: String, completion: @escaping (Result<String, Error>) -> Void) {
        storage.child("images/\(filename)").putData(data) { data, error in
            guard let _ = data, error == nil else {
                completion(
                    .failure(StorageManagerError.uploadPictureError)
                )
                return
            }
        }
    }
    
    func uploadMessageImage(data: Data, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child("message_images/\(filename)")
        reference.putData(data) { data, error in
            guard let _ = data, error == nil else {
                completion(
                    .failure(StorageManagerError.uploadPictureError)
                )
                return
            }
            
            reference.downloadURL { url, error in
                guard let url = url, error == nil else {
                    completion(
                        .failure(StorageManagerError.downloadUrlError)
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
                    .failure(StorageManagerError.downloadUrlError)
                )
                return
            }
            
            completion(
                .success(url)
            )
        }
    }
}
