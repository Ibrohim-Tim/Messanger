//
//  ChatViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 02.12.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import CoreLocation
import SDWebImage

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
    private var conversationId: String?

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
        messagesCollectionView.messageCellDelegate = self
        
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
            self?.showVideoPicker()
        }
        let geoAction = UIAlertAction(title: "Местоположение", style: .default) { [weak self] _ in
            self?.showLocationPicker(target: .send)
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
    
    private func showVideoPicker() {
        let viewController = UIImagePickerController()
        viewController.delegate = self
        viewController.sourceType = .photoLibrary
        viewController.mediaTypes = ["public.movie"]
        viewController.allowsEditing = true
        
        present(viewController, animated: true)
    }
    
    private func showLocationPicker(target: LocationPickerViewController.Target) {
        let viewController = LocationPickerViewController(target: target)
        viewController.delegate = self
        
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Messages

private extension ChatViewController {
    
    func createConversation(
        otherUserEmail: String,
        message: Message
    ) {
        DatabaseManager.shared.createConversation(
            otherUserEmail: otherUserEmail,
            otherUsername: title,
            message: message
        ) { [weak self] conversationId in
            guard let self = self else { return }
            
            guard let conversationId = conversationId else {
                print("Can not create conversation")
                return
            }
            
            self.conversationId = conversationId
            self.isNewConversation = false
            self.listenMessagesInConversation()
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

extension ChatViewController: MessagesDisplayDelegate {
    
    func configureMediaMessageImageView(
        _ imageView: UIImageView,
        for message: any MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        let photoUrlString = message.kind.content
        
        let url = URL(string: photoUrlString) // Было очищение от опционала через guard
        
        imageView.sd_setImage(with: url)
        
//        let urlReqest = URLRequest(url: url)
        
//        URLSession.shared.dataTask(with: urlReqest) { data, _, error in
//            guard let data = data, error == nil else {
//                print("Can not download message photo")
//                return
//            }
//            
//            let image = UIImage(data: data)
//            
//            DispatchQueue.main.async {
//                imageView.image = image
//            }
//        }.resume()
    }
}

//MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {}

//MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let item):
            guard let url = item.url else { return }
            
            let vc = PhotoViewController(url: url)
            
            navigationController?.pushViewController(vc, animated: true) // сделать другую анимацию открытия картинки в чате
        default:
            return
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let item):
            showLocationPicker(
                target: .show(item.location)
            )
        default:
            return
        }
    }
}

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
        
        guard let messageId = createMessageId(), let sender = sender else { return }
        
        if let image = info[.editedImage] as? UIImage {
            handleImagePickerPhotoSelected(image: image, messageId: messageId, sender: sender)
        } else if let url = info[.mediaURL] as? URL {
            handleImagePickerVideoSelected(url: url, messageId: messageId, sender: sender)
        }
    }
    
    private func handleImagePickerPhotoSelected(image: UIImage, messageId: String, sender: Sender) {
        guard let data = image.pngData() else { return }
        
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
    
    private func handleImagePickerVideoSelected(url: URL, messageId: String, sender: Sender) {
        let filename = "message_video_\(messageId).mov"
        
        StorageManager.shared.uploadMessageVideo(url: url, filename: filename) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let url):
                let media = Media(
                    url: url,
                    image: nil,
                    placeholderImage: UIImage(systemName: "message")!,
                    size: CGSize(width: 300, height: 300)
                )
                let message = Message(
                    sender: sender,
                    messageId: messageId,
                    sentDate: Date(),
                    kind: .video(media)
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

// MARK: - LocationPickerViewControllerDelegate

extension ChatViewController: LocationPickerViewControllerDelegate {
    
    func locationDidSelect(location: CLLocation) {
        guard let sender = sender, let messageId = createMessageId() else { return }
        
        let location = Location(location: location, size: .zero)
        
        let message = Message(
            sender: sender,
            messageId: messageId,
            sentDate: Date(),
            kind: .location(location)
        )
        
        if self.isNewConversation {
            self.createConversation(otherUserEmail: otherUserEmail, message: message)
        } else {
            // добавление существующего чата
            self.sendMessageToExistingConversation(message: message)
        }
    }
}
