//
//  MessageConverter.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 26.09.2024.
//
import UIKit
import CoreLocation
import MessageKit

struct MessageConverter {
    
    func messages(from messages: [[String: Any]]) -> [Message] {
        messages.compactMap { message in
            guard let content = message["content"] as? String,
                  let senderEmail = message["sender_email"] as? String,
                  let messageId = message["id"] as? String,
                  let dateString = message["date"] as? String,
                  let typeString = message["type"] as? String,
                  let date = ChatViewController.formatter.date(from: dateString)
            else {
                return nil
            }
            
            let kind: MessageKind
            
            switch typeString {
            case "text":
                kind = .text(content)
            case "photo":
                let media = Media(
                    url: URL(string: content),
                    image: nil,
                    placeholderImage: UIImage(systemName: "plus")!,
                    size: CGSize(width: 300, height: 300)
                )
                kind = .photo(media)
            case "video":
                let media = Media(
                    url: URL(string: content),
                    image: nil,
                    placeholderImage: UIImage(systemName: "message")!,
                    size: CGSize(width: 300, height: 300)
                )
                kind = .video(media)
            case "location":
                let coordinates = content.components(separatedBy: ",")
                
                guard coordinates.count == 2,
                      let latitude = Double(coordinates[0]),
                      let longitude = Double(coordinates[1])
                else {
                    return nil
                }
                
                let locationItem = CLLocation(
                    latitude: latitude,
                    longitude: longitude
                )
                let location = Location(
                    location: locationItem,
                    size: CGSize(width: 150, height: 150)
                )
                kind = .location(location)
            default:
                fatalError("Unknown message type")
            }
            
            let sender = Sender(senderId: senderEmail, displayName: senderEmail)
            
            return Message(
                sender: sender,
                messageId: messageId,
                sentDate: date,
                kind: kind
            )
        }
    }
}
