//
//  DatabaseManager.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 05.12.2023.
//

import UIKit
import FirebaseDatabase
import MessageKit
import CoreLocation

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = FirebaseDatabase.Database.database().reference()
    
    private init() {}
//    let a = FirebaseDatabase.Database.database().reference()
}

// MARK: - Accaunt manager

extension DatabaseManager {
    
    enum DatabaseManagerError: Error {
        case error
        case allUsers
        case userConversations
        case conversationMessages
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
                completion(
                    .failure(DatabaseManagerError.allUsers)
                )
                return
            }
            
            completion(
                .success(users)
            )
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
    
    private func finishConversationCreating(
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
                guard let lastMessageResult = conversation["latest_message"] as? [String: Any],
                      let text = lastMessageResult["content"] as? String,
                      let username = conversation["username"] as? String,
                      let email = conversation["other_user_email"] as? String,
                      let id = conversation["conversation_id"] as? String,
                      let isRead = lastMessageResult["is_read"] as? Bool,
                      let type = lastMessageResult["type"] as? String,
                      let senderEmail = lastMessageResult["sender_email"] as? String
                else {
                    return nil
                }
                
                
                let lastMessage = ChatItem.LastMessage(
                    message: text,
                    isRead: isRead,
                    type: type,
                    senderEmail: senderEmail
                )
                
                return ChatItem(id: id, email: email, username: username, lastMessage: lastMessage)
            }
            
            completion(
                .success(resultConversations)
            )
        }
    }
    
    /// Get all messages from conversation
    func getAllMessagesForConversation(
        conversationId: String,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        let reference = database.child("\(conversationId)/messages")
        
        reference.observe(.value) { snapshot in
            guard let messages = snapshot.value as? [[String: Any]] else {
                completion(
                    .failure(DatabaseManagerError.conversationMessages)
                )
                return
            }
            
            let messsageItems: [Message] = messages.compactMap { message in
                guard let content = message["content"] as? String,
                      let senderEmail = message["sender_email"] as? String,
                      let messageId = message["id"] as? String,
                      let dateString = message["date"] as? String,
                      let typeString = message["type"] as? String,
                      let date = ChatViewController.formatter.date(from: dateString)
                else {
                    return nil
                }
                
                let kind: MessageKind
                
                switch typeString {
                case "text":
                    kind = .text(content)
                case "photo":
                    let media = Media(
                        url: URL(string: content),
                        image: nil,
                        placeholderImage: UIImage(systemName: "plus")!,
                        size: CGSize(width: 300, height: 300)
                    )
                    kind = .photo(media)
                case "video":
                    let media = Media(
                        url: URL(string: content),
                        image: nil,
                        placeholderImage: UIImage(systemName: "message")!,
                        size: CGSize(width: 300, height: 300)
                    )
                    kind = .video(media)
                case "location":
                    let coordinates = content.components(separatedBy: ",")
                    
                    guard coordinates.count == 2,
                          let latitude = Double(coordinates[0]),
                          let longitude = Double(coordinates[1])
                    else {
                        return nil
                    }
                    
                    let locationItem = CLLocation(
                        latitude: latitude,
                        longitude: longitude
                    )
                    let location = Location(
                        location: locationItem,
                        size: CGSize(width: 150, height: 150)
                    )
                    kind = .location(location)
                default:
                    fatalError("Unknown message type")
                }
                
                let sender = Sender(senderId: senderEmail, displayName: senderEmail)
                
                return Message(
                    sender: sender,
                    messageId: messageId,
                    sentDate: date,
                    kind: kind
                )
            }
            
            completion(
                .success(messsageItems)
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
    
    func updateLatestMessageForConversation(
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

// MARK: - Read message

extension DatabaseManager {
    
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
