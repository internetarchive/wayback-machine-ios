//
//  HomeViewController.swift
//  WM
//
//  Created by mac-admin on 8/9/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class HomeViewController: UIViewController, UITextFieldDelegate, MBProgressHUDDelegate {

    @IBOutlet weak var txtURL: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    var progressHUD: MBProgressHUD?
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtURL.delegate = self
        
        self.progressHUD = MBProgressHUD(view: self.view)
        self.progressHUD!.bezelView.color = UIColor.clear
        self.view.addSubview(progressHUD!)
        self.progressHUD!.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func showWebPage(url: String) -> Void {
        if url.isEmpty {
            return
        }
        
        let webPageViewController = self.storyboard?.instantiateViewController(withIdentifier: "WebPageVC") as! WebPageVC
        webPageViewController.modalPresentationStyle = .fullScreen
        webPageViewController.url = url
        
        DispatchQueue.main.async {
            self.present(webPageViewController, animated: true, completion: nil)
        }
    }

    @IBAction func _onSave(_ sender: Any) {
        if self.txtURL.text!.isEmpty {
            WMGlobal.showAlert(title: "", message: "Please type a URL", target: self)
            return
        }
        
        if (!verifyURL(url: getURL(url: self.txtURL.text!))) {
            WMGlobal.showAlert(title: "", message: "The URL is invalid", target: self)
        } else {
            showProgress()
            WMAPIManager.sharedManager.checkURLBlocked(url: getURL(url: self.txtURL.text!), completion: { (isBlocked) in
                
                if isBlocked {
                    WMGlobal.showAlert(title: "Error", message: "That site's robots.txt policy requests we not archive it.", target: self)
                    self.hideProgress(isBlocked)
                    return
                }
                
                if let userData = WMGlobal.getUserData() {
                    
                    WMAPIManager
                        .sharedManager
                        .getCookieData(email: userData["email"] as! String,
                                       password: userData["password"] as! String,
                                       completion: { (cookieData) in
                                        
                        let loggedInSig = cookieData["logged-in-sig"] as! HTTPCookie
                        let loggedInUser = cookieData["logged-in-user"] as! HTTPCookie
                        var tmpData = userData
                        
                        tmpData["logged-in-sig"] = loggedInSig
                        tmpData["logged-in-user"] = loggedInUser
                        WMGlobal.saveUserData(userData: tmpData)
                                        
                        WMAPIManager
                            .sharedManager
                            .request_capture(url: self.getURL(url: self.txtURL.text!),
                                             logged_in_user: loggedInUser,
                                             logged_in_sig: loggedInSig,
                                             completion: { (job_id) in
                                
                            if job_id == nil {
                                self.hideProgress(isBlocked)
                                return
                            }
                            
                            WMAPIManager
                                .sharedManager
                                .request_capture_status(job_id: job_id!,
                                                        logged_in_user: loggedInUser,
                                                        logged_in_sig: loggedInSig,
                                                        completion: { (url, error) in
                                if url == nil || url?.isEmpty ?? false {
                                    self.hideProgress(isBlocked)
                                    WMGlobal.showAlert(title: "Error", message: "\(error!)", target: self)
                                } else {
                                    self.hideProgress(isBlocked)
                                    let shaveVC = self.storyboard?.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
                                    shaveVC.modalPresentationStyle = .fullScreen
                                    shaveVC.url = url!
                                    DispatchQueue.main.async {
                                        self.present(shaveVC, animated: true, completion: nil)
                                    }
                                }
                            })
                        })
                    })
                }
            })
            
        }
    }
    
    @IBAction func _onRecent(_ sender: Any) {
        if self.txtURL.text!.isEmpty {
            WMGlobal.showAlert(title: "", message: "Please type a URL", target: self)
            return
        }
        
        if (!verifyURL(url: getURL(url: self.txtURL.text!))) {
            WMGlobal.showAlert(title: "", message: WMConstants.errors[201]!, target: self)
        } else {
            showProgress()
            
            WMAPIManager.sharedManager.checkURLBlocked(url: self.getURL(url: self.txtURL.text!), completion: { (isBlocked) in
                if isBlocked {
                    self.hideProgress(isBlocked)
                    WMGlobal.showAlert(title: "", message: "That site's robots.txt policy requests we not play back archives", target: self)
                    return
                } else {
                    self.wmAvailabilityCheck(url: self.getOriginalURL(url: self.txtURL.text!) , timestamp: nil) { (wayback_url, errorCode) in
                        self.performSelector(onMainThread: #selector(self.hideProgress(_:)), with: wayback_url, waitUntilDone: false)
                        if wayback_url == nil {
                            self.performSelector(onMainThread: #selector(self.showErrorMessage(message:)), with: WMConstants.errors[errorCode]!, waitUntilDone: false)
                        } else {
                            self.showWebPage(url: wayback_url!)
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func _onFirst(_ sender: Any) {
        if self.txtURL.text!.isEmpty {
            showErrorMessage(message: "Please type a URL")
            return
        }
        
        if (!verifyURL(url: getURL(url: self.txtURL.text!))) {
            showErrorMessage(message: "The URL is invalid")
        } else {
            showProgress()
            
            WMAPIManager.sharedManager.checkURLBlocked(url: self.getURL(url: self.txtURL.text!), completion: { (isBlocked) in
                if isBlocked {
                    self.hideProgress(isBlocked)
                    self.showErrorMessage(message: "That site's robots.txt policy requests we not play back archives")
                    return
                } else {
                    self.wmAvailabilityCheck(url: self.getOriginalURL(url: self.txtURL.text!) , timestamp: "00000000000000") { (wayback_url, errorCode) in
                        self.performSelector(onMainThread: #selector(self.hideProgress(_:)), with: wayback_url, waitUntilDone: false)
                        if wayback_url == nil {
                            self.performSelector(onMainThread: #selector(self.showErrorMessage(message:)), with: WMConstants.errors[errorCode]!, waitUntilDone: false)
                        } else {
                            self.showWebPage(url: wayback_url!)
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func _onAll(_ sender: Any) {
        if self.txtURL.text!.isEmpty {
            showErrorMessage(message: "Please type a URL")
            return
        }

        if !verifyURL(url: getURL(url: self.txtURL.text!)) {
            showErrorMessage(message: "The URL is invalid")
        } else {
            showProgress()
            WMAPIManager.sharedManager.checkURLBlocked(url: self.getURL(url: self.txtURL.text!), completion: { (isBlocked) in
                if isBlocked {
                    self.hideProgress(isBlocked)
                    self.showErrorMessage(message: "That site's robots.txt policy requests we not play back archives")
                    return
                } else {
                    self.getAllArchives(url: self.getOriginalURL(url: self.txtURL.text!), completion: { (response) in
                        self.performSelector(onMainThread: #selector(self.hideProgress(_:)), with: nil, waitUntilDone: false)
                        if (response == nil) {
                            return
                        }
                        self.performSelector(onMainThread: #selector(self.showCalendarVC(archives:)), with: response, waitUntilDone: false)
                    })
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func showErrorMessage(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default) {action in
            
        })
        self.present(errorAlert, animated: true)
    }
    
    @objc func showCalendarVC(archives: [Dictionary<String, Any>]) {
        var events = [SSEvent]()
        var years = [Int]()
        for archive in archives {
            events.append(generateCapture(year: archive["year"] as! Int, month: archive["month"] as! Int, day: archive["day"] as! Int, hour: archive["hour"] as! String, minute: archive["minute"] as! String, archivedURL: archive["archivedURL"] as! String))
        }
        for year in (archives[0]["year"] as! Int)...(archives[archives.count-1]["year"] as! Int) {
            years.append(year)
        }
        
        SSStyles.applyNavigationBarStyles()
        let annualViewController = SSCalendarAnnualViewController(events: events, years:years)
        let navigationController = UINavigationController(rootViewController: annualViewController!)
        navigationController.navigationBar.isTranslucent = false
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func getAllArchives(url: String, completion: @escaping ([Any]?) -> Void) {
        let param = "?url=" + url + "&fl=timestamp,original&output=json"
        var request = URLRequest(url: URL(string: "http://web.archive.org/cdx/search/cdx" + param)!)
        request.httpMethod = "GET"
        request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "User-Agent")
        request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "Wayback-Extension-Version")
        request.setValue("2", forHTTPHeaderField: "Wayback-Api-Version")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completion(nil)
            }
            
            do {
                if let archives = try JSONSerialization.jsonObject(with: data, options: []) as? [[Any]] {
                    var ret = [Dictionary<String, Any>]()
                    for i in 1...archives.count-1 {
                        let timestamp = archives[i][0] as! String
                        let archive = [
                            "originalURL" : archives[i][1] as! String,
                            "archivedURL" : "https://web.archive.org/web/" + timestamp + "/" + (archives[i][1] as! String),
                            "year" : Int(timestamp.substring(with: timestamp.startIndex..<timestamp.index(timestamp.startIndex, offsetBy: 4)))!,
                            "month" : Int(timestamp.substring(with: timestamp.index(timestamp.startIndex, offsetBy: 4)..<timestamp.index(timestamp.startIndex, offsetBy: 6)))!,
                            "day" : Int(timestamp.substring(with: timestamp.index(timestamp.startIndex, offsetBy: 6)..<timestamp.index(timestamp.startIndex, offsetBy: 8)))!,
                            "hour" : timestamp.substring(with: timestamp.index(timestamp.startIndex, offsetBy: 8)..<timestamp.index(timestamp.startIndex, offsetBy: 10)),
                            "minute" : timestamp.substring(with: timestamp.index(timestamp.startIndex, offsetBy: 10)..<timestamp.index(timestamp.startIndex, offsetBy: 12))
                        ] as [String : Any]
                        ret.append(archive)
                    }
                    completion(ret)
                } else {
                    completion(nil)
                }
                
            } catch _ {
                completion(nil)
            }
            
        }
        
        task.resume()
    }
    
    func generateCapture(year: Int, month: Int, day: Int, hour: String, minute: String, archivedURL: String) -> SSEvent {
        let event = SSEvent()
        event.startDate = SSCalendarUtils.date(withYear: year, month: month, day: day)
        event.startTime = hour + ":" + minute
        event.name = "Archive"
        event.desc = archivedURL
        
        return event
    }
    
    public func verifyURL(url: String?) -> Bool {
        if let url = url {
            if let url = URL(string: url) {
                return UIApplication.shared.canOpenURL(url)
            }
        }
        return false
    }
    
    public func wmAvailabilityCheck(url: String, timestamp: String?, completion: @escaping (String?, Int) -> Void) {
        
        var postString = "url=" + url
        
        if (timestamp != nil) {
            postString += "&&timestamp=" + timestamp!
        }
        
        var request = URLRequest(url: URL(string: "https://archive.org/wayback/available")!)
        request.httpMethod = "POST"
        request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "User-Agent")
        request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "Wayback-Extension-Version")
        request.setValue("2", forHTTPHeaderField: "Wayback-Api-Version")
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completion(nil, 101)
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                    print("Data-", json)
                    self.getWaybackUrlFromResponse(response: json, completionHandler: { (wayback_url, errorCode) in
                        completion(wayback_url, errorCode)
                    })
                    
                } else {
                    completion(nil, 103)
                }
                
            } catch _ {
                completion(nil, 103)
            }
            
        }
        
        task.resume()
    }
    
    func getWaybackUrlFromResponse(response: [String: Any], completionHandler: @escaping (String?, Int) -> Void) {
        let results = response["results"] as Any
        let results_first = ((response["results"] as? [Any])?[0])
        let archived_snapshots = (results_first as? [String: Any])?["archived_snapshots"]
        let closest = (archived_snapshots as? [String: Any])?["closest"]
        let available = (closest as? [String: Any])? ["available"] as? Bool
        let status = (closest as? [String: Any])? ["status"] as? String
        let url = (closest as? [String: Any])? ["url"] as? String
        
        if (results != nil &&
            results_first != nil &&
            archived_snapshots != nil &&
            closest != nil &&
            available != nil &&
            available == true &&
            status == "200" &&
            isValidSnapshotUrl(url: url)) {
            completionHandler(url, 100)
        }  else {
            completionHandler(url, 102)
        }
        
    }
    
    func isValidSnapshotUrl(url: String?) -> Bool {
        if (url == nil) {
            return false
        }
        
        if (url!.range(of: "http://") != nil || (url!.range(of: "https://") != nil)) {
            return true
        } else {
            return false
        }
    }
    
    func getOriginalURL(url: String) -> String {
        var originalURL:String? = nil
        let tempArray = url.components(separatedBy: "http")
        if (tempArray.count > 2) {
            originalURL = "http" + tempArray[2]
        } else {
            originalURL = url
        }
        
        return originalURL!
    }
    
    func getURL(url: String) -> String {
        var url = self.txtURL.text!
        
        if ((url.range(of: "http:") == nil) && (url.range(of: "https:") == nil)) {
            url = "https://" + url
        }
        
        return url
    }
    
    func showProgress() -> Void {
        self.progressHUD!.show(animated: true)
    }
    
    @objc func hideProgress(_ result: Any) -> Void {
        self.progressHUD!.hide(animated: true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if scrollView.contentInset.bottom == 0 {
                scrollView.contentInset.bottom = keyboardSize.height
                scrollView.contentOffset.y = keyboardSize.height
            }
            
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if scrollView.contentInset.bottom > 0 {
            scrollView.contentInset.bottom = 0
            scrollView.contentOffset.y = 0
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //- MARK: UITextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

}
