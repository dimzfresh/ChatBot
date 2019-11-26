//
//  RequestsFactory.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Alamofire
import RxSwift
import Foundation

public final class RequestsFactory {
    enum Chat {
        case question(String)
        case answer(AnswerRequestInput)

        public var request: APIRequest {
            switch self {
            case .question(let text):
                return QuestionRequest(text: text)
            case .answer(let input):
                return AnswerRequest(input: input)
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

// MARK: - Question
public final class QuestionRequest: APIRequest {
    public var route: String = "/ChatbotV2?userQuestion="
    public var method: HTTPMethod { .get }
    
    private var text: String
    
    init(text: String) {
        self.text = text
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? text
        route = route + encoded
    }
}

// MARK: - Answer
public final class AnswerRequest: APIRequest {
    public var route: String = "/ChatbotV2?userQuestion="
    public var method: HTTPMethod { .get }
    
    public var headers: HTTPHeaders {
        var h = defaultHeaders
        h["buttoncontent"] = buttoncontent
        h["buttontype"] = buttontype
        h["dialogid"] = dialogid

        return h
    }
     
    private var buttoncontent = ""
    private var buttontype = ""
    private var dialogid = ""
    private var text: String
    
    init(input: AnswerRequestInput) {
        buttoncontent = input.content
        dialogid = input.id
        buttontype = input.type
        self.text = input.text
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? text
        route = route + encoded
    }
}

public struct AnswerRequestInput {
    var content: String = ""
    var type: String = ""
    var id: String = ""
    var text: String
    
    init(text: String) {
        self.text = text
    }
}
