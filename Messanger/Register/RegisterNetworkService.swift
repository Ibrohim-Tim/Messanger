//
//  RegisterNetworkService.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 30.11.2023.
//

import Foundation
import FirebaseAuth

final class RegisterNetworkService {
    
    enum RegistrationError: Error {
        case error(Error?)
    }
    
    func register(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { result, error in
            guard let result = result, let email = result.user.email, error == nil else {
                completion(
                    .failure(
                        RegistrationError.error(error)
                    )
                )
                return
            }
            
            completion(
                .success(email)
            )
        }
    }
}
