//
//  User.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 05.12.2023.
//

import Foundation

struct User {
    let username: String
    let email: String
    
    var pictureFilename: String {
        email.safe + "-picture.png"
    }
}
