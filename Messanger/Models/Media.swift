//
//  Media.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 11.05.2024.
//

import UIKit
import MessageKit

struct Media: MediaItem {
    let url: URL?
    let image: UIImage?
    let placeholderImage: UIImage
    let size: CGSize
}
