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
    @objc open var url: String = ""
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if let userData = WMGlobal.getUserData(),
            let addToMyWebArchive = userData["add-to-my-web-archive"] as? Bool,
            addToMyWebArchive == true {
            btnAdd.isHidden = true
            self.saveToMyWebArchive(showAlert: false)
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
            webPageVC.url = url
            DispatchQueue.main.async {
                self.present(webPageVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func _onSaveToMyArchive(_ sender: Any) {
        self.saveToMyWebArchive(showAlert: true)
    }
    
    @IBAction func _onShare(_ sender: Any) {
        displayShareSheet(url: url)
    }
    
    @IBAction func _onBack(_ sender: Any) {
#if EXTENSION
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        exit(0)
#else
        self.dismiss(animated: true, completion: nil)
#endif
    }
    
    func saveToMyWebArchive(showAlert: Bool) {
        if let userData = WMGlobal.getUserData(),
           let userProps = userData["logged-in-user"] as? [HTTPCookiePropertyKey : Any],
           let sigProps = userData["logged-in-sig"] as? [HTTPCookiePropertyKey : Any],
           let loggedInUser = HTTPCookie.init(properties: userProps),
           let loggedInSig = HTTPCookie.init(properties: sigProps)
        {
            do {
                let regex = try NSRegularExpression(pattern: "http[s]?:\\/\\/web.archive.org\\/web\\/(.*?)\\/(.*)", options: [])
                let results = regex.matches(in: url, range: NSRange(url.startIndex..., in: url))
                
                guard results.count != 0 else {
                    return
                }
                
                let snapshotUrlRange = results[0].range(at: 2)
                let snapshotRange = results[0].range(at: 1)
                
                guard
                    let snapshotUrl = url.slicing(from: snapshotUrlRange.location, length: snapshotUrlRange.length),
                    let snapshot = url.slicing(from: snapshotRange.location, length: snapshotRange.length) else {
                        return
                }
                
                MBProgressHUD.showAdded(to: self.view, animated: true)
                WMAPIManager.sharedManager.saveToMyWebArchive(url: snapshotUrl, snapshot: snapshot, logged_in_user: loggedInUser, logged_in_sig: loggedInSig) { (success) in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if (success && showAlert) {
                        WMGlobal.showAlert(title: "Success", message: "The page has been saved to your web archive successfully.", target: self)
                    }
                }
            } catch {
                print("Invalid regex")
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
