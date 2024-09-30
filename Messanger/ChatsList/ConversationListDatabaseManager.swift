//
//  ConversationListDatabaseManager.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.09.2024.
//

import FirebaseDatabase

final class ConversationListDatabaseManager {
    
    enum DatabaseManagerError: Error {
        case userConversations
    }
    
    private let database = FirebaseDatabase.Database.database().reference()
    
    /// Get all conversations for user
    func getAllConversations(
        for userEmail: String,
        completion: @escaping (Result<[ChatItem], Error>) -> Void
    ) {
        database.child("\(userEmail)/conversations").observe(.value) { snapshot in
            guard let conversationsResult = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseManagerError.userConversations))
                return
            }
            
            let conversations = ConversationConverter().conversations(from: conversationsResult)
            
            completion(
                .success(conversations)
            )
        }
    }
}

// MARK: - Read message

extension ConversationListDatabaseManager {
    
    func markAllMessagesRead(
        currentUserEmail: String,
        conversationId: String,
        completion: @escaping (Bool) -> Void
    ) {
        let reference = database.child("\(conversationId)/messages")
        
        reference.observeSingleEvent(of: .value) { snapshot in
            guard var messages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            for i in 0..<messages.count {
                guard let senderEmail = messages[i]["sender_email"] as? String else { continue }
                
                if senderEmail != currentUserEmail {
                    messages[i]["is_read"] = true
                }
            }
            
            reference.setValue(messages) { [weak self] error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self?.markLatestMessageAsRead(userEmail: currentUserEmail, conversationId: conversationId)
            }
        }
    }
    
    func markLatestMessageAsRead(
        userEmail: String,
        conversationId: String
    ){
        let path = database.child("\(userEmail)/conversations")
        
        path.observeSingleEvent(of: .value) { snapshot in
            guard var conversations = snapshot.value as? [[String: Any]] else {
                return
            }
            
            let indexResult = conversations.firstIndex { conversation in
                guard let conversationResultId = conversation["conversation_id"] as? String else {
                    return false
                }
                
                return conversationResultId == conversationId
            }
            
            guard let index = indexResult else { return }
            
            let conversation = conversations[index]
            
            guard var latestMessage = conversation["latest_message"] as? [String: Any],
                  let senderEmail = latestMessage["sender_email"] as? String
            else {
                return
            }
            
            if senderEmail != userEmail {
                latestMessage["is_read"] = true
            }
            
            conversations[index]["latest_message"] = latestMessage
            
            path.setValue(conversations)
        }
    }
}

// MARK: - Removing

extension ConversationListDatabaseManager {
    
    func handleRemoveConversation(
        currentUserEmail: String,
        otherUserEmail: String,
        conversationId: String,
        completion: @escaping (Bool) -> Void
    ) {
        removeConversation(email: currentUserEmail, id: conversationId) { isSuccess in
            completion(isSuccess)
        }
        removeConversation(email: otherUserEmail, id: conversationId) { isSuccess in
            
        }
    }
    
    private func removeConversation(email: String, id: String, completion: @escaping (Bool) -> Void) {
        let reference = database.child("\(email)/conversations")
        
        reference.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var conversations = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            conversations.removeAll { conversation in
                guard let conversationId = conversation["conversation_id"] as? String else {
                    return false
                }
                
                return conversationId == id
            }
            
            reference.setValue(conversations)
            
            self?.database.child(id).removeValue()
            
            completion(true)
        }
    }
}
