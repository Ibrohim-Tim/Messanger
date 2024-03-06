//
//  UserAvatarProvider.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 11.01.2024.
//

import Foundation

final class UserAvatarProvider {
    
    static let shared = UserAvatarProvider()
    
    private var avatars: [String: Data] = [:]
    
    private init() {}
    
    func fetchUserAvatar(email: String) {
        fetchData(for: email, completion: nil)
    }
    
    func avatar(for email: String, completion: @escaping (Data?) -> Void) {
        if let data = avatars[email] {
            completion(data)
        } else {
            fetchData(for: email, completion: completion)
        }
    }
    
    private func fetchData(
        for email: String,
        completion: ((Data?) -> Void)?
    ) {
        StorageManager.shared.url(for: email.safe + "-picture.png") { result in
            switch result {
            case .success(let url):
                let urlRequest = URLRequest(url: url)
                
                URLSession.shared.dataTask(with: urlRequest) { [weak self] data, _, error in
                    guard let data = data, error == nil else {
                        completion?(nil)
                        return
                    }
                    
                    self?.avatars[email] = data
                    
                    completion?(data)
                }.resume()
            case .failure(let error):
                completion?(nil)
                print(error)
            }
        }
    }
}
