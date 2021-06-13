//
//  UIStackView+Extension.swift
//  Puzzle
//
//  Created by Xianzhao Han on 2020/12/28.
//

import UIKit
import SnapKit


extension UIStackView {

    convenience init(views: [UIView], axis: NSLayoutConstraint.Axis, spacing: CGFloat, alignment: UIStackView.Alignment, distribution: UIStackView.Distribution) {
        self.init(arrangedSubviews: views)
        self.axis = axis
        self.spacing = spacing
        self.alignment = alignment
        self.distribution = distribution
    }

    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview)
    }

}

extension ConstraintMakerExtendable {

    @discardableResult func equalToSafeTop(_ view: UIView) -> ConstraintMakerEditable {
        equalTo(view.safeAreaLayoutGuide.snp.top)
    }

}
