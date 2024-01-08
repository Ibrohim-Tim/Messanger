//
//  ChatViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 02.12.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView

final class ChatViewController: MessagesViewController {
    
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = Locale(identifier: "en_EN")
        return formatter
    }()
    
    private var messages: [Message] = []
    
    private var sender: Sender? {
        guard let username = ProfileUserDefaults.username else { return nil }
        
        return Sender(senderId: "", displayName: username)
    }
    
    private let otherUserEmail: String
    private var isNewConversation: Bool

    //MARK: - Init
    
    init(otherUserEmail: String, isNewConversation: Bool) {
        self.otherUserEmail = otherUserEmail
        self.isNewConversation = isNewConversation
        
        super.init(nibName: nil, bundle: nil)
        
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.dataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        
        messageInputBar.delegate = self
        
        view.backgroundColor = .white
    }
}

// MARK: - Messages

private extension ChatViewController {
    
    func createConversation(otherUserEmail: String, message: Message) {
        DatabaseManager.shared.createConversation(
            otherUserEmail: otherUserEmail,
            otherUsername: title,
            message: message
        ) { [weak self] sucess in
            if sucess {
                print("create")
                self?.isNewConversation = false
            } else {
                print("non create")
            }
        }
    }
    
    func sendMessage(to conversationId: String) {}
    
    func createMessageId() -> String? {
        guard let currentUserEmail = ProfileUserDefaults.email?.safe else { return nil }
        
        let date = Date()
        let dateString = Self.formatter.string(from: date)
        
        let id = "\(currentUserEmail)_\(otherUserEmail)_\(date)"
        
        return id
    }
}

extension ChatViewController: MessagesDataSource {
    var currentSender: MessageKit.SenderType {
        guard let sender = sender else {
            fatalError("Current user is nil")
        }
        
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        messages[indexPath.item]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
}

//MARK: - InputBarAccessoryViewDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard let messageId = createMessageId(),
              let sender = sender
        else {
            return
        }
        
        let message = Message(
            sender: sender,
            messageId: messageId,
            sentDate: Date(),
            kind: .text(text)
        )
        
        if isNewConversation {
           createConversation(otherUserEmail: otherUserEmail, message: message)
        } else {
            // добавление существующего чата
            sendMessage(to: "")
        }
    }
}

//MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {}

//MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {}
