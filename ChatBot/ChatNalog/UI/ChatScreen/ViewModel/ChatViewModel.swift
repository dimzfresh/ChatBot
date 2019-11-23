//
//  ChatViewModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation

import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class ChatViewModel: BaseViewModel {
    typealias Service = ChatService
    
    private let service: Service?
    private let disposeBag = DisposeBag()
    
    let question = BehaviorRelay<String>(value: "")
    let password = BehaviorRelay<String>(value: "")
    
    var chat: BehaviorRelay<[ChatModel]> = BehaviorRelay(value: [])
    
    init(service: Service?) {
        self.service = service
    }

//    func enterButtonValid(email: Observable<String>, password: Observable<String>) -> Observable<Bool> {
//        return Observable.combineLatest(email, password)
//        { email, password in
//            return !email.isEmpty && !password.isEmpty
//        }
//    }
    
    func request() {
        send()
    }
}

private extension ChatViewModel {
    func send() {
        service?.sendQuestion(text: question.value)
        .subscribe(onNext: { [weak self] model in
            print(model)
            }, onError: { [weak self] error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
//    func save(user: Model) {
//        let info: AuthInfo = (token: user.token, name: user.name ?? "", email: email.value)
//        Settings.storage.isAuthorized = true
//        Settings.storage.saveAuth(info)
//    }
}
