//
//  ChatService.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import RxSwift
import Foundation

public typealias OservableResult = Observable<ApiResult<ApiErrorMessage, [ChatModel]>>

public final class ChatService {
    
    private let networkClient: APIClient = APIClient()

    public func sendQuestion(text: String) -> Observable<[ChatModel]> {
        let request = RequestsFactory.Chat.question(text).request
        
        let raw: OservableResult = networkClient.process(request)
        
        let result = raw.flatMap { result -> Observable<[ChatModel]> in
            switch result {
            case .success(let value):
                return .just(value)
            case .failure(let error):
                return .error(AppError.serverResponseError(error.code ?? 0, error.message ?? ""))
            }
        }
        .catchError { error -> Observable<[ChatModel]> in
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                return .error(AppError.networkError(error))
            } else {
                return .error(error)
            }
        }
        
        return result
    }
}
