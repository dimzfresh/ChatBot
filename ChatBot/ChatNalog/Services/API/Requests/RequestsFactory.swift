//
//  RequestsFactory.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Alamofire
import RxSwift

public final class RequestsFactory {
    enum Chat {
        case question(String)

        public var request: APIRequest {
            switch self {

            case .question(let text):
                return QuestionRequest(text: text)
            }
        }
    }
    
    enum Session {
        case logout

        public var request: APIRequest {
            switch self {
            case .logout:
                return QuestionRequest(text: "")
            }
        }
    }
}

public final class QuestionRequest: APIRequest {
    public var route: String = "/ChatbotV2"
    public var method: HTTPMethod { .get }
    
    private var text: String {
        didSet {
            route += "?userQuestion=\(text)"
        }
    }
    
    init(text: String) {
        self.text = text
    }
}
