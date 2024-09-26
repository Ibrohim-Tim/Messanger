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
        case .photo(let item), .video(let item):
            return item.url?.absoluteString ?? ""
        case .location(let item):
            return "\(item.location.coordinate.latitude),\(item.location.coordinate.longitude)"
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
        case .video:
            return "video"
        case .location:
            return "location"
        default:
            fatalError("Unknown message type")
        }
    }
}
