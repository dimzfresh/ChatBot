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
        case question(String, id: String)
        case answer(AnswerRequestInput)
        case search(String)

        public var request: APIRequest {
            switch self {
            case .question(let text, let id):
                return QuestionRequest(text: text, id: id)
            case .answer(let input):
                return AnswerRequest(input: input)
            case .search(let text):
                return SearchRequest(text: text)
            }
        }
    }
    
    enum Session {
        case logout

        public var request: APIRequest {
            switch self {
            case .logout:
                return QuestionRequest(text: "", id: "")
            }
        }
    }
}

// MARK: - Question
public final class QuestionRequest: APIRequest {
    public var route: String = "/ChatbotV2?userQuestion="
    public var method: HTTPMethod { .get }
    
    public var headers: HTTPHeaders {
        var h = defaultHeaders
        if !dialogid.isEmpty {
            h["dialogid"] = dialogid
        }
        return h
    }
    
    private var text: String
    private var dialogid = ""
    
    init(text: String, id: String) {
        self.text = text
        self.dialogid = id

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

// MARK: - Search
public final class SearchRequest: APIRequest {
    public var route: String = "/Suggest/suggest?search="
    public var method: HTTPMethod { .post }

    private var text: String
    
    init(text: String) {
        self.text = text
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? text
        route = route + encoded
    }
}

public struct QuestionRequestInput {
    var content: String = ""
    var type: String = ""
    var id: String = ""
    var text: String
    
    init(text: String) {
        self.text = text
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
