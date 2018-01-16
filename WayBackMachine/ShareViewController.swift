//
//  ShareViewController.swift
//  WayBackMachine
//
//  Created by Admin on 31/01/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController{

    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    let serverURLForSavePage = "https://web.archive.org/save/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ------UI------
        shareView.layer.cornerRadius = 10
        urlTextField.isUserInteractionEnabled = false
        urlTextField.textAlignment = .center
        
        logoImageView.image = UIImage(named: "icon_logo")
        logoImageView.contentMode = .center
        logoImageView.layer.cornerRadius = logoImageView.frame.width / 2
        logoImageView.layer.masksToBounds = true
        logoImageView.layer.borderWidth = 3
        logoImageView.layer.borderColor = UIColor.white.cgColor
        logoImageView.isHidden = true
        
        btnSave.layer.cornerRadius = 10
        btnCancel.layer.cornerRadius = 10
        
        if let inputItem = self.extensionContext?.inputItems.first as? NSExtensionItem,
            let attachmentsKeys = inputItem.userInfo?[NSExtensionItemAttachmentsKey] as? [NSItemProvider] {
            var itemProvider: NSItemProvider?
            for item in attachmentsKeys {
                if item.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    itemProvider = item
                    break
                }
            }
            
            if itemProvider == nil {
                return;
            }
            itemProvider!.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: {(result, error) in
                self.performSelector(onMainThread: #selector(self.processResult(_:)), with: result, waitUntilDone: false)
            })
        }
        
    }
    
    func processResult(_ result: Any) -> Void {
        if let url = result as? NSURL {
            self.urlTextField.text = url.absoluteString
        } else {
            let errorAlert = UIAlertController(title: "", message: "Error occured when grab url.", preferredStyle: .actionSheet)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default) {action in
                
            })
            self.present(errorAlert, animated: true)
        }
    }
    
    //- MARK: Actions
    @IBAction func _onOK(_ sender: Any) {
        
        let savePageViewController = self.storyboard?.instantiateViewController(withIdentifier: "SavePageViewController") as! SavePageViewController
        savePageViewController.url = self.serverURLForSavePage + self.urlTextField.text!
        
        DispatchQueue.main.async {
            self.present(savePageViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func _onCancel(_ sender: Any) {
        exit(0)
    }
}
