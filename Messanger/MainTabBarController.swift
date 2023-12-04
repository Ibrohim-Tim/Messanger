//
//  MainTabBarController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.11.2023.
//

import UIKit
import FirebaseAuth

final class MainTabBarController: UITabBarController {
    
    private var chatsViewController: UINavigationController {
        let viewController = ChatsListViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "Чаты",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )
        return navigationController
    }
    
    private var profileViewController: UINavigationController {
        let viewController = ProfileViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
        return navigationController
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        viewControllers = [chatsViewController, profileViewController]
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loginDidFinish),
            name: Notifications.loginDidFinish,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if FirebaseAuth.Auth.auth().currentUser == nil {
            showLoginScreen()
        }
    }
    
    // MARK: - Private methods
    
    private func showLoginScreen() {
        let viewController = LoginViewController()
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
    
    @objc
    private func loginDidFinish() {
        selectedIndex = 0
    }
}
