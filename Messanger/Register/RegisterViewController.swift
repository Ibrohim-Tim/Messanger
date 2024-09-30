//
//  RegisterViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.11.2023.
//

import UIKit

final class RegisterViewController: UIViewController {
    
    private let mainView = RegisterView()
    private let networkService = RegisterNetworkService()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        mainView.userNameTextField.delegate = self
        mainView.emailTextField.delegate = self
        mainView.passwordTextField.delegate = self
        mainView.confirmPasswordTextField.delegate = self

        setupActions()
    }
    
    // MARK: - Private methods
    
    private func setupActions() {
        mainView.loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchDown)
        
        mainView.profileImageView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(profileImageViewTapped)
            )
        )
        
        mainView.registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchDown)
    }
    
    @objc
    private func loginButtonTapped() {
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Ok", style: .default)
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}

//MARK: - Data

extension RegisterViewController {
    
    @objc
    private func registerButtonTapped() {
        guard let email = mainView.emailTextField.text,
              let username = mainView.userNameTextField.text,
              let password = mainView.passwordTextField.text,
              let confirmation = mainView.confirmPasswordTextField.text
        else {
            return
        }
        
        let isUsernameValid = checkUsername(username)
        let isEmailValid = checkEmail(email)
        let isPasswordValid = checkPassword(password, confirmation: confirmation)
        
        guard isUsernameValid, isEmailValid, isPasswordValid else { return }
        
        // запуск спинера
        
        networkService.register(
            email: email,
            username: username,
            password: password,
            avatarData: mainView.profileImageView.image?.pngData()
        ) { [weak self] in
            self?.dismiss(animated: true) {
                NotificationCenter.default.post(name: Notifications.loginDidFinish, object: nil)
            }
            
        }
    }
    
    private func checkEmail(_ email: String) -> Bool {
        guard email.count >= 6,
              email.firstIndex(of: "@") != nil,
              email.firstIndex(of: ".") != nil
        else {
            showAlert(title: "Ошибка", message: "Неверный email")
            return false
        }
        
        return true
    }
    
    private func checkPassword(_ password: String, confirmation: String) -> Bool {
        if password.count < 8 {
            showAlert(title: "Ошибка", message: "Доина пароля меньше 8 символов")
            return false
        }
        if password != confirmation {
            showAlert(title: "Ошибка", message: "Пароли не совпадают")
            return false
        }
        
        return true
    }
    
    private func checkUsername(_ username: String) -> Bool {
        guard username.count >= 3 else {
            showAlert(title: "Ошибка", message: "Имя должно быть больше 3 символов")
            return false
        }
        
        return true
    }
}

//MARK: - ImagePicker

extension RegisterViewController {
    
    @objc
    private func profileImageViewTapped() {
        let alertController = UIAlertController(
            title: "Выберите способ",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let cameraAction = UIAlertAction(title: "При помощи камеры", style: .default) { [weak self] _ in
            self?.showCameraPicker()
        }
        let libraryAction = UIAlertAction(title: "Из галлереи", style: .default) { [weak self] _ in
            self?.showGalleryPicker()
        }
        
        alertController.addAction(cameraAction)
        alertController.addAction(libraryAction)
        
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

//MARK: - UIImagePickerControllerDelegate

extension RegisterViewController: UIImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        guard let image = info[.editedImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        
        mainView.profilePicture = image
        
        picker.dismiss(animated: true)
    }
}

//MARK: - UITextFieldDelegate

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === mainView.userNameTextField {
            mainView.emailTextField.becomeFirstResponder()
        } else if textField === mainView.emailTextField {
            mainView.passwordTextField.becomeFirstResponder()
        } else if textField === mainView.passwordTextField {
            mainView.confirmPasswordTextField.becomeFirstResponder()
        } else {
            mainView.confirmPasswordTextField.resignFirstResponder()
            registerButtonTapped()
        }
        return true
    }
}

//MARK: - UINavigationControllerDelegate

extension RegisterViewController: UINavigationControllerDelegate {}
