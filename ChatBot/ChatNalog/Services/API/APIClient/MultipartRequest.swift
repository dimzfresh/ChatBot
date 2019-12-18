//
//  MultipartRequest.swift
//  ChatBot
//
//  Created by iOS dev on 13/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation

public protocol MultipartAPIRequest: APIRequest {
    
    /// Data prepared to upload
    var multipartUploadData: Data { get }
    /// e.g. "avatar"
    var multipartUploadName: String { get }
    /// e.g. "file"
    var multipartUploadFileName: String { get }
    /// e.g. "image/jpeg"
    var multipartUploadMimeType: String { get }
    
    var networkClient: APIClientProtocol { get }
}

extension MultipartAPIRequest {
    var networkClient: APIClientProtocol { APIClient() }
}
