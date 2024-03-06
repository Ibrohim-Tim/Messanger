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
        imageView.image = UIImage(named: "person_placeholder")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        setupTitleLabelLayout()
        setupSubtitleLabelLayout()
    }
    
    private func setupChatImageViewLayout() {
        contentView.addSubview(chatImageView)
        
        chatImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        chatImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: LayoutMetrics.doubleModule).isActive = true
        chatImageView.widthAnchor.constraint(equalToConstant: LayoutMetrics.module * 5).isActive = true
        chatImageView.heightAnchor.constraint(equalToConstant: LayoutMetrics.module * 5).isActive = true
    }
    
    private func setupTitleLabelLayout() {
        contentView.addSubview(titleLabel)
        
        titleLabel.topAnchor.constraint(equalTo: chatImageView.topAnchor, constant: LayoutMetrics.halfModule).activate()
        titleLabel.leadingAnchor.constraint(equalTo: chatImageView.trailingAnchor, constant: LayoutMetrics.module).activate()
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -LayoutMetrics.doubleModule).activate()
    }
    
    private func setupSubtitleLabelLayout() {
        contentView.addSubview(subtitleLabel)
        
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).activate()
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).activate()
        subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).activate()
    }
    
    private func configureAvatarImage(email: String) {
        UserAvatarProvider.shared.avatar(for: email) { [weak self] data in
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self?.chatImageView.image = UIImage(data: data)
            }
        }
    }
    
    func configure(email: String, username: String, message: String) {
        titleLabel.text = username
        subtitleLabel.text = message
        configureAvatarImage(email: email)
    }
}
