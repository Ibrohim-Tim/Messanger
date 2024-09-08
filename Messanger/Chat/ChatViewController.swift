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
        setupInputButton()
    }
    
    // MARK: - Private methods
    
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
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(
            CGSize(width: LayoutMetrics.halfModule * 9, height: LayoutMetrics.halfModule * 9),
            animated: false
        )
        button.setImage(
            UIImage(systemName: "plus"),
            for: .normal
        )
        button.tintColor = .black
        button.onTouchUpInside { [weak self] _ in
            self?.handleInputButtonTapped()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: LayoutMetrics.halfModule * 9, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
}

//MARK: - ImagePicker

extension ChatViewController {
    
    private func handleInputButtonTapped() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let cameraAction = UIAlertAction(title: "Камера", style: .default) { [weak self] _ in
            self?.showCameraPicker()
        }
        let photoAction = UIAlertAction(title: "Фото", style: .default) { [weak self] _ in
            self?.showGalleryPicker()
        }
        let videoAction = UIAlertAction(title: "Видео", style: .default) { [weak self] _ in
        }
        let geoAction = UIAlertAction(title: "Местоположение", style: .default) { [weak self] _ in
        }
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel) { [weak self] _ in
        }
        
        alertController.addAction(cameraAction)
        alertController.addAction(photoAction)
        alertController.addAction(videoAction)
        alertController.addAction(geoAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func showCameraPicker() {
        let viewController = UIImagePickerController()
        viewController.delegate = self
        viewController.sourceType = .camera
        viewController.allowsEditing = true
        
        present(viewController, animated: true)
    }
    
    private func showGalleryPicker() {
        let viewController = UIImagePickerController()
        viewController.delegate = self
        viewController.sourceType = .photoLibrary
        viewController.allowsEditing = true
        
        present(viewController, animated: true)
    }
}

// MARK: - Messages

private extension ChatViewController {
    
    func createConversation(otherUserEmail: String, message: Message) {
        DatabaseManager.shared.createConversation(
            otherUserEmail: otherUserEmail,
            otherUsername: title,
            message: message
        ) { [weak self] isSucess in
            guard isSucess else {
                print("Can not send message")
                return
            }
            
            self?.isNewConversation = false
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
        ) { isSucess in
            guard isSucess else {
                print("Can not send message")
                return
            }
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
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessageKit.MessagesCollectionView
    ) -> MessageKit.MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
    
    func configureMediaMessageImageView(
        _ imageView: UIImageView,
        for message: any MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        imageView.image = UIImage(systemName: "plus")
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

//MARK: - UINavigationControllerDelegate

extension ChatViewController: UINavigationControllerDelegate {}

//MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage,
              let data = image.pngData(),
              let messageId = createMessageId(),
              let sender = sender
        else {
            return
        }
        
        let filename = "message_image_\(messageId).png"
        
        StorageManager.shared.uploadMessageImage(data: data, filename: filename) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let url):
                let media = Media(
                    url: url,
                    image: nil,
                    placeholderImage: UIImage(systemName: "plus")!,
                    size: CGSize(width: 300, height: 300)
                )
                let message = Message(
                    sender: sender,
                    messageId: messageId,
                    sentDate: Date(),
                    kind: .photo(media)
                )
                
                if self.isNewConversation {
                    self.createConversation(otherUserEmail: otherUserEmail, message: message)
                } else {
                    // добавление существующего чата
                    self.sendMessageToExistingConversation(message: message)
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
}
