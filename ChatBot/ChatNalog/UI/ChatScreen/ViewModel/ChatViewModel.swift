//
//  ChatViewModel.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
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

enum SpeakerState {
    case loading
    case playing
    case stopped
}

fileprivate let chatName = "Помощник по Самозанятым".uppercased()

final class ChatViewModel: BaseViewModel {
    typealias Service = ChatService
    
    private let service: Service?
    private let voiceManager = VoiceManager.shared
    private let storage: CoreDataManagerProtocol = CoreDataManager()
    private var firstOpen = true
    
    private let disposeBag = DisposeBag()
      
    let title = BehaviorSubject<ChatTitle>(value: (main: chatName,
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
        
        fetchAll()
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
    
    func recognizeVoice() {
        recognize()
    }
    
    func convertAndPlay() {
        guard let text: String = voice.value, !text.isEmpty else { return }

        guard let audioData = Data(base64Encoded: text, options: .ignoreUnknownCharacters) else { return }
        
        let filename = getDocumentsDirectory().appendingPathComponent("input.mp3")
        do {
            try audioData.write(to: filename, options: .atomicWrite)
        } catch (let error) {
            print(error)
        }
        voiceManager.startPlaying()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

private extension ChatViewModel {
    func bind() {
        answerOutput.subscribe(onNext: { [weak self] input in
            guard let input = input, !input.id.isEmpty else { return }
            self?.answer(input: input)
        })
            .disposed(by: disposeBag)
        
//        voice.subscribe(onNext: { [weak self] text in
//            guard let text = text else { return }
//            self?.recognize(text: text)
//        })
//            .disposed(by: disposeBag)
        
        messages.subscribe(onNext: { [weak self] new in
            guard self?.firstOpen == false else { return }
            self?.save(new: new)
        })
        .disposed(by: disposeBag)
    }
    
    
    // MARK: - Messages
    
    func addFirstMessage() {
        var message = ChatModel()
        message.identifier = UUID().uuidString
        message.isIncoming = true
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
        title.onNext((main: chatName,
        sub: "\nпечатает..."))
    }
    
    func moveScroll() {
        scrollPosition.onNext(.bottom)
    }
    
    
    // MARK: - Network
    
    func question() {
        searchResult.onNext([])
        let text = questionInput.value
        questionInput.accept("")
        
        let items = messages.value.flatMap { $0.items }
        let identifiers: [String?] = items.map {
            guard case let TableViewItem.message(message) = $0,
                let id = message.dialogID else {
                return nil
            }
            return "\(id)"
        }
        let id: String = identifiers.last { $0 != nil } as? String ?? ""
        
        service?.sendQuestion(text: text, id: id)
        .subscribe(onNext: { [weak self] model in
            var m = model
            m.isIncoming = true
            self?.processItems(for: m)
            self?.title.onNext((main: chatName,
            sub: "\nОнлайн"))
            self?.scrollPosition.onNext(.bottom)
            }, onError: { error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func answer(input: AnswerRequestInput) {
        service?.sendAnswer(input: input)
        .subscribe(onNext: { [weak self] model in
            var m = model
            m.isIncoming = true
            self?.processItems(for: m)
            self?.title.onNext((main: chatName,
            sub: "\nОнлайн"))
            self?.scrollPosition.onNext(.bottom)
            }, onError: { error in
                print(error)
        })
        .disposed(by: disposeBag)
    }
    
    func recognize() {
        guard let text: String = voice.value, !text.isEmpty else { return }
                
        service?.recognize(text: text)
        .subscribe(onNext: { [weak self] model in
            let text = model.someString ?? ""
            let str = text.replacingOccurrences(of: "\"", with: "")
            self?.questionInput.accept(str)
            self?.sendQuestion()
            self?.scrollPosition.onNext(.bottom)
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
            let new = items.map { $0.text ?? "" }
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
    
    
    // MARK: - CoreDataManager
    func fetchAll() {
        storage.fetch { [weak self] (result: Result<[ChatModel]>) in
            switch result {
            case .success(let items):
                //completion(users.first)
                let messages = items
                    .sorted(by: { m1, m2 -> Bool in
                        guard let date1 = m1.date, let date2 = m2.date else { return false }
                        return date1 < date2
                    })
                    .map { message -> SectionOfChat in
                    let item: [TableViewItem] = [.message(info: message)]
                    let type: TableViewSection = message.isIncoming == true ? .incoming : .outgoing
                    let new = SectionOfChat(model: type, items: item)
                    return new
                }
                
                if messages.isEmpty {
                    self?.addFirstMessage()
                } else {
                    self?.messages.accept(messages)
                    self?.moveScroll()
                }
                self?.firstOpen = false
            case .failure(let error):
                print(error)
                self?.addFirstMessage()
                self?.firstOpen = false
                //completion(nil)
            }
        }
        
//        let outgoingItems: [TableViewItem] = [.message(info: chat)]
//        let new = [SectionOfChat(model: .incoming, items: outgoingItems)]
//        messages.accept(messages.value + new)
    }
    
    func save(new message: [SectionOfChat]) {
        let items: [ChatModel?] = message
            .map { $0.items }
            .flatMap { $0 }
            .map {
                guard case let .message(item) = $0 else { return nil }
                return item
            }
        
        let history: [ChatModel] = items.compactMap { $0 }
        
        storage.save(entities: history) { error in
            guard let error = error else { return }
            print(error)
        }
    }    
}
