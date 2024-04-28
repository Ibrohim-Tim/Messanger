//
//  ChatItem.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 03.12.2023.
//

import UIKit

struct ChatItem {
    
    struct LastMessage {
        let message: String
        let isRead: Bool
    }
    
    let id: String
    let email: String
    let username: String
    let lastMessage: LastMessage
}
