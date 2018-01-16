//
//  OfferViewController.swift
//  WM
//
//  Created by Admin on 07/02/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit
import MBProgressHUD

class SavePageViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, MBProgressHUDDelegate {

    @IBOutlet weak var containerView: UIView!
    var webView: WKWebView?
    var progressHUD: MBProgressHUD?
    var url:String = ""
    let webStorage = WKWebsiteDataStore.default()
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        webView?.frame = containerView.bounds
        self.containerView.addSubview(webView!)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!url.isEmpty) {
            self.progressHUD = MBProgressHUD(view: self.view)
            self.progressHUD!.bezelView.color = UIColor.clear
            self.view.addSubview(progressHUD!)
            self.progressHUD!.delegate = self
            self.progressHUD!.show(animated: true)
            
            var request = URLRequest(url: URL(string: url)!)
            
            if let userData = WMGlobal.getUserData(),
                let loggedInUser = userData["logged-in-user"] as? HTTPCookie,
                let loggedInSig = userData["logged-in-sig"] as? HTTPCookie
            {
                if #available(iOS 11.0, *) {
                    webStorage.httpCookieStore.setCookie(loggedInSig, completionHandler: nil)
                    webStorage.httpCookieStore.setCookie(loggedInUser, completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
            }
            
            request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "User-Agent")
            request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "Wayback-Extension-Version")
            UserDefaults.standard.register(defaults: ["UserAgent": "Wayback_Machine_iOS/\(version!)"])
            webView?.load(request)
            
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func _onBack(_ sender: Any) {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        exit(0)
    }

    @IBAction func _onOpen(_ sender: Any) {
        
    }
    
    @IBAction func onShare(_ sender: Any) {
        if (url.isEmpty) {
            return
        }
        
        self.displayShareSheet(url: (webView?.url?.absoluteString)!)
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
    
    // MARK: - Delegates
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let urlString = webView.url?.absoluteString
        if (urlString?.range(of: "https://web.archive.org/web/") != nil) {
            progressHUD?.hide(animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
