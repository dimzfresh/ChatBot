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
        
    let questionInput = BehaviorRelay<String>(value: "")
    let answerInput = BehaviorSubject<AnswerRequestInput?>(value: nil)
    var messages = BehaviorRelay<[SectionOfChat]>(value: [])
    
    var scrollPosition = BehaviorSubject<ScorllPosition>(value: .bottom)

    init(service: Service?) {
        self.service = service
    }
    
    func addFirstMessage() {
        let firstMessage = ChatModel(dialogID: nil, text: "Добрый день, задайте вопрос!", buttonsDescription: nil, buttons: nil, buttonContent: nil, buttonType: nil)
        let new = [SectionOfChat(model: .incoming, items: [.message(info: firstMessage)])]
        messages.accept(new)
        scrollPosition.on(.next(.bottom))
    }
    
    func sendQuestion() {
        guard !questionInput.value.isEmpty else { return }

        addMessage()
        question()
    }
    
    func sendAnswer() {
        answer()
    }
}

private extension ChatViewModel {
    func question() {
        let text = questionInput.value
        questionInput.accept("")
        
        service?.sendQuestion(text: text)
        .subscribe(onNext: { [weak self] model in
            self?.processItems(for: model)
            self?.scrollPosition.on(.next(.bottom))
            }, onError: { error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func answer() {
        service?.sendAnswer(input: AnswerRequestInput(text: ""))
        .subscribe(onNext: { [weak self] model in
            self?.processItems(for: model)
            self?.scrollPosition.on(.next(.bottom))
            }, onError: { error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func processItems(for chat: ChatModel) {
//        let incomingItems: [TableViewItem] = chat
//            .filter { $0.buttons != nil }
//            .map { .message(info: $0) }

        let outgoingItems: [TableViewItem] = [.message(info: chat)]
        let new = [SectionOfChat(model: .incoming, items: outgoingItems)]

        messages.accept(messages.value + new)
    }
    
    func addMessage() {
        let text = questionInput.value
        let message = ChatModel(dialogID: nil, text: text, buttonsDescription: nil, buttons: nil, buttonContent: nil, buttonType: nil)
        let new = [SectionOfChat(model: .outgoing, items: [.message(info: message)])]
        messages.accept(messages.value + new)
        
        scrollPosition.on(.next(.bottom))
    }
}
