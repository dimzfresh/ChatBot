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
typealias ChatTitle = (main:String, sub:String)

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
        
    let title = BehaviorSubject<ChatTitle>(value: (main: "Налоговый помощник Жора",
                                                   sub: "\nОнлайн"))

    let questionInput = BehaviorRelay<String>(value: "")
    let answerOutput = BehaviorSubject<AnswerRequestInput?>(value: nil)
    let messages = BehaviorRelay<[SectionOfChat]>(value: [])
    let searchResult = BehaviorSubject<[String]>(value: [])
    
    var scrollPosition = BehaviorSubject<ScorllPosition>(value: .bottom)

    init(service: Service?) {
        self.service = service
        bind()
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
    
    func searchSuggestions() {
        guard !questionInput.value.isEmpty else { return }

        search()
    }
}

private extension ChatViewModel {
    func bind() {
        answerOutput.subscribe(onNext: { [weak self] input in
            guard let input = input, !input.id.isEmpty else { return }
            self?.answer(input: input)
        })
        .disposed(by: disposeBag)
    }
    
    func question() {
        searchResult.onNext([])
        let text = questionInput.value
        questionInput.accept("")
        
        var id = ""
        //don't ask me why I do this
        let _ = messages.value.last { model -> Bool in
            let _ = model.items.last {
                guard case let TableViewItem.message(message) = $0, let i = message.dialogID else {
                    return false
                }
                id = "\(i)"
                return true
            }
            return false
        }
        
        service?.sendQuestion(text: text, id: id)
        .subscribe(onNext: { [weak self] model in
            self?.processItems(for: model)
            self?.title.on(.next((main: "Налоговый помощник Жора",
            sub: "\nОнлайн")))
            self?.scrollPosition.on(.next(.bottom))
            }, onError: { error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func answer(input: AnswerRequestInput) {
        service?.sendAnswer(input: input)
        .subscribe(onNext: { [weak self] model in
            self?.processItems(for: model)
            self?.title.on(.next((main: "Налоговый помощник Жора",
            sub: "\nОнлайн")))
            self?.scrollPosition.on(.next(.bottom))
            }, onError: { error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func search() {
        let text = questionInput.value
        
        service?.search(text: text)
        .subscribe(onNext: { [weak self] model in
            guard let items = model.suggestions, !items.isEmpty else {
                self?.searchResult.onNext([])
                return }
            let new = items.map({ $0.text ?? "" })
            self?.searchResult.onNext(new)
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
        title.on(.next((main: "Налоговый помощник Жора",
        sub: "\nпечатает...")))
        
        let text = questionInput.value
        let message = ChatModel(dialogID: nil, text: text, buttonsDescription: nil, buttons: nil, buttonContent: nil, buttonType: nil)
        let new = [SectionOfChat(model: .outgoing, items: [.message(info: message)])]
        messages.accept(messages.value + new)
        
        scrollPosition.on(.next(.bottom))
    }
}
