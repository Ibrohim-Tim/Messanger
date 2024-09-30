//
//  LoginViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.11.2023.
//

import UIKit

final class LoginViewController: UIViewController {
    
    private let mainView = LoginView()
    private let networkService = LoginNetworkService()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        mainView.passwordTextField.isSecureTextEntry = true
        mainView.emailTextField.autocapitalizationType = .none
        
        setupActions()
    }
    
    // MARK: - Private methods
    
    private func setupActions() {
        mainView.loginButon.addTarget(self, action: #selector(loginButtonTapped), for: .touchDown)
        mainView.registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchDown)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loginDidFinish),
            name: Notifications.loginDidFinish,
            object: nil
        )
    }
    
    @objc
    private func loginButtonTapped() {
        handleLoginButton()
    }
    
    @objc
    private func registerButtonTapped() {
        let viewController = RegisterViewController()
        viewController.modalPresentationStyle = .fullScreen
        
        present(viewController, animated: true)
    }
    
    @objc
    private func loginDidFinish() {
        dismiss(animated: true)
    }
}

extension LoginViewController {
    
    private func handleLoginButton() {
        guard let email = mainView.emailTextField.text,
              let password = mainView.passwordTextField.text
        else {
            return // можно добавить алерт
        }
        
        // Можно сделать проверки после получения данных
        
        networkService.login(email: email, password: password) { [weak self] in
            NotificationCenter.default.post(name: Notifications.loginDidFinish, object: nil)
            
            self?.dismiss(animated: true)
        }
    }
}
