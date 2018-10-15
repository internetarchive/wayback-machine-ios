//
//  WMView.swift
//  WM
//
//  Created by Admin on 10/11/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
            clipsToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return layer.borderColor != nil ? UIColor(cgColor: layer.borderColor!) : nil
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
}
