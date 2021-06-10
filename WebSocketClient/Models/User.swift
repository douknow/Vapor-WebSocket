//
//  User.swift
//  
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


struct User: Codable {

    static let users = [
        User(id: 0, username: "Anna"),
        User(id: 1, username: "Bob")
    ]

    static func findUser(by id: Int) -> User? {
        users.first(where: { $0.id == id })
    }

    let id: Int
    let username: String

}
