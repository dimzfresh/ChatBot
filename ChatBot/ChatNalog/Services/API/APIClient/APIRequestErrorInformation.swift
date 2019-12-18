//
//  RequestErrorInformation.swift
//  ChatBot
//
//  Created by iOS dev on 13/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation

public typealias JSON = [String:Any]

public struct APIRequestErrorInformation {
  
  /// Error returned from alamofire.
  let error: Error
  /// Error status code.
  let statusCode: Int?
  /// More error information, this could be returned error information from backend.
  let responseBody: JSON?
  
  init(error: Error, data: Data?, urlResponse: HTTPURLResponse?) {
    self.error = error
    //responseBody = (try? JSON(data: data ?? Data())) ?? JSON()
    responseBody = nil
    statusCode = urlResponse?.statusCode
  }
}
