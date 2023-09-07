//
//  WebPageVC.swift
//  WM
//
//  Created by mac-admin on 8/10/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit
import MBProgressHUD

open class WebPageVC: UIViewController, WKUIDelegate, WKNavigationDelegate, MBProgressHUDDelegate {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var navBarHeight: NSLayoutConstraint!
    
    var webView: WKWebView?
    var progressHUD: MBProgressHUD?
    @objc open var url: String = ""
    let webStorage = WKWebsiteDataStore.default()
    
    override open func loadView() {
        super.loadView()
        
        WMGlobal.adjustNavBarHeight(constraint: navBarHeight)
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        webView?.frame = containerView.bounds
        if let webView = webView {
            self.containerView.addSubview(webView)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if let webView = webView {
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
            // Load the web page
            webView.load(URLRequest(url: URL(string: url)!))
        }
    }
    
    @IBAction func _onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func _onShare(_ sender: Any) {
        displayShareSheet(url: url)
    }
    
    func displayShareSheet(url: String) {
        let text = "Archived in the Wayback Machine at: "
        
        let activityViewController = UIActivityViewController(activityItems: [text, url as NSString], applicationActivities: nil)
        
        
        activityViewController.completionWithItemsHandler = {
            (activityType, completed, returnedItems, err) -> Void in
            
            if (completed) {
                // don't do anything
            }
        }
        
        self.present(activityViewController, animated: true, completion: {})
    }
    
    // MARK: - WKWebView Delegates

    //public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        MBProgressHUD.hide(for: self.view, animated: true)
    }

}
