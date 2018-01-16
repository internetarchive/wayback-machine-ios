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
    let WEB_LOGIN_URL           = "https://archive.org/account/login.php"
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
    // PUT
    // DELETE
    // POST
    private func SendDataToService(params: [String: Any], operation: String, completion: @escaping ([String: Any]?) -> Void) {
        
        var parameters          = params
        parameters["access"]    = ACCESS
        parameters["secret"]    = SECRET
        parameters["version"]   = VERSION
        
        Alamofire.request(BASE_URL + operation, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: HEADERS).validate(contentType: ["application/json"]).responseJSON{ (response) in
            
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
    
    private func SendDataToSparkLine(params: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        Alamofire.request(SPARKLINE_URL, method: .get, parameters: params, encoding: URLEncoding.default, headers: HEADERS).validate(contentType: ["application/json"]).responseJSON{ (response) in
            
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
}
