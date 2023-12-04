//
//  BaseComponentsFactory.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 28.11.2023.
//

import UIKit

struct BaseComponentsFactory {
    
    static func makeTextField(placeholder: String?) -> UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.backgroundColor = Colors.ligthGrayBackgroundColor
        textField.layer.cornerRadius = LayoutMetrics.module
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: .init(x: 0, y: 0, width: LayoutMetrics.doubleModule, height: 0))
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Colors.ligthGrayBorderColor.cgColor
        textField.heightAnchor.constraint(equalToConstant: LayoutMetrics.module * 7).isActive = true
        return textField
    }
    
    static func makeActionButton(title: String, color: UIColor = Colors.buttonDarkColor) -> UIButton {
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = LayoutMetrics.module
        button.heightAnchor.constraint(equalToConstant: LayoutMetrics.module * 7).isActive = true
        return button
    }
    
    static func makeGreetingLabel(text: String?) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .boldSystemFont(ofSize: 30)
        label.numberOfLines = 2
        return label
    }
}
