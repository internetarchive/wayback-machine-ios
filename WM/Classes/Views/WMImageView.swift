//
//  WMImageView.swift
//  WM
//
//  Created by mac-admin on 8/3/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class WMImageView: UIImageView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0).cgColor
        
    }
}
