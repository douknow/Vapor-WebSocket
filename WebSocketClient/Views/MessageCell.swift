//
//  MessageCell.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/10.
//

import UIKit
import Kingfisher


class MessageCell: UITableViewCell {

    // MARK: - Views

    let imgView = UIImageView()
    let label = UILabel()
    let indicatorView = UIView()
    let containerView = UIView()

    let timeLabel = UILabel()
    let userLabel = UILabel()
    let infoSCV = UIStackView(views: [], axis: .vertical, spacing: 0, alignment: .leading, distribution: .equalSpacing)

    let indicatorLen: CGFloat = 7


    // MARK: - Initialize

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Helper Methods

    func setupViews() {
        backgroundColor = .clear

        imgView.contentMode = .scaleAspectFit

        label.numberOfLines = 0

        indicatorView.transform = CGAffineTransform(rotationAngle: .pi/4)
        contentView.addSubview(indicatorView) { [self] in
            $0.width.height.equalTo(indicatorLen)
        }

        containerView.layer.cornerRadius = 4

        timeLabel.font = .systemFont(ofSize: 9)
        timeLabel.textColor = .secondaryLabel

        userLabel.font = .systemFont(ofSize: 9)
        userLabel.textColor = .secondaryLabel

        infoSCV.addArrangedSubviews([userLabel, timeLabel])
    }

    func config(_ message: Message) -> Self {
        imgView.removeFromSuperview()
        label.removeFromSuperview()

        switch message.content {
        case let .img(url):
            containerView.addSubview(imgView) {
                $0.edges.equalToSuperview().inset(8)
                $0.width.height.equalTo(220)
            }

            imgView.kf.setImage(with: url)
        case let .text(content):
            containerView.addSubview(label) {
                $0.leading.trailing.equalToSuperview().inset(8)
                $0.top.bottom.equalToSuperview().inset(8)
            }

            label.text = content
            label.sizeToFit()
            label.textAlignment = message.style == .receive ? .left : .right
        }

        timeLabel.text = message.timeDes
        timeLabel.sizeToFit()

        userLabel.text = message.userDes
        userLabel.sizeToFit()

        return self
    }

}
