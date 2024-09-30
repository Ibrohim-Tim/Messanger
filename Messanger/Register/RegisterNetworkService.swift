//
//  RegisterNetworkService.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 30.11.2023.
//

import Foundation
import FirebaseAuth

final class RegisterNetworkService {
    
    enum RegistrationError: Error {
        case error(Error?)
    }
    
    func register(
        email: String,
        username: String,
        password: String,
        avatarData: Data?,
        completion: @escaping () -> Void
    ) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let result = result, let email = result.user.email, error == nil else {
                return
            }
            
            self?.handleEmail(email, username: username, avatarData: avatarData, completion: completion)
        }
    }
    
    private func uploadProfilePicture(user: User, avatarData: Data?) {
        guard let data = avatarData else {
            ProfileUserDefaults.handleAvatarUrl(nil)
            return
        }
        
        StorageManager.shared.uploadAvatarImage(data: data, filename: user.pictureFilename) { result in
            switch result {
            case .success(let url):
                ProfileUserDefaults.handleAvatarUrl(url)
            case .failure(let error):
                ProfileUserDefaults.handleAvatarUrl(nil)
                print(error)
            }
        }
    }
    
    private func handleEmail(
        _ email: String,
        username: String,
        avatarData: Data?,
        completion: () -> Void
    ) {
        let user = User(username: username, email: email)
        
        ProfileUserDefaults.handleUser(user)
        AccountDatabaseManager.shared.saveUser(user)
        
        uploadProfilePicture(user: user, avatarData: avatarData)
        
        completion()
    }
}
