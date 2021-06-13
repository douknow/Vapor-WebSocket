//
//  Message.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


struct Message {
    
    enum Style {
        case send, receive
    }

    enum Content {
        case text(String), img(URL)
    }

    static let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt
    }()

    let style: Style
    let content: Content
    let user: User
    let time: Date

    var timeDes: String {
        Self.timeFormatter.string(from: time)
    }

    var userDes: String {
        switch style {
        case .receive:
            return "From \(user.username)"
        case .send:
            return "To \(user.username)"
        }
    }
}
