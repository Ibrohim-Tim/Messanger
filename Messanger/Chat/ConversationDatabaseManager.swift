//
//  DatabaseManager.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 05.12.2023.
//

import UIKit
import FirebaseDatabase

final class ConversationDatabaseManager {
    
    enum DatabaseManagerError: Error {
        case conversationMessages
    }
    
    private let database = FirebaseDatabase.Database.database().reference()
}

//MARK: - Conversations

extension ConversationDatabaseManager {
    
    ///Create new conversation
    func createConversation(
        otherUserEmail: String,
        otherUsername: String?,
        message: Message,
        completion: @escaping (String?) -> Void
    ) {
        guard let currentUserEmail = ProfileUserDefaults.email,
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
            currentUserEmail: currentUserEmail.safe,
            otherUserEmail: otherUserEmail,
            message: message
        ) { isSuccess in
            guard isSuccess else { return }
            
            completion(conversationId)
        }
        
        updateConversationForOtherUser(
            conversationId: conversationId,
            currentUserEmail: currentUserEmail,
            username: currentUsername,
            otherUserEmail: otherUserEmail.safe,
            date: dateString,
            message: message
        ) { isSuccess in
            
        }
    }
    
    /// Get all messages from conversation
    func getAllMessagesForConversation(
        conversationId: String,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        let reference = database.child("\(conversationId)/messages")
        
        reference.observe(.value) { snapshot in
            guard let messagesResult = snapshot.value as? [[String: Any]] else {
                completion(
                    .failure(DatabaseManagerError.conversationMessages)
                )
                return
            }
            
            let messages = MessageConverter().messages(from: messagesResult)
            
            completion(
                .success(messages)
            )
        }
    }
    
    /// Send message to existing conversation
    func sendMessage(
        to conversationId: String,
        senderEmail: String,
        otherUserEmail: String,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        let path = database.child("\(conversationId)/messages")
        
        path.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, var messages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let date = ChatViewController.formatter.string(from: message.sentDate)
            
            let messageItem: [String: Any] = [
                "id": message.messageId,
                "type": message.kind.type,
                "content": message.kind.content,
                "date": date,
                "sender_email": senderEmail,
                "is_read": false
            ]
            
            messages.append(messageItem)
            
            path.setValue(messages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self.updateLatestMessageForConversation(
                    conversationId: conversationId,
                    userEmail: senderEmail,
                    newMessage: message,
                    senderEmail: senderEmail
                )
                
                self.updateLatestMessageForConversation(
                    conversationId: conversationId,
                    userEmail: otherUserEmail,
                    newMessage: message,
                    senderEmail: senderEmail
                )
            }
        }
    }
}

// MARK: - Private

extension ConversationDatabaseManager {
    
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
                "content": message.kind.content,
                "type": message.kind.type,
                "is_read": false,
                "sender_email": currentUserEmail
            ] as [String : Any]
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
                
                // абдула перемести эту часть за скобки но от этого портится логика
                
                self?.createChat(
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
                "content": message.kind.content,
                "type": message.kind.type,
                "is_read": false,
                "sender_email": currentUserEmail.safe
            ] as [String : Any]
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
                // массива нет
                user["conversations"] = [otherUserConversation]
                reference.setValue(user)
            }
            
            completion(true)
        }
    }
    
    private func createChat(
        conversationId: String,
        message: Message,
        date: String,
        currentUserEmail: String,
        otherUserEmail: String
    ) {
        let message: [String: Any] = [
            "id": message.messageId,
            "type": message.kind.type,
            "content": message.kind.content,
            "date": date,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let conversation = [
            "messages": [message]
        ]
        
        database.child(conversationId).setValue(conversation)
    }
    
    private func updateLatestMessageForConversation(
        conversationId: String,
        userEmail: String,
        newMessage: Message,
        senderEmail: String
    ) {
        let path = database.child(userEmail)
        
        path.observeSingleEvent(of: .value) { snapshot in
            guard let user = snapshot.value as? [String: Any],
                  var conversations = user["conversations"] as? [[String: Any]]
            else {
                return
            }
            
            let newMessage: [String: Any] = [
                "date": ChatViewController.formatter.string(from: newMessage.sentDate),
                "content": newMessage.kind.content,
                "type": newMessage.kind.type,
                "is_read": false,
                "sender_email": senderEmail
            ]
            
            let index = conversations.firstIndex { conversation in
                guard let id = conversation["conversation_id"] as? String else { return false }
                return id == conversationId
            }
            
            guard let conversationIndex = index else {
                return
            }
            
            conversations[conversationIndex]["latest_message"] = newMessage
            
            path.child("conversations").setValue(conversations)
        }
    }
}
