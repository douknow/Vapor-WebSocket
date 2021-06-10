//
//  MessageData.swift
//  
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


struct MessageData: Codable {
    let to: Int
    let content: String
    let time: Date
    let user: User

    var json: String {
        let data = try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
