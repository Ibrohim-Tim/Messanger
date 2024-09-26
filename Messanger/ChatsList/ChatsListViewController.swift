//
//  ChatsViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.11.2023.
//

import UIKit

final class ChatsListViewController: UIViewController {
    
    private var chats: [ChatItem] = []
            
    // MARK: - UI Elements
    
    private let tabelView: UITableView = {
        let tabelView = UITableView()
        tabelView.translatesAutoresizingMaskIntoConstraints = false
        tabelView.rowHeight = LayoutMetrics.module * 10
        return tabelView
    }()
    
    // MARK: - Lyfecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        title = "Чаты"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(newChatButtonTapped)
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loginDidFinish),
            name: Notifications.loginDidFinish,
            object: nil
        )
        
        setupSearchController()
        setupTabelView()
        listenConversations()
    }
    
    // MARK: - Private methods
    
    private func setupSearchController() {
        let searchController = UISearchController()
                
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupTabelView() {
        tabelView.dataSource = self
        tabelView.delegate = self
        
        tabelView.register(ChatsListTableViewCell.self, forCellReuseIdentifier: ChatsListTableViewCell.reuseId)
        
        setupTabelViewLayout()
    }
    
    private func listenConversations() {
        guard let currentUserEmail = ProfileUserDefaults.email?.safe else { return }
        
        DatabaseManager.shared.getAllConversations(for: currentUserEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                self?.chats = conversations
                self?.tabelView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func setupTabelViewLayout() {
        view.addSubview(tabelView)
        
        tabelView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tabelView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tabelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tabelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    @objc
    private func newChatButtonTapped() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] username, email in
            guard let self = self else { return }
            
            let conversation = self.chats.first { $0.email == email }
            
            self.showChatViewController(conversationId: conversation?.id, username: username, email: email)
        }
        present(vc, animated: true)
    }
    
    @objc
    private func loginDidFinish() {
        listenConversations()
    }
    
    private func showChatViewController(
        conversationId: String?,
        username: String,
        email: String
    ) {
        let viewController = ChatViewController(
            conversationId: conversationId,
            otherUserEmail: email
        )
        viewController.title = username
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func handleRemoveConversationAction(indexPath: IndexPath) {
        guard let email = ProfileUserDefaults.email?.safe else { return }
        
        let chat = chats[indexPath.row]
        let id = chat.id
        let otherUserEmail = chat.email.safe
        
        DatabaseManager.shared.handleRemoveConversation(
            currentUserEmail: email,
            otherUserEmail: otherUserEmail,
            conversationId: id
        ) { [weak self] isSuccess in
            guard let self = self, isSuccess else {
                print("Can not remove comversation")
                return
            }
            
            self.chats.remove(at: indexPath.row)
            self.tabelView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - UITableViewDataSource

extension ChatsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tabelView.dequeueReusableCell(
            withIdentifier: ChatsListTableViewCell.reuseId,
            for: indexPath
        ) as? ChatsListTableViewCell else {
            fatalError("Can not dequeue ChatsListTableViewCell")
        }
        
        let conversation = chats[indexPath.row]
        
        let message = conversation.lastMessage.type == "text" 
        ? conversation.lastMessage.message
        : conversation.lastMessage.type.firstCapitalized
        
        let isRead: Bool
        
        if conversation.lastMessage.senderEmail == ProfileUserDefaults.email?.safe {
            isRead = true
        } else {
            isRead = conversation.lastMessage.isRead
        }
        
        cell.configure(
            email: conversation.email,
            username: conversation.username,
            message: message,
            isRead: isRead
        )
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = chats[indexPath.row]
        showChatViewController(
            conversationId: item.id,
            username: item.username,
            email: item.email
        )
        
        guard let currentUserEmail = ProfileUserDefaults.email?.safe else { return }
        
        DatabaseManager.shared.markAllMessagesRead(
            currentUserEmail: currentUserEmail,
            conversationId: item.id
        ) { isSuccess in
            guard isSuccess else {
                return
            }
            
            print("All messages marked as read")
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, _ in
            self?.handleRemoveConversationAction(indexPath: indexPath)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
