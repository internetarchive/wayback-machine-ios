//
//  WMButton.swift
//  WM
//
//  Created by mac-admin on 8/3/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class WMButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = 7
    }

}
