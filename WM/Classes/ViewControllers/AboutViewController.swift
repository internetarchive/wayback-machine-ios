//
//  HelpViewController.swift
//  WM
//
//  Created by mac-admin on 8/2/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import MessageUI
import FRHyperLabel

class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var txtVersion: UILabel!
    @IBOutlet weak var txtSupport: FRHyperLabel!
    @IBOutlet weak var navbar: UIView!
    @IBOutlet weak var navBarHeight: NSLayoutConstraint!
    
    var shouldShowNavbar: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WMGlobal.adjustNavBarHeight(constraint: navBarHeight)

        txtVersion.text = (txtVersion.text ?? "") + "\(APP_VERSION) (\(APP_BUILD))"
        let strSupport = txtSupport.text ?? ""
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)]
        
        let attributedString =  NSMutableAttributedString(attributedString: NSAttributedString(string: strSupport, attributes: attributes))
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body), range: NSRange(location: strSupport.count - 17,length: 17))
        
        txtSupport.attributedText = attributedString
        txtSupport.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        
        let handler = {
            (hyperLabel: FRHyperLabel?, substring: String?) -> Void in
            if (MFMailComposeViewController.canSendMail()) {
                let composeVC = MFMailComposeViewController()
                composeVC.mailComposeDelegate = self as MFMailComposeViewControllerDelegate
                composeVC.setToRecipients(["info@archive.org"])
                composeVC.modalPresentationStyle = .fullScreen
                self.present(composeVC, animated: true, completion: nil)
            }
        }
        
        txtSupport.setLinkForSubstring("info@archive.org", withLinkHandler: handler)
        
        if !shouldShowNavbar {
            self.navbar.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //- MARK: Delegates
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //- MARK: Actions
    
    @IBAction func onBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}
