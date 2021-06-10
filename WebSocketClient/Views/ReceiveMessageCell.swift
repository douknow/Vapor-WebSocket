//
//  ReceiveMessageCell.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/10.
//

import UIKit


class ReceiveMessageCell: MessageCell {

    override func setupViews() {
        super.setupViews()

        indicatorView.backgroundColor = .white

        containerView.backgroundColor = .systemBackground
        contentView.addSubview(containerView) { [self] in
            $0.width.lessThanOrEqualToSuperview().offset(-100)
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(8)

            $0.top.equalTo(indicatorView.snp.centerY).offset(-10)
            $0.leading.equalTo(indicatorView.snp.centerX)
        }

        infoSCV.alignment = .leading
        contentView.addSubview(infoSCV) { [self] in
            $0.bottom.equalTo(containerView)
            $0.leading.equalTo(containerView.snp.trailing).offset(6)
        }
    }

}
