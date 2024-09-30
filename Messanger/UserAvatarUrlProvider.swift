//
//  UserAvatarUrlProvider.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 27.09.2024.
//

import Foundation

struct UserAvatarUrlProvider {
    
    func userAvatarUrl(email: String, completion: @escaping (URL?) -> Void) {
        StorageManager.shared.url(for: email.safe + "-picture.png") { result in
            switch result {
            case .success(let url):
                completion(url)
            case .failure(let error):
                completion(nil)
                print(error)
            }
        }
    }
}
