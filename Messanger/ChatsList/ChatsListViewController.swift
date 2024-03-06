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
            self?.showChatViewController(conversationId: nil, username: username, email: email)
        }
        present(vc, animated: true)
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
        
        cell.configure(
            email: conversation.email,
            username: conversation.username,
            message: conversation.lastMessage
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
    }
}
