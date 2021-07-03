//
//  ShareVC.swift
//  WM
//
//  Created by mac-admin on 8/10/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD

open class ShareVC: UIViewController {

    @IBOutlet weak var btnAdd: WMButton!
    @IBOutlet weak var navBarHeight: NSLayoutConstraint!
    @objc open var shareUrl: String = ""
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // auto-saves to My Archive if switch turned on
        if let userData = WMGlobal.getUserData(),
            let addToMyWebArchive = userData["add-to-my-web-archive"] as? Bool,
            addToMyWebArchive == true
        {
            btnAdd.isHidden = true
            self.saveToMyArchive(showAlert: false)
        }
    }
    
    override open func loadView() {
        super.loadView()
        
        WMGlobal.adjustNavBarHeight(constraint: navBarHeight)
    }
    
    @IBAction func _onViewPage(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if let webPageVC = storyBoard.instantiateViewController(withIdentifier: "WebPageVC") as? WebPageVC {
            webPageVC.modalPresentationStyle = .fullScreen
            webPageVC.url = self.shareUrl
            DispatchQueue.main.async {
                self.present(webPageVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func _onSaveToMyArchive(_ sender: Any) {
        self.saveToMyArchive(showAlert: true)
    }
    
    @IBAction func _onShare(_ sender: Any) {
        displayShareSheet(url: self.shareUrl)
    }
    
    @IBAction func _onBack(_ sender: Any) {
#if EXTENSION
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        exit(0)
#else
        self.dismiss(animated: true, completion: nil)
#endif
    }
    
    func saveToMyArchive(showAlert: Bool) {

        if let userData = WMGlobal.getUserData(), userData["logged-in"] as? Bool ?? false {
            do {
                let regex = try NSRegularExpression(pattern: "http[s]?:\\/\\/web.archive.org\\/web\\/(.*?)\\/(.*)", options: [])
                let results = regex.matches(in: self.shareUrl, range: NSRange(self.shareUrl.startIndex..., in: self.shareUrl))
                
                guard results.count != 0 else {
                    return
                }
                
                let snapshotUrlRange = results[0].range(at: 2)
                let snapshotRange = results[0].range(at: 1)
                
                guard
                    let snapshotUrl = self.shareUrl.slicing(from: snapshotUrlRange.location, length: snapshotUrlRange.length),
                    let snapshot = self.shareUrl.slicing(from: snapshotRange.location, length: snapshotRange.length) else {
                        return
                }
                
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.label.text = "Saving..."

                WMSAPIManager.shared.saveToMyWebArchive(url: snapshotUrl, snapshot: snapshot,
                    loggedInUser: userData["logged-in-user"] as? String, // REMOVE or KEEP?
                    loggedInSig: userData["logged-in-sig"] as? String, // REMOVE or KEEP?
                    accessKey: userData["s3accesskey"] as? String,
                    secretKey: userData["s3secretkey"] as? String)
                { (success) in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if (showAlert) {
                        if (success) {
                            WMGlobal.showAlert(title: "Success", message: "The page has been saved to your web archive.", target: self)
                        } else {
                            WMGlobal.showAlert(title: "Failed", message: "The page was not saved to your web archive.", target: self)
                        }
                    }
                }
            } catch {
                if (DEBUG_LOG) { NSLog("*** saveToWebArchive() Invalid regex for shareUrl: \(self.shareUrl)") }
            }
        }
    }
    
    func displayShareSheet(url: String) {
        let text = "Archived in the Wayback Machine at: "
        
        let activityViewController = UIActivityViewController(activityItems: [text, url as NSString], applicationActivities: nil)
        
        
        activityViewController.completionWithItemsHandler = {
            (activityType, completed, returnedItems, err) -> Void in
            
            if (completed) {
                self.displayShareSheet(url: url)
            }
        }
        
        self.present(activityViewController, animated: true, completion: {})
    }

}
