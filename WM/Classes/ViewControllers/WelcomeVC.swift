//
//  WelcomeVC.swift
//  WM
//
//  Created by Admin on 10/10/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit

class WelcomeVC: WMBaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if WMGlobal.isLoggedIn() {
            let tabbarVC = self.storyboard?.instantiateViewController(withIdentifier: "TabbarVC") as! UITabBarController
            self.present(tabbarVC, animated: true, completion: nil)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
