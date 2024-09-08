//
//  MessageKind+Content1.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 08.09.2024.
//

import MessageKit

extension MessageKind {
    
    var content: String {
        switch self {
        case .text(let string):
            return string
        case .photo(let item):
            return item.url?.absoluteString ?? ""
        default:
            return ""
        }
    }
    
    var type: String {
        switch self {
        case .text:
            return "text"
        case .photo:
            return "photo"
        default:
            fatalError("Can be text or photo only")
        }
    }
}
