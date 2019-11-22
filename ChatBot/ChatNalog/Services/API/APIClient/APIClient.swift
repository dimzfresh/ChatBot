//
//  APIClient.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation
import Alamofire
import RxAlamofire
import RxSwift
import RxCocoa

enum AppError: Error {
    case noInternet
    case networkError(Error?)
    case serverResponseError(Int, String)
    case unexpectedError(Error?)
}

public protocol APIClientProtocol: AlamofireManager {
    func process<Model: Decodable>(_ networkRequest: APIRequest) -> Observable<ApiResult<ApiErrorMessage, Model>>
}

public class APIClient: APIClientProtocol {
    private let scheduler: ConcurrentDispatchQueueScheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS(qosClass: .userInteractive, relativePriority: 1))
}

extension APIClient {
    public func process<Model: Decodable>(_ request: APIRequest) -> Observable<ApiResult<ApiErrorMessage, Model>> {
        
        let method = request.method
        let url = request.url
        let parameters = request.parameters
        let headers = request.headers
        
        let observable = RxAlamofire.requestData(method, url, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .debug()
            .observeOn(scheduler)
            .asObservable()
            .expectingObject(ofType: Model.self)
        
        return observable

    }
}

public struct ApiErrorMessage: Decodable {
    let code: Int?
    let message: String?

    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }

    public init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: ApiErrorMessageKeys.self)
            .nestedContainer(keyedBy: ErrorMessageKeys.self, forKey: .error)
        self.code = try? container?.decode(Int.self, forKey: .code)
        self.message = try? container?.decode(String.self, forKey: .message)
    }

    enum ApiErrorMessageKeys: String, CodingKey {
        case error
    }

    enum ErrorMessageKeys: String, CodingKey {
        case code
        case message
    }
}

public enum ApiResult<Error, Value: Decodable> {
    case success(Value)
    case failure(Error)

    init(value: Value) {
        self = .success(value)
    }

    init(error: Error) {
        self = .failure(error)
    }
}

extension Observable where Element == (HTTPURLResponse, Data) {
    fileprivate func expectingObject<T: Decodable>(ofType type: T.Type) -> Observable<ApiResult<ApiErrorMessage, T>> {
        return self.map { (httpURLResponse, data) -> ApiResult<ApiErrorMessage, T> in
            switch httpURLResponse.statusCode {
            case 200...299:
                let object = try JSONDecoder().decode(type, from: data)
                return .success(object)
            default:
                // otherwise try
                let apiErrorMessage: ApiErrorMessage
                do {
                    apiErrorMessage = try JSONDecoder().decode(ApiErrorMessage.self, from: data)
                } catch _ {
                    apiErrorMessage = ApiErrorMessage(code: -1, message: "Ошибка. Повторите позже")
                }
                return .failure(apiErrorMessage)
            }
        }
    }
}


