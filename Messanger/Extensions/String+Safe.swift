//
//  String+Safe.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 05.12.2023.
//


extension String {
    var safe: String {
        self.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
    }
}
