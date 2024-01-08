//
//  Message.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.12.2023.
//

import Foundation
import MessageKit

struct Message: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
}
