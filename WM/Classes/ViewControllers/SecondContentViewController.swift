//
//  SecondContentViewController.swift
//  WM
//
//  Created by mac-admin on 8/2/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class SecondContentViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func _onEnable(_ sender: Any) {
        let enableExtensionViewController = self.storyboard?.instantiateViewController(withIdentifier: "EnableExtensionViewController")
        enableExtensionViewController?.modalPresentationStyle = .fullScreen
        self.present(enableExtensionViewController!, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
