//
//  AccountDatabaseManager.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 26.09.2024.
//

import FirebaseDatabase

final class AccountDatabaseManager {
    
    static let shared = AccountDatabaseManager()
    
    private let database = FirebaseDatabase.Database.database().reference()
    
    private init() {}
}

// MARK: - Accaunt manager

extension AccountDatabaseManager {
    
    enum AccountDatabaseManagerError: Error {
        case user
        case allUsers
    }
    
    func saveUser(_ user: User) {

        let userData = [
            "username": user.username
        ]
        
        database.child(user.email.safe).setValue(userData) { [weak self] error, reference in
            guard error == nil else {
                return
            }
            
            self?.database.child("users").observeSingleEvent(of: .value) { snapshot in
                let user = [
                    "email": user.email,
                    "username": user.username
                ]
                
                if var users = snapshot.value as? [[String: String]] {
                    // добавляется в имеющийся массив
                    users.append(user)
                    self?.database.child("users").setValue(users)
                } else {
                    // создается массив
                    self?.database.child("users").setValue([user])
                }
            }
        }
    }
    
    func getUser(email: String, completion: @escaping (Result<User, Error>) -> Void) {
        
        database.child(email.safe).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let username = data["username"] as? String
            else {
                completion(
                    .failure(AccountDatabaseManagerError.user)
                )
                return
            }
            
            let user = User(username: username, email: email)
            
            completion(
                .success(user)
            )
        }
    }
    
    func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let users = snapshot.value as? [[String: String]] else {
                completion(
                    .failure(AccountDatabaseManagerError.allUsers)
                )
                return
            }
            
            completion(
                .success(users)
            )
        }
    }
}
