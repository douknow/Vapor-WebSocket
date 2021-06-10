//
//  SendMessageCell.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/10.
//

import UIKit


class SendMessageCell: MessageCell {

    override func setupViews() {
        super.setupViews()

        label.textColor = .white

        indicatorView.backgroundColor = .systemBlue

        containerView.backgroundColor = .systemBlue
        contentView.addSubview(containerView) { [self] in
            $0.width.lessThanOrEqualToSuperview().offset(-100)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.bottom.equalToSuperview().inset(8)

            $0.top.equalTo(indicatorView.snp.centerY).offset(-10)
            $0.trailing.equalTo(indicatorView.snp.centerX)
        }

        infoSCV.alignment = .trailing
        contentView.addSubview(infoSCV) { [self] in
            $0.bottom.equalTo(containerView)
            $0.trailing.equalTo(containerView.snp.leading).offset(-6)
        }
    }

}
