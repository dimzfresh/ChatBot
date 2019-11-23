//
//  ChatViewModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

typealias SectionOfChat = SectionModel<TableViewSection, TableViewItem>

enum TableViewSection {
    case outgoing
    case incoming
}

enum TableViewItem {
    case message(info: ChatModel)
}

final class ChatViewModel: BaseViewModel {
    typealias Service = ChatService
    
    private let service: Service?
    private let disposeBag = DisposeBag()
    
    let question = BehaviorRelay<String>(value: "")
    let password = BehaviorRelay<String>(value: "")
    
    //var chat: BehaviorRelay<[ChatModel]> = BehaviorRelay(value: [])
    var messages = PublishSubject<[SectionOfChat]>()

    
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
            self?.processItems(for: model)
            }, onError: { [weak self] error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func processItems(for chat: [ChatModel]) {
        let incomingItems: [TableViewItem] = chat
            .filter { $0.buttons != nil }
            .map { .message(info: $0) }
        
        let outgoingItems: [TableViewItem] = chat
            .filter { $0.buttons != nil }
            .map { .message(info: $0) }
        
        let sections = [SectionOfChat(model: .incoming, items: incomingItems),
                        SectionOfChat(model: .outgoing, items: outgoingItems)]
        
        messages.onNext(sections)
    }
}
