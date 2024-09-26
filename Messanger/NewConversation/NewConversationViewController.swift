//
//  NewConversationViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 12.12.2023.
//

import UIKit

class NewConversationViewController: UIViewController {
    
    var completion: ((String, String) -> Void)?
    
    private var fetchedUsers: [ChatUser] = []
    private var items: [ChatUser] = []
    
    // MARK: - UI Elements
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search"
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tabelView = UITableView()
        tabelView.translatesAutoresizingMaskIntoConstraints = false
        tabelView.separatorStyle = .none
        tabelView.rowHeight = LayoutMetrics.module * 10
        return tabelView
    }()
    
    // MARK: - Lyfecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        searchBar.delegate = self
        
        setupTabelView()
    }
    
    // MARK: - Private methods
    
    private func setupTabelView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(NewConversationTableViewCell.self, forCellReuseIdentifier: NewConversationTableViewCell.reuseId)
        
        setupSearchBarLayout()
        setupTabelViewLayout()
    }
    
    
    private func setupSearchBarLayout() {
        view.addSubview(searchBar)
        
        searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutMetrics.doubleModule).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutMetrics.doubleModule).isActive = true
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    private func setupTabelViewLayout() {
        view.addSubview(tableView)
        
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    private func fetchData(completion: @escaping ([ChatUser]) -> Void) {
        DatabaseManager.shared.getAllUsers { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let users):
                self.fetchedUsers = self.convert(from: users)
                completion(self.fetchedUsers)
//                self.items = convert(from: users)
//                self.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func convert(from items: [[String: String]]) -> [ChatUser] {
        var result: [ChatUser] = []
        
        for item in items {
            guard let email = item["email"],
                  let username = item["username"]
            else {
                continue
            }
            
            result.append(
                ChatUser(
                    email: email,
                    username: username
                )
            )
        }
        
        return result
    }
}

// MARK: - UITableViewDataSource

extension NewConversationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
//        chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.reuseId, for: indexPath) as? NewConversationTableViewCell else {
            fatalError("Can not dequeue NewConversationTableViewCell")
        }
        
        let user = items[indexPath.row]
        
        cell.configure(user: user)
        cell.selectionStyle = .none
        
        return cell
    }
}

//MARK: - UITableViewDelegate

extension NewConversationViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        dismiss(animated: true) { [weak self] in
            self?.completion?(item.username, item.email)
        }
    }
}

//MARK: - UISearchBarDelegate

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        
        if !fetchedUsers.isEmpty {
            displayUsers(users: fetchedUsers, searchText: searchText)
        } else {
            fetchData() { [weak self] users in
                self?.displayUsers(users: users, searchText: searchText)
            }
        }
    }
    
    private func displayUsers(users: [ChatUser], searchText: String) {
        items = users.filter { user in
            guard let currentUserEmail = ProfileUserDefaults.email, 
                    currentUserEmail != user.email
            else {
                return false
            }
            return user.username.lowercased().hasPrefix(searchText.lowercased())
        }
       
        tableView.reloadData()
    }
}
