//
//  MessageData.swift
//  
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


protocol MessageData: Codable {
    var to: Int { get }
    var time: Date { get }
    var user: User { get }

    var json: String { get }
}


extension MessageData {

    var json: String {
        let data = try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }

}


struct TextMessageData: MessageData {
    let to: Int
    let time: Date
    let user: User
    let content: String
}


struct ImgMessageData: MessageData {
    let to: Int
    let time: Date
    let user: User
    let imgURL: URL
}
