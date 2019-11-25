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
    var messages = BehaviorRelay<[SectionOfChat]>(value: [])
    
    init(service: Service?) {
        self.service = service
    }
    
    func addFirstMessage() {
        let firstMessage = ChatModel(dialogID: nil, text: "Добрый день, задайте вопрос!", buttonsDescription: nil, buttons: nil, buttonContent: nil, buttonType: nil)
        messages.accept([SectionOfChat(model: .incoming, items: [.message(info: firstMessage)])])
    }
    
    func addMessage() {
        guard !question.value.isEmpty else { return }
        
        let text = question.value
        let message = ChatModel(dialogID: nil, text: text, buttonsDescription: nil, buttons: nil, buttonContent: nil, buttonType: nil)
        let new = [SectionOfChat(model: .outgoing, items: [.message(info: message)])]
        messages.accept(messages.value + new)            
    }
    
    func request() {
        //send()
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
//        let incomingItems: [TableViewItem] = chat
//            .filter { $0.buttons != nil }
//            .map { .message(info: $0) }
//
//        let outgoingItems: [TableViewItem] = chat
//            .filter { $0.buttons != nil }
//            .map { .message(info: $0) }
//
//        let sections = [SectionOfChat(model: .incoming, items: incomingItems),
//                        SectionOfChat(model: .outgoing, items: outgoingItems)]
//
//        messages.onNext(sections)
    }
}
