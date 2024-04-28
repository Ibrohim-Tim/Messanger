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
        guard let email = ProfileUserDefaults.email,
              let username = ProfileUserDefaults.username
        else {
            return nil
        }
        
        return Sender(senderId: email.safe, displayName: username)
    }
    
    private let otherUserEmail: String
    private var isNewConversation: Bool
    private let conversationId: String?

    //MARK: - Init
    
    init(conversationId: String?, otherUserEmail: String) {
        self.otherUserEmail = otherUserEmail
        self.isNewConversation = conversationId == nil
        self.conversationId = conversationId
        
        super.init(nibName: nil, bundle: nil)
        
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        
        messageInputBar.delegate = self
        
        view.backgroundColor = .white
        
        listenMessagesInConversation()
    }
    
    private func listenMessagesInConversation() {
        guard let conversationId = conversationId else { return }
        
        DatabaseManager.shared.getAllMessagesForConversation(conversationId: conversationId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messages):
                self.messages = messages
                self.messagesCollectionView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
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
    
    func sendMessageToExistingConversation(message: Message) {
        guard let conversationId = conversationId,
              let currentUserEmail = ProfileUserDefaults.email?.safe
        else {
            return
        }
        
        DatabaseManager.shared.sendMessage(
            to: conversationId,
            senderEmail: currentUserEmail,
            otherUserEmail: otherUserEmail.safe,
            message: message 
        ) { success in
            
        }
    }
    
    func createMessageId() -> String? {
        guard let currentUserEmail = ProfileUserDefaults.email?.safe else { return nil }
        
        let date = Date()
        let dateString = Self.formatter.string(from: date)
        
        let id = "\(currentUserEmail)_\(otherUserEmail.safe)_\(dateString)"
        
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
        messages[indexPath.section]
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
            sendMessageToExistingConversation(message: message)
        }
        
        inputBar.inputTextView.text = nil
    }
}

//MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {}

//MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {}
