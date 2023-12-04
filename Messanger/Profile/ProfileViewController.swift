//
//  ProfileViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.11.2023.
//

import UIKit
import FirebaseAuth

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = LayoutMetrics.module * 10
        imageView.image = UIImage(named: "person_placeholder")
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        return imageView
    }()
    
    private let emailLabel = BaseComponentsFactory.makeGreetingLabel(text: nil)
    private let logoutButton = BaseComponentsFactory.makeActionButton(title: "Log out", color: .systemRed)

    // MARK: - Lyfecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        title = "Профиль"
        
        setupLayout()
        
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchDown)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        emailLabel.text = FirebaseAuth.Auth.auth().currentUser?.email
    }
    
    // MARK: - Private methods
    
    @objc
    private func logoutButtonTapped() {
        let alertController = UIAlertController(
            title: "Выйти из аккаунта",
            message: "Вы уверены?",
            preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
            self?.handleLogout()
        }
        
        let cancelAction = UIAlertAction(title: "Нет", style: .default)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func handleLogout() {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            showLoginScreen()
        } catch {
            print("Logout error")
        }
    }
    
    private func showLoginScreen() {
        let viewController = LoginViewController()
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
}

// MARK: - Layout

extension ProfileViewController {
    
    private func  setupLayout() {
        setupProfileImageLayout()
        setupEmailLabelLayout()
        setupLogoutButtonLayout()
    }
    
    private func setupProfileImageLayout() {
        view.addSubview(profileImageView)
        
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: LayoutMetrics.module * 3).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: LayoutMetrics.module * 20).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: LayoutMetrics.module * 20).isActive = true
    }
    
    private func setupEmailLabelLayout() {
        view.addSubview(emailLabel)
        
        emailLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        emailLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: LayoutMetrics.module).isActive = true
    }
    
    private func setupLogoutButtonLayout() {
        view.addSubview(logoutButton)
        
        logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -LayoutMetrics.doubleModule).isActive = true
        logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutMetrics.doubleModule).isActive = true
        logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutMetrics.doubleModule).isActive = true
    }
}
