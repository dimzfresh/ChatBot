//
//  ChatService.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import RxSwift
import Foundation

public typealias OservableResult = Observable<ApiResult<ApiErrorMessage, ChatModel>>
public typealias OservableSearchResult = Observable<ApiResult<ApiErrorMessage, SearchModel>>
public typealias OservableVoiceResult = Observable<ApiResult<ApiErrorMessage, VoiceModel>>


public final class ChatService {
    
    private let networkClient: APIClient = APIClient()

    public func sendQuestion(text: String, id: String) -> Observable<ChatModel> {
        let request = RequestsFactory.Chat.question(text, id: id).request
        
        let raw: OservableResult = networkClient.process(request)
        
        let result = raw.flatMap { result -> Observable<ChatModel> in
            switch result {
            case .success(let value):
                return .just(value)
            case .failure(let error):
                return .error(AppError.serverResponseError(error.code ?? 0, error.message ?? ""))
            }
        }
        .catchError { error -> Observable<ChatModel> in
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                return .error(AppError.networkError(error))
            } else {
                return .error(error)
            }
        }
        
        return result
    }
    
    public func sendAnswer(input: AnswerRequestInput) -> Observable<ChatModel> {
        let request = RequestsFactory.Chat.answer(input).request
        
        let raw: OservableResult = networkClient.process(request)
        
        let result = raw.flatMap { result -> Observable<ChatModel> in
            switch result {
            case .success(let value):
                return .just(value)
            case .failure(let error):
                return .error(AppError.serverResponseError(error.code ?? 0, error.message ?? ""))
            }
        }
        .catchError { error -> Observable<ChatModel> in
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                return .error(AppError.networkError(error))
            } else {
                return .error(error)
            }
        }
        
        return result
    }
    
    public func search(text: String) -> Observable<SearchModel> {
        let request = RequestsFactory.Chat.search(text).request
        
        let raw: OservableSearchResult = networkClient.process(request)
        
        let result = raw.flatMap { result -> Observable<SearchModel> in
            switch result {
            case .success(let value):
                return .just(value)
            case .failure(let error):
                return .error(AppError.serverResponseError(error.code ?? 0, error.message ?? ""))
            }
        }
        .catchError { error -> Observable<SearchModel> in
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                return .error(AppError.networkError(error))
            } else {
                return .error(error)
            }
        }
        
        return result
    }
    
    public func recognize(text: String) -> Observable<VoiceModel> {
        let request = RequestsFactory.Chat.recognize(text).request
        
        let raw: OservableVoiceResult = networkClient.process(request)
        
        let result = raw.flatMap { result -> Observable<VoiceModel> in
            switch result {
            case .success(let value):
                return .just(value)
            case .failure(let error):
                return .error(AppError.serverResponseError(error.code ?? 0, error.message ?? ""))
            }
        }
        .catchError { error -> Observable<VoiceModel> in
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                return .error(AppError.networkError(error))
            } else {
                return .error(error)
            }
        }
        
        return result
    }
}
