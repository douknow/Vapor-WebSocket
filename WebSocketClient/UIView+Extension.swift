//
//  UIView+Extensions.swift
//  GIF Creator
//
//  Created by Xianzhao Han on 2020/4/8.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import SnapKit

extension UIView {

    func addSubview(_ view: UIView, closure: ((ConstraintMaker) -> Void)? = nil) {
        addSubview(view)
        if let closure = closure {
            view.snp.makeConstraints(closure)
        }
    }

    func insertSubview(_ view: UIView, aboveSubview: UIView, closure: ((ConstraintMaker) -> Void)? = nil) {
        insertSubview(view, aboveSubview: aboveSubview)
        if let closure = closure {
            view.snp.makeConstraints(closure)
        }
    }

    func insertSubview(_ view: UIView, at index: Int, closure: ((ConstraintMaker) -> Void)? = nil) {
        insertSubview(view, at: index)
        if let closure = closure {
            view.snp.makeConstraints(closure)
        }
    }

    func enableShadow(color: UIColor = .black,
                      opacity: Float = 0.08,
                      offsetX: CGFloat = 0,
                      offsetY: CGFloat = 4,
                      radius: CGFloat = 6) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: offsetX, height: offsetY)
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
    }

}
