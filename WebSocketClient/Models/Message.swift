//
//  Message.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


struct Message {
    static let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt
    }()

    enum Style {
        case send, receive
    }

    let style: Style
    let content: String
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
