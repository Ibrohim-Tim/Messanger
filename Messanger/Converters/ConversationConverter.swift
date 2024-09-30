//
//  ConversationConverter.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 26.09.2024.
//

struct ConversationConverter {
    
    func conversations(from conversations: [[String: Any]]) -> [ChatItem]{
        conversations.compactMap { conversation in
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
    }
}
