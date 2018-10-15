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
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        txtVersion.text = txtVersion.text! + (version as! String)
        let strSupport = txtSupport.text!
        let attributes = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        
        let attributedString =  NSMutableAttributedString(attributedString: NSAttributedString(string: strSupport, attributes: attributes))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body), range: NSRange(location: strSupport.characters.count - 17,length: 17))
        
        txtSupport.attributedText = attributedString
        txtSupport.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        
        let handler = {
            (hyperLabel: FRHyperLabel?, substring: String?) -> Void in
            if (MFMailComposeViewController.canSendMail()) {
                let composeVC = MFMailComposeViewController()
                composeVC.mailComposeDelegate = self as MFMailComposeViewControllerDelegate
                composeVC.setToRecipients(["info@archive.org"])
                self.present(composeVC, animated: true, completion: nil)
            }
        }
        
        txtSupport.setLinkForSubstring("info@archive.org", withLinkHandler: handler)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //- MARK: Delegates
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

}
