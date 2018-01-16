//
//  EnableExtensionViewController.swift
//  WM
//
//  Created by mac-admin on 8/3/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class EnableExtensionViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func _onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
