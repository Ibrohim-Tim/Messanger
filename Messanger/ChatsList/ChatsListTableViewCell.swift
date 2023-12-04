//
//  ChatsListTableViewCell.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 03.12.2023.
//

import UIKit

final class ChatsListTableViewCell: UITableViewCell {

   static let reuseId = "ChatsListTableViewCell"
    
    // MARK: - UI Elements
    
    private let chatImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = LayoutMetrics.halfModule * 5
        return imageView
    }()
    
    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private methods
    
    private func setupLayout() {
        setupChatImageViewLayout()
    }
    
    private func setupChatImageViewLayout() {
        contentView.addSubview(chatImageView)
        
        chatImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        chatImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: LayoutMetrics.doubleModule).isActive = true
        chatImageView.widthAnchor.constraint(equalToConstant: LayoutMetrics.module * 5).isActive = true
        chatImageView.heightAnchor.constraint(equalToConstant: LayoutMetrics.module * 5).isActive = true
    }
    
    func configure() {
        
    }
}
