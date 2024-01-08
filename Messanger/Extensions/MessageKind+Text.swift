//
//  MessageKind+Text.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 02.01.2024.
//

import MessageKit

extension MessageKind {
    
    var messageText: String {
        switch self {
        case .text(let string):
            return string
        default:
            return ""
//        case .attributedText(let nSAttributedString):
//            <#code#>
//        case .photo(let mediaItem):
//            <#code#>
//        case .video(let mediaItem):
//            <#code#>
//        case .location(let locationItem):
//            <#code#>
//        case .emoji(let string):
//            <#code#>
//        case .audio(let audioItem):
//            <#code#>
//        case .contact(let contactItem):
//            <#code#>
//        case .linkPreview(let linkItem):
//            <#code#>
//        case .custom(let any):
//            <#code#>
        }
    }
}
