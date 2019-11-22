//
//  LoginViewModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class LoginViewModel: BaseViewModel {
    typealias Service = UserService
    
    private let service: Service?
    private let disposeBag = DisposeBag()
    
    let email = BehaviorRelay<String>(value: "")
    let password = BehaviorRelay<String>(value: "")
    
    init(service: Service?) {
        self.service = service
    }

    func enterButtonValid(email: Observable<String>, password: Observable<String>) -> Observable<Bool> {
        return Observable.combineLatest(email, password)
        { email, password in
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    func request() {
        send()
    }
}

private extension LoginViewModel {
    func send() {
        service?.login(email: email.value, password: password.value)
        .subscribe(onNext: { [weak self] model in
            print(model)
            }, onError: { [weak self] error in

        })
        .disposed(by: disposeBag)
    }
    
    func save(user: LoginModel) {
        let info: AuthInfo = (token: user.token, name: user.name ?? "", email: email.value)
        Settings.storage.isAuthorized = true
        Settings.storage.saveAuth(info)
    }
}
