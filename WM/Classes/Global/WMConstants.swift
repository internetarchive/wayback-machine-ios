//
//  WMConstants.swift
//  WM
//
//  Created by mac-admin on 8/23/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import Foundation

class WMConstants {
    static let errors :[Int: String] = [
        //-- Codes for Availability API
        100: "Success",
        101: "Cannot connect to server",
        102: "Cannot find an archived page",
        103: "JSON Serialization Error",
        //-- Codes for URL validation
        201: "The URL is invalid",
        //-- Codes for Authenticate
        300: "success",
        301: "account_bad_password",
        302: "account_not_found",
        303: "account_not_verified"
        //-- Codes for Register
    ]
    static let unknown = "Unknown Error"
}
