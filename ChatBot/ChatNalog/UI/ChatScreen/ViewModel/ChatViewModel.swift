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
import Alamofire

typealias SectionOfChat = SectionModel<TableViewSection, TableViewItem>
typealias ChatTitle = (main:String, sub:String)

enum TableViewSection {
    case outgoing
    case incoming
}

enum TableViewItem {
    case message(info: ChatModel)
}

enum MicrophoneState {
    case recording
    case stopped
    case none

    var opposite: MicrophoneState {
        return self == .recording ? .stopped : .recording
    }
}

enum SpeakerState {
    case loading
    case playing
    case stopped
}

final class ChatViewModel: BaseViewModel {
    typealias Service = ChatService
    
    private let service: Service?
    private let voiceManager = VoiceManager.shared
    private let disposeBag = DisposeBag()
        
    let title = BehaviorSubject<ChatTitle>(value: (main: "Налоговый помощник Жора",
                                                   sub: "\nОнлайн"))
   
    let messages = BehaviorRelay<[SectionOfChat]>(value: [])
    
    let questionInput = BehaviorRelay<String>(value: "")
    let answerOutput = BehaviorSubject<AnswerRequestInput?>(value: nil)
    let searchResult = BehaviorSubject<[String]>(value: [])
    let voice = BehaviorRelay<String?>(value: nil)

    let microphoneState = BehaviorRelay<MicrophoneState>(value: .none)
    let speakerState = BehaviorRelay<SpeakerState>(value: .stopped)
    
    var scrollPosition = BehaviorSubject<ScorllPosition>(value: .bottom)

    init(service: Service?) {
        self.service = service
        bind()
        addFirstMessage()
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
    
    // MARK: - Microphone
    func record(for state: MicrophoneState) {
        if state == .recording {
            voiceManager.startRecording()
        } else {
            voiceManager.stopRecording()
        }
    }
}

private extension ChatViewModel {
    func bind() {
        answerOutput.subscribe(onNext: { [weak self] input in
            guard let input = input, !input.id.isEmpty else { return }
            self?.answer(input: input)
        })
        .disposed(by: disposeBag)
        
        voice.subscribe(onNext: { [weak self] text in
            guard let text = text else { return }
            self?.recognize(text: text)
        })
        .disposed(by: disposeBag)
    }
    
    
    // MARK: - Messages
    
    func addFirstMessage() {
        var message = ChatModel()
        message.text = "Добрый день, задайте вопрос!"
       
        let new = [SectionOfChat(model: .incoming, items: [.message(info: message)])]
        messages.accept(new)
        
        moveScroll()
    }
    
    func addMessage() {
        changeTitle()
        
        var message = ChatModel()
        message.text = questionInput.value
        
        let new = [SectionOfChat(model: .outgoing, items: [.message(info: message)])]
        messages.accept(messages.value + new)
        
        moveScroll()
    }
    
    func changeTitle() {
        title.on(.next((main: "Налоговый помощник Жора",
        sub: "\nпечатает...")))
    }
    
    func moveScroll() {
         scrollPosition.on(.next(.bottom))
    }
    
    
    // MARK: - Network
    
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
    
    func recognize(text: String) {
        service?.recognize(text: text)
        .subscribe(onNext: { [weak self] model in
            let text = model.someString ?? ""
            self?.questionInput.accept(text)
            self?.sendQuestion()
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
    
    
    // MARK: - Funcs
    func processItems(for chat: ChatModel) {
        let outgoingItems: [TableViewItem] = [.message(info: chat)]
        let new = [SectionOfChat(model: .incoming, items: outgoingItems)]

        messages.accept(messages.value + new)
    }
}
