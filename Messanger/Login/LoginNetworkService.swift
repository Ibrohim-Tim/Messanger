//
//  LoginNetworkService.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 30.11.2023.
//

import Foundation
import FirebaseAuth

final class LoginNetworkService {
    
    enum LoginError: Error {
        case error(String)
    }
    
    func login(
        email: String,
        password: String,
        completion: @escaping () -> Void
    ) {
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let result = result, let email = result.user.email, error == nil else {
                return
            }
            
            self?.handleEmail(email, completion: completion)
        }
    }
    
    private func handleEmail(_ email: String, completion: @escaping () -> Void) {
        AccountDatabaseManager.shared.getUser(email: email) { [weak self] result in
            switch result {
            case .success(let user):
                self?.handleUser(user, completion: completion)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func handleUser(_ user: User, completion: @escaping () -> Void) {
        ProfileUserDefaults.handleUser(user)
        
        StorageManager.shared.url(for: user.pictureFilename) { result in
            switch result {
            case .success(let url):
                ProfileUserDefaults.handleAvatarUrl(url)
            case .failure(let error):
                ProfileUserDefaults.handleAvatarUrl(nil)
                print(error)
            }
        }
        
        completion()
    }
}
