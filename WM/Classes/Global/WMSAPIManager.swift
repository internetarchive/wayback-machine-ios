//
//  WMSAPIManager.swift
//  Wayback Machine Shared
//
//  Created by Carl on 1/28/20.
//
//  This code is meant to be shared across the Safari Extension, iOS, and TV apps.
//  Any modifications should be synced across apps.
//
// TODO:
// This code really should be rewritten so that the auth keys
// are stored within this class and not passed in methods calls from outside.

import Foundation
import Alamofire

/// # Globals Used #
/// - APP_VERSION
/// - DEBUG_LOG

class WMSAPIManager {
    static let shared = WMSAPIManager()

    // options
    public enum CaptureOption {
        case allErrors, outlinks, screenshot, availability, emailOutlinks
    }
    public typealias CaptureOptions = [CaptureOption]

    // MARK: - API Constants

    // keep base URLs as vars to support testing
    #if os(macOS)
    static var API_BASE_URL        = "https://safari-api.archive.org"
    #elseif os(iOS)
    static var API_BASE_URL        = "https://web.archive.org"  // TODO: ios-app.archive.org NOT assigned yet?
    #elseif os(tvOS)
    #endif
    static let API_SPN2_SAVE       = "/save/"
    static let API_SPN2_STATUS     = "/save/status/"
    static let API_SPARKLINE       = "/__wb/sparkline" // SPARKLINE_URL
    static let API_MY_WEB_ARCHIVE  = "/__wb/web-archive/" // MY_WEB_ARCHIVE_URL
    static let API_AVAILABILITY    = "/wayback/available"
    static let API_CDX_SEARCH      = "/cdx/search/cdx"

    static var WM_BASE_URL         = "https://web.archive.org"
    static let WM_OLDEST           = "/web/0/"
    static let WM_NEWEST           = "/web/2/"
    static let WM_OVERVIEW         = "/web/*/"

    static var IA_BASE_URL         = "https://archive.org" // WEB_BASE_URL
    static let IA_LOGIN            = "/account/login"
    static let IA_S3KEYS           = "/account/s3.php?output_json=1"
    static let IA_RESET_PW         = "/account/forgot-password"

    static var UPLOAD_BASE_URL     = "https://s3.us.archive.org"

    // Xauthn Authentication Service
    // these ACCESS & SECRET keys still required
    static var XA_BASE_URL         = "https://archive.org/services/xauthn/" // BASE_URL
    static let XA_ACCESS           = "trS8dVjP8dzaE296"
    static let XA_SECRET           = "ICXDO78cnzUlPAt1"
    static let XA_VERSION          = 1
    public enum XAuthOperation {
        case info, authenticate, identify, create, chkprivs, login
    }
    static let XA_OPS: [XAuthOperation: String] = [
        .info: "?op=info",
        .authenticate: "?op=authenticate",
        .identify: "?op=identify",
        .create: "?op=create",
        .chkprivs: "?op=chkprivs",
        .login: "?op=login"
    ]

    /// update headers to reflect different apps
    #if os(macOS)
    static let HEADERS: HTTPHeaders = [
        "User-Agent": "Wayback_Machine_Safari_XC/\(APP_VERSION)",
        "Wayback-Extension-Version": "Wayback_Machine_Safari_XC/\(APP_VERSION)",
        "Wayback-Api-Version": "2"
    ]
    #elseif os(iOS)
    static let HEADERS: HTTPHeaders = [
        "User-Agent": "Wayback_Machine_iOS/\(APP_VERSION)",
        "Wayback-Extension-Version": "Wayback_Machine_iOS/\(APP_VERSION)",
        "Wayback-Api-Version": "2"
    ]
    #elseif os(tvOS)
    #endif

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Helper Functions

    // WAS: func isValidSnapshotUrl(url: String?) -> Bool
    /// Returns true if `url` is a valid website URL, i.e. it begins with `http(s)://`.
    func isValidWebURL(_ url: String?) -> Bool {
        guard let url = url else { return false }
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }

    // WAS: func getURL(url: String) -> String
    /// Given a `url` string, prepends `https://` if `http(s)://` isn't present.
    func fullWebURL(_ url: String) -> String {
        return isValidWebURL(url) ? url : "https://\(url)"
    }

    /// Sets a temporary cookie for the archive.org domain and its sub-domains.
    func setArchiveCookie(name: String, value: String) {
        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.name: name,
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.domain: ".archive.org",
            HTTPCookiePropertyKey.secure: true,
            HTTPCookiePropertyKey.discard: true
        ]
        if let cookie = HTTPCookie(properties: cookieProps) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
    }

    /// Return percent-encoded string for any character that is not allowed in a URL path or is non-alphanumeric.
    /// Also trims whitespace from both ends.
    func uriEncode(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cs = CharacterSet.urlPathAllowed.intersection(.alphanumerics)
        return trimmed?.addingPercentEncoding(withAllowedCharacters: cs)
    }

    
    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - API Wrappers

    func SendDataToSparkLine(params: Parameters, completion: @escaping ([String: Any]?) -> Void) {

        Alamofire.request(WMSAPIManager.API_BASE_URL + WMSAPIManager.API_SPARKLINE,
                          method: .get, parameters: params, headers: WMSAPIManager.HEADERS)
            .responseJSON { (response) in
            
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
    
    // WAS: SendDataToService(params: [String: Any], operation: String, completion: @escaping ([String: Any]?) -> Void) {
    /// Xauthn Authentication Service
    /// This API will use Cookies before using S3 credentials.
    ///
    func SendDataToService(params: Parameters, operation: XAuthOperation,
                           loggedInUser: String? = nil, loggedInSig: String? = nil,
                           accessKey: String? = nil, secretKey: String? = nil,
                           completion: @escaping ([String: Any]?) -> Void)
    {
        guard let opPath = WMSAPIManager.XA_OPS[operation] else { return }
        let url = WMSAPIManager.XA_BASE_URL + opPath

        // TEST TO REMOVE
        if (DEBUG_LOG) { NSLog("*** SendDataToService() url: \(url)") }
        if (DEBUG_LOG) { NSLog("***   loggedInUser: \(String(describing: loggedInUser))") }
        if (DEBUG_LOG) { NSLog("***   loggedInSig: \(String(describing: loggedInSig))") }
        if (DEBUG_LOG) { NSLog("***   accessKey: \(String(describing: accessKey))") }
        if (DEBUG_LOG) { NSLog("***   secretKey: \(String(describing: secretKey))") }

        // clear existing cookies
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.removeCookies(since: Date.distantPast)

        // prepare cookies
        if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
            setArchiveCookie(name: "logged-in-user", value: loggedInUser)
            setArchiveCookie(name: "logged-in-sig", value: loggedInSig)
        }

        // prepare request
        var parameters = params
        parameters["version"]   = WMSAPIManager.XA_VERSION
        parameters["access"] = WMSAPIManager.XA_ACCESS // accessKey
        parameters["secret"] = WMSAPIManager.XA_SECRET // secretKey
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        if let accessKey = accessKey, let secretKey = secretKey {
            headers["Authorization"] = "LOW \(accessKey):\(secretKey)" // don't know if this does anything
        }

        // TEST TO REMOVE
        if (DEBUG_LOG) { NSLog("***   headers: \(headers)") }
        if (DEBUG_LOG) { NSLog("***   params: \(parameters)") }

        let req = Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { (response) in

            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any] {
                    if (DEBUG_LOG) { NSLog("*** SendDataToService() json: \(json)") } // DEBUG TEST
                    completion(json)
                }
            case .failure:
                if (DEBUG_LOG) { NSLog("*** SendDataToService() FAILED") }
                completion(nil)
            }
        }
        if (DEBUG_LOG) { NSLog("***   curl: \(req.debugDescription)") }
    }

    
    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - User Account API

    /// Main Login that uses a 2-step API call to retrieve the S3 keys given a user's email and password.
    /// - parameter email: User's email.
    /// - parameter password: User's password.
    /// - parameter completion: Returns a Dictionary to pass to saveUserData(), else nil if failed.
    /// - returns: *Keys*:
    ///   email, logged-in-user, logged-in-sig, s3accesskey, s3secretkey
    ///
    // TODO: needs to return a better error response instead of just nil.
    func login(email: String, password: String, completion: @escaping ([String: Any?]?) -> Void) {

        webLogin(email: email, password: password) {
            (loggedInUser, loggedInSig) in

            if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
                self.getIAS3Keys(loggedInUser: loggedInUser, loggedInSig: loggedInSig) {
                    (accessKey, secretKey) in

                    if let accessKey = accessKey, let secretKey = secretKey {
                        // success
                        let data: [String: Any?] = [
                            // password not stored
                            "email"          : email,
                            "logged-in-user" : loggedInUser,
                            "logged-in-sig"  : loggedInSig,
                            "s3accesskey"    : accessKey,
                            "s3secretkey"    : secretKey,
                            "logged-in"      : true
                        ]
                        completion(data)
                    } else {
                        // failed to get the S3 keys
                        if (DEBUG_LOG) { NSLog("*** login() FAILED 1: failed to get S3 keys") }
                        completion(nil)
                    }
                }
            } else {
                // couldn't log in
                if (DEBUG_LOG) { NSLog("*** login() FAILED 2: couldn't log in") }
                completion(nil)
            }
        }
    }

    /// Logout returns userData[] with key fields cleared, and `logged-in` set to false. Also clears cookies.
    ///
    func logout(userData: [String: Any?]?) -> [String: Any?]? {

        // clear cookies
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.removeCookies(since: Date.distantPast)
        if var udata = userData {
            udata["email"] = nil
            udata["password"] = nil
            udata["screenname"] = nil
            udata["logged-in-user"] = nil
            udata["logged-in-sig"] = nil
            udata["s3accesskey"] = nil
            udata["s3secretkey"] = nil
            udata["logged-in"] = false
            return udata
        }
        return nil
    }

    // WAS: login()
    /// Login using a single API call to retrieve the S3 keys given a user's email and password.
    /// - parameter email: User's email.
    /// - parameter password: User's password.
    /// - parameter completion: Returns a Dictionary to pass to saveUserData(), else nil if failed.
    /// - returns: *Keys*:
    ///   email, s3accesskey, s3secretkey, logged-in
    ///
    func authLogin(email: String, password: String, completion: @escaping ([String: Any?]?) -> Void) {

        let params: Parameters = [
            "email"     : email,
            "password"  : password
        ]

        SendDataToService(params: params, operation: .authenticate) {
            (json) in
            // success as Bool, values as dict, error as String, version as Int

            if let json = json {
                if (DEBUG_LOG) { NSLog("*** authLogin() json: \(json)") } // TEST
                if json["success"] as? Bool ?? false,
                   let values = json["values"] as? [String: Any],
                   let accessKey = values["access"] as? String,
                   let secretKey = values["secret"] as? String
                {
                    // success
                    let userData: [String: Any?] = [
                        // password not stored
                        "email"          : email,
                        "s3accesskey"    : accessKey,
                        "s3secretkey"    : secretKey,
                        "logged-in"      : true
                    ]
                    completion(userData)
                } else {
                    let errMsg = json["error"] as? String ?? "null"
                    if (DEBUG_LOG) { NSLog("*** authLogin() FAILED 1: \(errMsg)") }
                    completion(nil)
                    // TODO: return error msg
                }
            } else {
                // unknown error
                if (DEBUG_LOG) { NSLog("*** authLogin() FAILED 2: Unknown Error") }
                completion(nil)
            }
        }
    }
    
    /// Login using the web login form, which returns cookie strings that may be used
    /// for short-term auth. For longer-term, retrieve the A3 keys using getIAS3Keys().
    /// See login().
    ///
    func webLogin(email: String, password: String,
                  completion: @escaping (_ loggedInUser: String?, _ loggedInSig: String?) -> Void) {

        // prepare cookie to avoid glitch where login doesn't work half the time.
        setArchiveCookie(name: "test-cookie", value: "1")

        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        var params = Parameters()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"

        // make login request
        Alamofire.request(WMSAPIManager.IA_BASE_URL + WMSAPIManager.IA_LOGIN,
                          method: .post, parameters: params, headers: headers)
        .responseString { (response) in

            switch response.result {
            case .success:
                var ck = [String: String]()
                if let cookies = HTTPCookieStorage.shared.cookies {
                    for cookie in cookies {
                        ck[cookie.name] = cookie.value
                    }
                }
                completion(ck["logged-in-user"], ck["logged-in-sig"])

            case .failure:
                completion(nil, nil)
            }
        }
    }

    // TODO: convert any calls to this to what follows...
    // func getIAS3Keys(params: [String: String], completion: @escaping([String: String]?) -> Void) {
    // input params: dictionary with keys "logged-in-user" & "logged-in-sig".
    // returns: dictionary with all keys returned, which should include "s3accesskey" & "s3secretkey".

    /// Get the S3 account keys for long-term API access. Pass in cookie strings returned by webLogin().
    ///
    func getIAS3Keys(loggedInUser: String, loggedInSig: String,
                     completion: @escaping (_ accessKey: String?, _ secretKey: String?) -> Void) {

        // prepare cookies
        setArchiveCookie(name: "logged-in-user", value: loggedInUser)
        setArchiveCookie(name: "logged-in-sig", value: loggedInSig)

        // make request
        Alamofire.request(WMSAPIManager.IA_BASE_URL + WMSAPIManager.IA_S3KEYS,
                          method: .get, parameters: nil, headers: WMSAPIManager.HEADERS)
        .responseJSON { (response) in

            // API Response:
            // {"success":1,"key":{"s3accesskey":"...","s3secretkey":"..."}}
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any],
                    let key = json["key"] as? [String: String] {
                    completion(key["s3accesskey"], key["s3secretkey"])
                } else {
                    completion(nil, nil)
                }
            case .failure:
                completion(nil, nil)
            }
        }
    }

    // TODO: REDO
    /// Register new Account.
    /// - parameter params: Requires keys "verified" (should be set false), "email", "password", and "screenname".
    /// - parameter completion: Callback returns dictionary of json results, or nil if failed.
    ///
    func registerAccount(params: Parameters, completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: params, operation: .create, completion: completion)
    }

    // TODO: REDO?
    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {

        let params = [
            "email": email,
            "action": "Send Reset Password Email"
        ]
        Alamofire.request(WMSAPIManager.IA_BASE_URL + WMSAPIManager.IA_RESET_PW, method: .post, parameters: params)
        .responseString{ (response) in
            switch response.result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
    
    // Get Account Info
    // Get additional info such as user's screenname.
    func getAccountInfo(email: String,
                        loggedInUser: String? = nil, loggedInSig: String? = nil,
                        accessKey: String? = nil, secretKey: String? = nil,
                        completion: @escaping ([String: Any]?) -> Void) {

        let params: Parameters = ["email": email]

        SendDataToService(params: params, operation: .info, loggedInUser: loggedInUser, loggedInSig: loggedInSig, accessKey: accessKey, secretKey: secretKey) {
            (json) in
            if let json = json {
                if (DEBUG_LOG) { NSLog("*** getAccountInfo() json: \(json)") } // TEST
                if json["success"] as? Bool ?? false, let values = json["values"] as? [String: Any] {
                    // success
                    completion(values)
                } else {
                    let errMsg = json["error"] as? String ?? "null"
                    if (DEBUG_LOG) { NSLog("*** getAccountInfo() FAILED 1: \(errMsg)") }
                    completion(nil)
                    // TODO: return error msg
                }
            } else {
                // unknown error
                if (DEBUG_LOG) { NSLog("*** getAccountInfo() FAILED 2") }
                completion(nil)
            }
        }
    }

    func getScreenName(email: String,
                       loggedInUser: String? = nil, loggedInSig: String? = nil,
                       accessKey: String? = nil, secretKey: String? = nil,
                       completion: @escaping (String?) -> Void) {

        getAccountInfo(email: email, loggedInUser: loggedInUser, loggedInSig: loggedInSig,
                       accessKey: accessKey, secretKey: secretKey) { (values) in
            if let values = values, let screenname = values["screenname"] as? String {
                if (DEBUG_LOG) { NSLog("*** getScreenName() returns: \(screenname)") }
                completion(screenname)
            } else {
                if (DEBUG_LOG) { NSLog("*** getScreenName() FAILED") }
                completion(nil)
            }
        }
    }


    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Wayback API

    // WAS: func wmAvailabilityCheck(url: String, completion: @escaping (String?, String?) -> Void)
    /// Checks Wayback Machine if given `url` has been archived.
    /// - parameter url: The URL to check.
    /// - parameter completion: Callback function.
    /// - parameter waybackURL: The URL as stored in the Wayback Machine, else `nil` if error or no response.
    /// - parameter originalURL: The original URL passed in.
    ///
    func checkAvailability(url: String, completion: @escaping (_ waybackURL: String?, _ originalURL: String) -> Void) {
        if (DEBUG_LOG) { NSLog("*** checkAvailability() url: \(url)") }

        // prepare request
        let requestParams = "url=\(url)"
        var request = URLRequest(url: URL(string: WMSAPIManager.API_BASE_URL + WMSAPIManager.API_AVAILABILITY)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        for (key, value) in WMSAPIManager.HEADERS {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = requestParams.data(using: .utf8)

        // make request
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in

            guard let data = data, error == nil else { return }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                completion(self.extractWaybackURL(from: json), url)
            } catch _ {
                completion(nil, url)
            }
        }
        task.resume()
    }

    // WAS: func getWaybackUrlFromResponse(response: [String: Any]) -> String?
    /// Grabs the wayback URL string out of the JSON response object from checkAvailability().
    /// - parameter json: from JSONSerialization.jsonObject()
    /// - returns: Wayback URL as String, or nil if not available, invalid, or status != 200.
    ///
    /// # API response JSON format: #
    /// ```
    /// "results" : [ { "archived_snapshots": {
    ///   "closest": { "available": true, "status": "200", "url": "http:..." }
    /// } } ]
    /// ```
    func extractWaybackURL(from json: [String: Any]?) -> String? {

        if let results = json?["results"] as? [[String: Any]],
            let archived_snapshots = results.first?["archived_snapshots"] as? [String: Any],
            let closest = archived_snapshots["closest"] as? [String: Any],
            let available = closest["available"] as? Bool,
            let status = closest["status"] as? String,
            let url = closest["url"] as? String,
            available == true,
            status == "200",
            isValidWebURL(url)
        {
            return url
        }
       return nil
    }

    /// Retrieves total count of snapshots stored in the Wayback Machine for given `url`.
    /// - parameter url: The URL to check.
    ///
    func getWaybackCount(url: String, completion: @escaping (_ originalURL: String, _ count: Int?,
                                                             _ firstDate: Date?, _ lastDate: Date?) -> Void) {
        if (DEBUG_LOG) { NSLog("*** getWaybackCount() url: \(url)") }

        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        var params = Parameters()
        params["url"] = url
        params["collection"] = "web"
        params["output"] = "json"

        // make request
        // http://web.archive.org/__wb/sparkline?url=URL&collection=web&output=json
        Alamofire.request(WMSAPIManager.API_BASE_URL + WMSAPIManager.API_SPARKLINE,
                          method: .get, parameters: params, headers: headers)
        .responseJSON { (response) in
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any],
                    let years = json["years"] as? [String: [Int]]
                {
                    // get total count
                    var totalCount = 0
                    for year in years {
                        for monthCount in year.value {
                            totalCount += monthCount
                        }
                    }
                    // get timestamps
                    var firstDate: Date? = nil, lastDate: Date? = nil
                    if totalCount > 0 {
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "en_US_POSIX")
                        df.dateFormat = "yyyyMMddHHmmss"
                        df.timeZone = TimeZone(secondsFromGMT: 0)
                        if let firstStr = json["first_ts"] as? String {
                            firstDate = df.date(from: firstStr)
                        }
                        if let lastStr = json["last_ts"] as? String {
                            lastDate = df.date(from: lastStr)
                        }
                    }
                    completion(url, totalCount, firstDate, lastDate)
                } else {
                    completion(url, 0, nil, nil)
                }
            case .failure(let error):
                NSLog("*** ERROR: %@", error.localizedDescription)
                completion(url, nil, nil, nil)
            }
        }
    }

    /// Retrieves data for the Site Map graph.
    func getSiteMapData(url: String, completion: @escaping (_ data: [Any]?) -> Void) {

        // TODO: need to check/encode url?
        let apiURL = WMSAPIManager.API_BASE_URL + WMSAPIManager.API_CDX_SEARCH + "?url=\(url)/&fl=timestamp,original&matchType=prefix&filter=statuscode:200&filter=mimetype:text/html&output=json"

        /* TODO: later
        // prepare request
        var params = Parameters()
        params["url"] = url
        params["fl"] = "timestamp,original"
        params["matchType"] = "prefix"
        //params["filter"] = "statuscode:200"  // need to handle multiple values for same key
        //params["filter"] = "mimetype:text/html"
        params["output"] = "json"
        // */

        // make request
        Alamofire.request(apiURL, method: .get, headers: WMSAPIManager.HEADERS)
        .responseJSON { (response) in
            switch response.result {
            case .success(let data):
                //if let json = response.result.value as? [String: Any]  // ??
                completion(data as? [Any])
            case .failure(let error):
                NSLog("*** ERROR: %@", error.localizedDescription)
                completion(nil)
            }
        }
    }

    // TODO: TEST
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


    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Save Page Now API (SPN2)

    // WAS: requestCapture(...)
    /// Requests Wayback Machine to save the given webpage.
    /// Provide `loggedInUser` & `loggedInSig` to use cookie auth.
    /// Or `accessKey` & `secretKey` to use S3 auth. Must pick one or the other.
    /// - parameter url: Can be a full or partial URL with or without the http(s).
    /// - parameter loggedInUser: Cookie string for short-term auth.
    /// - parameter loggedInSig: Cookie string for short-term auth.
    /// - parameter accessKey: String for long-term S3 auth.
    /// - parameter secretKey: String for long-term S3 auth.
    /// - parameter options: See enum & API docs for options.
    /// - parameter completion:
    /// - parameter jobId: Returns a job ID to pass to getPageStatus() for status updates.
    ///
    func capturePage(url: String,
                     loggedInUser: String? = nil, loggedInSig: String? = nil,
                     accessKey: String? = nil, secretKey: String? = nil,
                     options: CaptureOptions = [],
                     completion: @escaping (_ jobId: String?, _ error: Error?) -> Void)
    {
        // prepare cookies
        if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
            setArchiveCookie(name: "logged-in-user", value: loggedInUser)
            setArchiveCookie(name: "logged-in-sig", value: loggedInSig)
        }
        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        if let accessKey = accessKey, let secretKey = secretKey {
            headers["Authorization"] = "LOW \(accessKey):\(secretKey)"
        }
        var params = Parameters()
        params["url"] = url
        if options.contains(.allErrors)  { params["capture_all"] = "1" }  // page with errors (status=4xx or 5xx)
        if options.contains(.outlinks)   { params["capture_outlinks"] = "1" }  // web page outlinks
        if options.contains(.screenshot) { params["capture_screenshot"] = "1" }  // full page screenshot as PNG
        if options.contains(.emailOutlinks) { params["email_result"] = "1" }

        // make request
        let req = Alamofire.request(WMSAPIManager.API_BASE_URL + WMSAPIManager.API_SPN2_SAVE,
                          method: .post, parameters: params, headers: headers)
        .responseJSON { (response) in

            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any],
                    let job_id = json["job_id"] as? String {
                    completion(job_id, nil)
                } else {
                    completion(nil, nil)
                }
            case .failure(let error):
                NSLog("*** ERROR: %@", error.localizedDescription)
                completion(nil, error)
            }
        }
        if (DEBUG_LOG) { NSLog("*** capturePage() curl: \(req.debugDescription)") }
    }

    /// Use to retrieve status of saving a page in the Wayback Machine.
    /// Provide `loggedInUser` & `loggedInSig` to use cookie auth.
    /// Or `accessKey` & `secretKey` to use S3 auth. Must pick one or the other.
    /// - parameter jobId: ID from capturePage().
    /// - parameter loggedInUser: Cookie string for short-term auth.
    /// - parameter loggedInSig: Cookie string for short-term auth.
    /// - parameter accessKey: String for long-term S3 auth.
    /// - parameter secretKey: String for long-term S3 auth.
    /// - parameter options: Normally leave off.
    /// - parameter pending:
    /// - parameter resources: Array of Strings of URLs that the Wayback Machine archived.
    /// - parameter completion:
    /// - parameter archiveURL: URL of archived website on the Wayback Machine, or `nil` if error.
    /// - parameter errMsg: Error message as String.
    ///
    func getPageStatus(jobId: String,
                       loggedInUser: String? = nil, loggedInSig: String? = nil,
                       accessKey: String? = nil, secretKey: String? = nil,
                       options: CaptureOptions = [],
                       pending: @escaping (_ resources: [String]?) -> Void = {_ in },
                       completion: @escaping (_ archiveURL: String?, _ errMsg: String?, _ resultJSON: [String: Any]? ) -> Void)
    {
        if (DEBUG_LOG) { NSLog("*** getPageStatus()") }

        // prepare cookies
        if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
            setArchiveCookie(name: "logged-in-user", value: loggedInUser)
            setArchiveCookie(name: "logged-in-sig", value: loggedInSig)
        }
        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        if let accessKey = accessKey, let secretKey = secretKey {
            headers["Authorization"] = "LOW \(accessKey):\(secretKey)"
        }
        var params = Parameters()
        params["job_id"] = jobId
        if options.contains(.availability) { params["outlinks_availability"] = "1" }  // outlinks contain timestamps (NOT USED)

        // TODO: return custom Error objects?

        // make request
        Alamofire.request(WMSAPIManager.API_BASE_URL + WMSAPIManager.API_SPN2_STATUS,
                          method: .post, parameters: params, headers: headers)
        .responseJSON { (response) in
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any],
                    let status = json["status"] as? String {
                    // status is one of {"success", "pending", "error"}
                    if (DEBUG_LOG) { NSLog("*** SPN2 Status: \(status)") }
                    if status == "pending" {
                        pending(json["resources"] as? [String])
                        // TODO: May need to allow for cancel or timeout.
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            self.getPageStatus(jobId: jobId, loggedInUser: loggedInUser, loggedInSig: loggedInSig,
                                               accessKey: accessKey, secretKey: secretKey, options: options,
                                               pending: pending, completion: completion)
                        }
                    } else if status == "success" {
                        if let timestamp = json["timestamp"] as? String,
                            let originalUrl = json["original_url"] as? String {
                            let archiveUrl = WMSAPIManager.WM_BASE_URL + "/web/\(timestamp)/\(originalUrl)"
                            completion(archiveUrl, nil, json)
                        } else {
                            completion(nil, "Unknown Status Error 1", json)
                        }
                    } else if status == "error" {
                        let message = json["message"] as? String ?? "Unknown Status Error 2"
                        completion(nil, message, json)
                    } else {
                        completion(nil, "Unknown Status Error 3 (\(status))", json)
                    }
                } else {
                    completion(nil, "Error serializing JSON: \(String(describing: response.result.value))", nil)
                }

            case .failure(let error):
                // Sometimes we get "The request timed out".
                // This error really should be fixed on the server API end.
                if (DEBUG_LOG) { NSLog("*** getPageStatus(): request failure: " + error.localizedDescription) }
                completion(nil, error.localizedDescription, nil)
            }
        }
    }


    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - More APIs

    /// Saves a url to user's "My Web Archive".
    /// Provide `loggedInUser` & `loggedInSig` to use cookie auth.
    /// Or `accessKey` & `secretKey` to use S3 auth. Must pick one or the other.
    /// - parameter url
    /// - parameter snapshot
    /// - parameter loggedInUser: Cookie string for short-term auth.
    /// - parameter loggedInSig: Cookie string for short-term auth.
    /// - parameter accessKey: String for long-term S3 auth.
    /// - parameter secretKey: String for long-term S3 auth.
    /// - parameter completion:
    /// - parameter isSuccess: Bool true if successful.
    ///
    func saveToMyWebArchive(url: String, snapshot: String,
                            loggedInUser: String? = nil, loggedInSig: String? = nil,
                            accessKey: String? = nil, secretKey: String? = nil,
                            completion: @escaping (_ isSuccess: Bool) -> Void)
    {
        // prepare cookies
        if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
            setArchiveCookie(name: "logged-in-user", value: loggedInUser)
            setArchiveCookie(name: "logged-in-sig", value: loggedInSig)
        }
        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        if let accessKey = accessKey, let secretKey = secretKey {
            headers["Authorization"] = "LOW \(accessKey):\(secretKey)"
        }
        let params = [
            "url" : url,
            "snapshot" : snapshot,
            "tags" : []
        ] as Parameters

        // make request
        let req = Alamofire.request(WMSAPIManager.API_BASE_URL + WMSAPIManager.API_MY_WEB_ARCHIVE,
                          method: .post, parameters: params,
                          encoding: JSONEncoding.default, headers: headers)
            .responseJSON { (response) in

            switch response.result {
            case .success( _):

                if let json = response.result.value as? [String: Any] {
                    if (DEBUG_LOG) { NSLog("*** saveToMyWebArchive() json: \(json)") }
                    if let success = json["success"] as? Bool {
                        completion(success)
                    } else {
                        completion(false)
                    }
                }
            case .failure( _):
                if (DEBUG_LOG) { NSLog("*** saveToMyWebArchive() FAILED") }
                completion(false)
            }
        }
        if (DEBUG_LOG) { NSLog("*** saveToMyWebArchive() curl: \(req.debugDescription)") }
    }

    // TODO: TEST & Review Code
    func SendDataToBucket(params: [String: Any?],
                          pending: @escaping (Progress) -> Void = {_ in },
                          completion: @escaping (Bool, Int64) -> Void)
    {
        let identifier  = params["identifier"]  as? String ?? ""
        let title       = params["title"]       as? String ?? "", uriTitle = uriEncode(title) ?? ""
        let description = params["description"] as? String ?? "", uriDescription = uriEncode(description) ?? ""
        let subjectTags = params["tags"]        as? String ?? "", uriSubjectTags = uriEncode(subjectTags) ?? ""
        let filename    = params["filename"]    as? String ?? "", uriFilename = uriEncode(filename) ?? ""
        let mediatype   = params["mediatype"]   as? String ?? ""
        let s3accesskey = params["s3accesskey"] as? String ?? ""
        let s3secretkey = params["s3secretkey"] as? String ?? ""
        var uploaded: Int64 = 0
        
        var headers = [
            "X-File-Name": "uri(\(uriFilename))",
            "x-amz-acl": "bucket-owner-full-control",
            "x-amz-auto-make-bucket": "1",
            "x-archive-meta-collection": "opensource_media",
            "x-archive-meta-mediatype": mediatype,
            "x-archive-meta-title": "uri(\(uriTitle))",
            "x-archive-meta-description": "uri(\(uriDescription))",
            "x-archive-meta-subject": "uri(\(uriSubjectTags))",
            "authorization": String(format: "LOW %@:%@", s3accesskey, s3secretkey)
        ]

        for (key, value) in WMSAPIManager.HEADERS {
            headers[key] = value
        }

        let url = String(format: "%@/%@/%@", WMSAPIManager.UPLOAD_BASE_URL, identifier, filename)
        var uploadRequest: UploadRequest?

        if let fileData = params["data"] as? Data {
            uploadRequest = Alamofire.upload(fileData, to: url, method: .put, headers: headers)
        } else if let fileData = params["data"] as? URL {
            uploadRequest = Alamofire.upload(fileData, to: url, method: .put, headers: headers)
        } else {
            if (DEBUG_LOG) { NSLog("*** SendDataToBucket() ERROR Cannot read File Data") }
            completion(false, uploaded)
        }

        uploadRequest?
            .uploadProgress { (progress) in
                pending(progress)
                if (DEBUG_LOG) {
                    uploaded = progress.completedUnitCount
                    let total = progress.totalUnitCount
                    var estimateTime: TimeInterval?
                    if #available(iOS 11.0, *) {
                        estimateTime = progress.estimatedTimeRemaining
                    }
                    if (DEBUG_LOG) { NSLog("*** SendDataToBucket() upload: \(uploaded), total: \(total), time: \(estimateTime ?? 0)") }
                }
            }
            .responseData(completionHandler: { (result) in
                switch result.result {
                case .success( _):
                    completion(true, uploaded)
                    break
                case .failure(let error):
                    if (DEBUG_LOG) { NSLog("*** SendDataToBucket(): request failure: " + error.localizedDescription) }
                    completion(false, uploaded)
                    break
                }
            })
    }

}
