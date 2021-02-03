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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtURL.delegate = self
        
        self.progressHUD = MBProgressHUD(view: self.view)
        if let pHUD = self.progressHUD {
            pHUD.bezelView.color = UIColor.clear
            self.view.addSubview(pHUD)
            pHUD.delegate = self
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func showWebPage(url: String) -> Void {
        if url.isEmpty {
            return
        }
        DispatchQueue.main.async {
            if let webPageViewController = self.storyboard?.instantiateViewController(withIdentifier: "WebPageVC") as? WebPageVC {
                webPageViewController.modalPresentationStyle = .fullScreen
                webPageViewController.url = url
                self.present(webPageViewController, animated: true, completion: nil)
            }
        }
    }

    @IBAction func _onSave(_ sender: Any) {
        let tURL = self.txtURL.text ?? ""
        if tURL.isEmpty {
            WMGlobal.showAlert(title: "", message: "Please type a URL", target: self)
            return
        }
        
        if (!verifyURL(url: getURL(url: tURL))) {
            WMGlobal.showAlert(title: "", message: "The URL is invalid", target: self)
        } else {
            showProgress()
            WMAPIManager.sharedManager.checkURLBlocked(url: getURL(url: tURL), completion: { (isBlocked) in
                
                if isBlocked {
                    WMGlobal.showAlert(title: "Error", message: "That site's robots.txt policy requests we not archive it.", target: self)
                    self.hideProgress(isBlocked)
                    return
                }
                
                if let userData = WMGlobal.getUserData() {
                    
                    WMAPIManager
                        .sharedManager
                        .getCookieData(email: userData["email"] as? String ?? "",
                                       password: userData["password"] as? String ?? "",
                                       completion: { (cookieData) in

                        guard let loggedInSig = cookieData["logged-in-sig"] as? HTTPCookie else { return }
                        guard let loggedInUser = cookieData["logged-in-user"] as? HTTPCookie else { return }
                        var tmpData = userData
                        // can't save HTTPCookie in userData directly
                        tmpData["logged-in-sig"] = loggedInSig.properties
                        tmpData["logged-in-user"] = loggedInUser.properties
                        WMGlobal.saveUserData(userData: tmpData)
                                        
                        WMAPIManager
                            .sharedManager
                            .request_capture(url: self.getURL(url: tURL),
                                             logged_in_user: loggedInUser,
                                             logged_in_sig: loggedInSig,
                                             completion: { (job_id) in
                                
                            guard let job_id = job_id else {
                                self.hideProgress(isBlocked)
                                return
                            }

                            WMAPIManager
                                .sharedManager
                                .request_capture_status(job_id: job_id,
                                                        logged_in_user: loggedInUser,
                                                        logged_in_sig: loggedInSig,
                                                        completion: { (url, error) in
                                if url == nil || url?.isEmpty ?? false {
                                    self.hideProgress(isBlocked)
                                    WMGlobal.showAlert(title: "Error", message: (error ?? ""), target: self)
                                } else {
                                    self.hideProgress(isBlocked)
                                    if let shareVC = self.storyboard?.instantiateViewController(withIdentifier: "ShareVC") as? ShareVC {
                                        shareVC.modalPresentationStyle = .fullScreen
                                        shareVC.url = url!
                                        DispatchQueue.main.async {
                                            self.present(shareVC, animated: true, completion: nil)
                                        }
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
        let tURL = self.txtURL.text ?? ""
        if tURL.isEmpty {
            WMGlobal.showAlert(title: "", message: "Please type a URL", target: self)
            return
        }
        
        if (!verifyURL(url: getURL(url: tURL))) {
            WMGlobal.showAlert(title: "", message: WMConstants.errors[201] ?? WMConstants.unknown, target: self)
        } else {
            showProgress()
            
            WMAPIManager.sharedManager.checkURLBlocked(url: self.getURL(url: tURL), completion: { (isBlocked) in
                if isBlocked {
                    self.hideProgress(isBlocked)
                    WMGlobal.showAlert(title: "", message: "That site's robots.txt policy requests we not play back archives", target: self)
                    return
                } else {
                    self.wmAvailabilityCheck(url: self.getOriginalURL(url: tURL) , timestamp: nil) { (wayback_url, errorCode) in
                        self.performSelector(onMainThread: #selector(self.hideProgress(_:)), with: wayback_url, waitUntilDone: false)
                        if wayback_url == nil {
                            self.performSelector(onMainThread: #selector(self.showErrorMessage(message:)), with: WMConstants.errors[errorCode] ?? WMConstants.unknown, waitUntilDone: false)
                        } else {
                            self.showWebPage(url: wayback_url!)
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func _onFirst(_ sender: Any) {
        let tURL = self.txtURL.text ?? ""
        if tURL.isEmpty {
            showErrorMessage(message: "Please type a URL")
            return
        }
        
        if (!verifyURL(url: getURL(url: tURL))) {
            showErrorMessage(message: "The URL is invalid")
        } else {
            showProgress()
            
            WMAPIManager.sharedManager.checkURLBlocked(url: self.getURL(url: tURL), completion: { (isBlocked) in
                if isBlocked {
                    self.hideProgress(isBlocked)
                    self.showErrorMessage(message: "That site's robots.txt policy requests we not play back archives")
                    return
                } else {
                    self.wmAvailabilityCheck(url: self.getOriginalURL(url: tURL) , timestamp: "00000000000000") { (wayback_url, errorCode) in
                        self.performSelector(onMainThread: #selector(self.hideProgress(_:)), with: wayback_url, waitUntilDone: false)
                        if wayback_url == nil {
                            self.performSelector(onMainThread: #selector(self.showErrorMessage(message:)), with: WMConstants.errors[errorCode] ?? WMConstants.unknown, waitUntilDone: false)
                        } else {
                            self.showWebPage(url: wayback_url!)
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func _onAll(_ sender: Any) {
        let tURL = self.txtURL.text ?? ""
        if tURL.isEmpty {
            showErrorMessage(message: "Please type a URL")
            return
        }

        if !verifyURL(url: getURL(url: tURL)) {
            showErrorMessage(message: "The URL is invalid")
        } else {
            showProgress()
            WMAPIManager.sharedManager.checkURLBlocked(url: self.getURL(url: tURL), completion: { (isBlocked) in
                if isBlocked {
                    self.hideProgress(isBlocked)
                    self.showErrorMessage(message: "That site's robots.txt policy requests we not play back archives")
                    return
                } else {
                    self.getAllArchives(url: self.getOriginalURL(url: tURL), completion: { (response) in
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
        if archives.isEmpty { return }
        for archive in archives {
            if let year = archive["year"] as? Int, let month = archive["month"] as? Int,
              let day = archive["day"] as? Int, let hour = archive["hour"] as? Int,
              let minute = archive["minute"] as? Int, let archivedURL = archive["archivedURL"] as? String {
                events.append(generateCapture(year: year, month: month, day: day, hour: hour, minute: minute, archivedURL: archivedURL))
            }
        }
        if let firstYear = archives.first!["year"] as? Int,
            let lastYear = archives.last!["year"] as? Int {
            for year in firstYear...lastYear {
                years.append(year)
            }
        }
        SSStyles.applyNavigationBarStyles()
        if let annualViewController = SSCalendarAnnualViewController(events: events, years:years) {
            let navigationController = UINavigationController(rootViewController: annualViewController)
            navigationController.navigationBar.isTranslucent = false
            navigationController.modalPresentationStyle = .fullScreen
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func getAllArchives(url: String, completion: @escaping ([Any]?) -> Void) {
        let param = "?url=" + url + "&fl=timestamp,original&output=json"
        var request = URLRequest(url: URL(string: "http://web.archive.org/cdx/search/cdx" + param)!)
        request.httpMethod = "GET"
        request.setValue("Wayback_Machine_iOS/\(APP_VERSION)", forHTTPHeaderField: "User-Agent")
        request.setValue("Wayback_Machine_iOS/\(APP_VERSION)", forHTTPHeaderField: "Wayback-Extension-Version")
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
                      if let timestamp = archives[i][0] as? String, let originalURL = archives[i][1] as? String {
                        let archive = [
                            "originalURL" : originalURL,
                            "archivedURL" : "https://web.archive.org/web/" + timestamp + "/" + originalURL,
                            "year"   : Int(timestamp.slicing(from: 0, length: 4) ?? "1900") ?? 1900,
                            "month"  : Int(timestamp.slicing(from: 4, length: 2) ?? "01") ?? 1,
                            "day"    : Int(timestamp.slicing(from: 6, length: 2) ?? "01") ?? 1,
                            "hour"   : Int(timestamp.slicing(from: 8, length: 2) ?? "00") ?? 0,
                            "minute" : Int(timestamp.slicing(from:10, length: 2) ?? "00") ?? 0
                        ] as [String : Any]
                        ret.append(archive)
                      }
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
    
    func generateCapture(year: Int, month: Int, day: Int, hour: Int, minute: Int, archivedURL: String) -> SSEvent {
        let event = SSEvent()
        event.startDate = SSCalendarUtils.date(withYear: year, month: month, day: day)
        event.startTime = String(format: "%2d:%2d", hour, minute)
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

    // TODO: move func to cross-platform APIManager version
    // [ ] instead of returning an error code Int, return an error enum (to define)
    // [ ] move all API URLs to central location
    
    public func wmAvailabilityCheck(url: String, timestamp: String?, completion: @escaping (String?, Int) -> Void) {
        
        var postString = "url=" + url
        
        if (timestamp != nil) {
            postString += "&&timestamp=" + timestamp!
        }
        
        var request = URLRequest(url: URL(string: "https://archive.org/wayback/available")!)
        request.httpMethod = "POST"
        request.setValue("Wayback_Machine_iOS/\(APP_VERSION)", forHTTPHeaderField: "User-Agent")
        request.setValue("Wayback_Machine_iOS/\(APP_VERSION)", forHTTPHeaderField: "Wayback-Extension-Version")
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
                    if (DEBUG_LOG) { print("DATA: ", json) }
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

    // TODO: move func to cross-platform APIManager version
    // [ ] async not needed, convert to sync

    func getWaybackUrlFromResponse(response: [String: Any], completionHandler: @escaping (String?, Int) -> Void) {

        // JSON format:
        // "results" : [ { "archived_snapshots": { "closest": { "available": true, "status": "200", "url": "http:..." } } } ]

        if let results = response["results"] as? [[String: Any]],
           let archivedSnapshots = results.first?["archived_snapshots"] as? [String: Any],
           let closest = archivedSnapshots["closest"] as? [String: Any],
           let available = closest["available"] as? Bool,
           let status = closest["status"] as? String,
           let url = closest["url"] as? String
        {
            if (available == true) && (status == "200") && isValidSnapshotUrl(url: url) {
                completionHandler(url, 100)  // success
            } else {
                completionHandler(url, 102)  // cannot find archived page
            }
        } else {
            completionHandler(nil, 102)  // cannot find archived page
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
        var originalURL = url
        let tempArray = url.components(separatedBy: "http")
        if (tempArray.count > 2) {
            originalURL = "http" + tempArray[2]
        }
        return originalURL
    }
    
    func getURL(url: String) -> String {
        var retUrl = url
        if ((url.range(of: "http:") == nil) && (url.range(of: "https:") == nil)) {
            retUrl = "https://" + url
        }
        return retUrl
    }
    
    func showProgress() -> Void {
        self.progressHUD?.show(animated: true)
    }
    
    @objc func hideProgress(_ result: Any) -> Void {
        self.progressHUD?.hide(animated: true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
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
