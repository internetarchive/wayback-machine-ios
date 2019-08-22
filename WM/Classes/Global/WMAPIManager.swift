//
//  WMAPIManager.swift
//  WM
//
//  Created by mac-admin on 8/23/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import Foundation
import Alamofire

class WMAPIManager: NSObject {
    static let sharedManager    = WMAPIManager()
    
    let BASE_URL                = "https://archive.org/services/xauthn/"
    let SPARKLINE_URL           = "https://web.archive.org/__wb/sparkline"
    let MY_WEB_ARCHIVE_URL      = "https://web.archive.org/__wb/web-archive/"
    let WEB_LOGIN_URL           = "https://archive.org/account/login.php"
    let UPLOAD_BASE_URL         = "https://s3.us.archive.org"
    let SPN2_URL                = "https://web-beta.archive.org/save/"
    let API_CREATE              = "?op=create"
    let API_LOGIN               = "?op=authenticate"
    let API_INFO                = "?op=info"
    
    let ACCESS                  = "trS8dVjP8dzaE296"
    let SECRET                  = "ICXDO78cnzUlPAt1"
    let VERSION                 = 1
    let HEADERS                 = [
        "User-Agent": "Wayback_Machine_iOS/\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!)",
        "Wayback-Extension-Version": "Wayback_Machine_iOS/\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!)"
    ]
    
    // GET
    private func SendDataToSparkLine(params: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        Alamofire.request(SPARKLINE_URL, method: .get, parameters: params, headers: HEADERS).responseJSON{ (response) in
            
            switch response.result {
            case .success:
                if let json = response.result.value {
                    completion(json as? [String: Any])
                }
            case .failure:
                completion(nil)
            }
        }
    }
    
    // PUT
    // DELETE
    // POST
    private func SendDataToService(params: [String: Any], operation: String, completion: @escaping ([String: Any]?) -> Void) {
        
        var parameters          = params
        parameters["access"]    = ACCESS
        parameters["secret"]    = SECRET
        parameters["version"]   = VERSION
        
        Alamofire.request(BASE_URL + operation, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: HEADERS).responseJSON { (response) in

            switch response.result {
            case .success:
                if let json = response.result.value {
                    completion(json as? [String: Any])
                }
            case .failure:
                completion(nil)

            }
        }
    }
    
    // Register new Account
    func registerAccount(params: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: params, operation: API_CREATE, completion: completion)
    }
    
    // Login
    func login(email: String, password: String, completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: [
            "email"     : email,
            "password"  : password
        ], operation: API_LOGIN, completion: completion)
    }
    
    // Get Account Info
    func getAccountInfo(email: String, completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: ["email": email], operation: API_INFO, completion: completion)
    }
    
    func getCookieData(email: String, password: String, completion: @escaping([String: Any]) -> Void) {
        
        var params = [String: Any]()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"
        
        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.version: 0,
            HTTPCookiePropertyKey.name: "test-cookie",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: "1",
            HTTPCookiePropertyKey.domain: ".archive.org",
            HTTPCookiePropertyKey.secure: false,
            HTTPCookiePropertyKey.expires: NSDate(timeIntervalSinceNow: 86400 * 20)
        ]
        
        if let cookie = HTTPCookie(properties: cookieProps) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
        
        var cookieData = [String: Any]()
        
        Alamofire.request(WEB_LOGIN_URL, method: .post, parameters: params, encoding: URLEncoding.default, headers: ["Content-Type": "application/x-www-form-urlencoded"]).responseString{ (response) in
            
            switch response.result {
                case .success:
                    if let cookies = HTTPCookieStorage.shared.cookies {
                        for cookie in cookies {
                            if cookie.name == "logged-in-sig" {
                                cookieData["logged-in-sig"] = cookie
                            } else if cookie.name == "logged-in-user" {
                                cookieData["logged-in-user"] = cookie
                            }
                        }
                    }
                    
                    completion(cookieData)
                case .failure:
                    completion(cookieData)
                
            }
        }
    }
    
    // Check if a URL is Blocked
    func checkURLBlocked(url: String, completion: @escaping (Bool) -> Void) {
        SendDataToSparkLine(params: [
            "url"     : url,
            "output"  : "json"
        ]) { (response) in
            guard let response = response else {
                completion(false)
                return
            }
            
            guard let error = response["error"] as? [String: Any] else {
                completion(false)
                return
            }
            
            if let type = error["type"] as? String, type.lowercased() == "blocked" {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func getIAS3Keys(params: [String: String], completion: @escaping([String: String]?) -> Void) {
        let cookiePropsLoggedInSig: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.name: "logged-in-sig",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: params["logged-in-sig"]!,
            HTTPCookiePropertyKey.domain: ".archive.org"
        ]
        let cookiePropsLoggedInUser: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.name: "logged-in-user",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: params["logged-in-user"]!,
            HTTPCookiePropertyKey.domain: ".archive.org"
        ]

        if let cookieLoggedInSig = HTTPCookie(properties: cookiePropsLoggedInSig),
            let cookieLoggedInUser = HTTPCookie(properties: cookiePropsLoggedInUser){
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookieLoggedInSig)
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookieLoggedInUser)
        }
        
        Alamofire.request("https://archive.org/account/s3.php?output_json=1", method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseJSON{ (response) in
            
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any], let key = json["key"] as? [String: Any]{
                    completion(key as? [String : String])
                } else {
                    completion(nil)
                }
            case .failure:
                completion(nil)
            }
        }
    }
    
    func saveToMyWebArchive(url: String, snapshot: String, logged_in_user: HTTPCookie, logged_in_sig: HTTPCookie, completion: @escaping (Bool) -> Void) {
    
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_user)
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_sig)
        
        let param = [
            "url" : url,
            "snapshot" : snapshot,
            "tags" : []
            ] as [String : Any]
        
        var headers = ["Content-Type": "application/json"]
        
        for (key, value) in HEADERS {
            headers[key] = value
        }
        
        Alamofire.request(MY_WEB_ARCHIVE_URL, method: .post,
                          parameters: param,
                          encoding: JSONEncoding.default,
                          headers: headers).responseJSON{ (response) in
            
            switch response.result {
            case .success( _):
                if let json = response.result.value as? [String: Any],
                    let success = json["success"] as? Bool {
                    completion(success)
                } else {
                    completion(false)
                }
            case .failure( _):
                completion(false)
            }
        }
    }
    
    func SendDataToBucket(params: [String: Any?], completion: @escaping (Bool, Int64) -> Void) {
        let identifier = params["identifier"] as! String
        let title      = params["title"] as! String
        let description = params["description"] as! String
        let subjectTags = params["tags"] as! String
        let filename   = params["filename"] as! String
        let mediatype  = params["mediatype"] as! String
        let s3accesskey = params["s3accesskey"] as! String
        let s3secretkey = params["s3secretkey"] as! String
        var uploaded: Int64 = 0
        
        var headers = [
            "X-File-Name": filename,
            "x-amz-acl": "bucket-owner-full-control",
            "x-amz-auto-make-bucket": "1",
            "x-archive-meta-collection": "opensource_media",
            "x-archive-meta-mediatype": mediatype,
            "x-archive-meta-title": title,
            "x-archive-meta-description": description,
            "x-archive-meta-subject": subjectTags,
            "authorization": String(format: "LOW %@:%@", s3accesskey, s3secretkey)
        ]
        
        for (key, value) in HEADERS {
            headers[key] = value
        }
        
        let url = String(format: "%@/%@/%@", self.UPLOAD_BASE_URL, identifier, filename)
        
        var uploadRequest: UploadRequest?
        
        if let fileData = params["data"] as? Data {
            uploadRequest = Alamofire.upload(fileData, to: url, method: .put, headers: headers)
        } else if let fileData = params["data"] as? URL {
            uploadRequest = Alamofire.upload(fileData, to: url, method: .put, headers: headers)
        } else {
            print("Error Print", "Cannot read File Data")
            completion(false, uploaded)
        }

        uploadRequest!
            .uploadProgress {(progress) in
                uploaded = progress.completedUnitCount
                let total = progress.totalUnitCount
                var estimateTime: TimeInterval?
                if #available(iOS 11.0, *) {
                    estimateTime = progress.estimatedTimeRemaining
                }
                print(String(format: "upload: %d, total: %d, time: %d",uploaded, total, estimateTime ?? 0))
            }
            .responseData(completionHandler: { (result) in
                switch result.result {
                case .success( _):
                    completion(true, uploaded)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(false, uploaded)
                    break
                }
            })
    }
    
    func request_capture(url: String, logged_in_user: HTTPCookie, logged_in_sig: HTTPCookie, completion: @escaping (String?) -> Void) {
        
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_user)
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_sig)
        
        let param = ["url" : url]
        var headers = ["Accept": "application/json"]
        
        for (key, value) in HEADERS {
            headers[key] = value
        }
        
        Alamofire.request(SPN2_URL, method: .post,
                          parameters: param,
                          headers: headers)
            .responseJSON{ (response) in
                            
                switch response.result {
                case .success(let data):
                    if let json = response.result.value as? [String: Any],
                        let job_id = json["job_id"] as? String {
                        completion(job_id)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil)
            }
        }
    }
    
    func request_capture_status(job_id: String, logged_in_user: HTTPCookie, logged_in_sig: HTTPCookie, completion: @escaping (String?, String?) -> Void) {
        
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_user)
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_sig)
        
        let param = ["job_id" : job_id]
        var headers = ["Accept": "application/json"]
        
        for (key, value) in HEADERS {
            headers[key] = value
        }
        
        Alamofire.request("\(SPN2_URL)status/", method: .post,
                          parameters: param,
                          headers: headers)
            .responseJSON{ (response) in
                
                switch response.result {
                case .success(let data):
                    if let json = response.result.value as? [String: Any],
                        let status = json["status"] as? String {
                        
                        if status == "pending" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                self.request_capture_status(job_id: job_id, logged_in_user: logged_in_user, logged_in_sig: logged_in_sig, completion: completion)
                            })
                        } else {
                            if let timestamp = json["timestamp"] as? String,
                                let original_url = json["original_url"] as? String {
                                completion("http://web.archive.org/web/\(timestamp)/\(original_url)", nil)
                            } else if let errorMessage = json["message"] as? String {
                                completion(nil, errorMessage)
                            } else {
                                completion(nil, json["status"] as? String)
                            }
                        }
                    } else {
                        completion(nil, "Error serializing JSON: \(String(describing: response.result.value))")
                    }
                case .failure(let error):
                    completion(nil, error.localizedDescription)
                }
        }
    }
    
}
