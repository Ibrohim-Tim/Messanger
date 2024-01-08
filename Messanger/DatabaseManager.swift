//
//  DatabaseManager.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 05.12.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = FirebaseDatabase.Database.database().reference()
    
    private init() {}
}

// MARK: - Accaunt manager

extension DatabaseManager {
    
    enum DatabaseManagerError: Error {
        case error
        case allUsers
        case userConversations
    }
    
    func saveUser(_ user: User) {

        let userData = [
            "username": user.username.safe
        ]
        
        database.child(user.email.safe).setValue(userData) { [weak self] error, reference in
            guard error == nil else {
                return
            }
            
            self?.database.child("users").observeSingleEvent(of: .value) { snapshot in
                let user = [
                    "email": user.email.safe,
                    "username": user.username.safe
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
            guard let data = snapshot.value as? [String: String],
                  let username = data["username"]
            else {
                completion(
                    .failure(DatabaseManagerError.error)
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
                completion(.failure(DatabaseManagerError.allUsers))
                return
            }
            
            completion(.success(users))
        }
    }
}

//MARK: - Conversations

extension DatabaseManager {
    
    ///Create new conversation
    func createConversation(
        otherUserEmail: String,
        otherUsername: String?,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUserEmail = ProfileUserDefaults.email?.safe,
              let currentUsername = ProfileUserDefaults.username,
              let otherUsername = otherUsername
        else {
            return
        }
        
        let conversationId = "conversation_\(message.messageId)"
        let dateString = ChatViewController.formatter.string(from: Date())
        
        updateConversationForCurrentUser(
            conversationId: conversationId,
            date: dateString,
            username: otherUsername,
            currentUserEmail: currentUserEmail,
            otherUserEmail: otherUserEmail,
            message: message) { isSuccess in }
        
        updateConversationForOtherUser(
            conversationId: conversationId,
            currentUserEmail: dateString,
            username: currentUsername,
            otherUserEmail: currentUserEmail,
            date: otherUserEmail,
            message: message) { isSuccess in }
       
    }
    
    private func updateConversationForCurrentUser(
        conversationId: String,
        date: String,
        username: String,
        currentUserEmail: String,
        otherUserEmail: String,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        
        let conversation: [String: Any] = [
            "conversation_id": conversationId,
            "other_user_email": otherUserEmail,
            "username": username,
            "latest_message": [
                "date": date,
                "message": message.kind.messageText,
                "is_read": false
            ] // as [String : Any] //просит добавить это но у абдуллы такого нет если что удалить
        ]
        
        let reference = database.child(currentUserEmail)
        
        reference.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var user = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
                
            if var conversations = user["conversations"] as? [[String: Any]] {
                // массив есть
                conversations.append(conversation)
                user["conversations"] = conversations
                reference.setValue(user)
            } else {
                // масства нет
                let conversations = [conversation]
                user["conversations"] = conversations
                reference.setValue(user)
                
                self?.finishConversationCreating(
                    conversationId: conversationId,
                    message: message,
                    date: date,
                    currentUserEmail: currentUserEmail,
                    otherUserEmail: otherUserEmail
                )
            }
            
            completion(true)
        }
    }
    
    private func updateConversationForOtherUser(
        conversationId: String,
        currentUserEmail: String,
        username: String,
        otherUserEmail: String,
        date: String,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        
        let otherUserConversation: [String: Any] = [
            "conversation_id": conversationId,
            "other_user_email": currentUserEmail,
            "username": username,
            "latest_message": [
                "date": date,
                "message": message.kind.messageText,
                "is_read": false
            ] // as [String : Any] //просит добавить это но у абдуллы такого нет если что удалить
        ]
        
        let reference = database.child(otherUserEmail)
        
        reference.observeSingleEvent(of: .value) { snapshot in
            guard var user = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            
            if var conversations = user["conversations"] as? [[String: Any]] {
                // массив есть
                conversations.append(otherUserConversation)
                user["conversations"] = conversations
                reference.setValue(user)
            } else {
                // масства нет
                user["conversations"] = [otherUserConversation]
                reference.setValue(user)
            }
            
            completion(true)
        }
    }
    
    private func finishConversationCreating(
        conversationId: String,
        message: Message,
        date: String,
        currentUserEmail: String,
        otherUserEmail: String
    ) {
        let message: [String: Any] = [
            "id": message.messageId,
            "type": "text",
            "message": message.kind.messageText,
            "date": date,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let conversation = [
            "messages": message
        ]
        
        let reference = database.child(conversationId)
        
        reference.observeSingleEvent(of: .value) { snapshot in
            if var conversation = snapshot.value as? [String: Any] {
                
            } else {
                reference.setValue(conversation)
            }
        }
    }
    
    /// Get all conversations for user
    func getAllConversations(
        for userEmail: String,
        completion: @escaping (Result<[ChatItem], Error>) -> Void
    ) {
        database.child("\(userEmail)/conversations").observe(.value) { snapshot in
            guard let conversations = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseManagerError.userConversations))
                return
            }
            
            let resultConversations: [ChatItem] = conversations.compactMap { conversation in
                guard let lastMessage = conversation["latest_message"] as? [String: Any],
                      let text = lastMessage["message"] as? String,
                      let email = conversation["other_user_email"] as? String
                else {
                    return nil
                }
                
                return ChatItem(image: nil, username: email, lastMessage: text)
            }
            
            completion(
                .success(resultConversations)
            )
        }
    }
}

