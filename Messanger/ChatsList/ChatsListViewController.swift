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
        
        setupSearchController()
        setupTabelView()
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
    
    private func setupTabelViewLayout() {
        view.addSubview(tabelView)
        
        tabelView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tabelView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tabelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tabelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
}

// MARK: - UITableViewDataSource

extension ChatsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
//        chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tabelView.dequeueReusableCell(withIdentifier: ChatsListTableViewCell.reuseId, for: indexPath) as? ChatsListTableViewCell else {
            fatalError("Can not dequeue ChatsListTableViewCell")
        }
        
        cell.configure()
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = ChatViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}
