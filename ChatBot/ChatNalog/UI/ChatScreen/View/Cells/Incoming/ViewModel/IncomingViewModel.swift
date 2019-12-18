//
//  IncomingViewModel.swift
//  ChatBot
//
//  Created by iOS dev on 05/12/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import RxSwift
import RxCocoa

struct InputAnswer {
    var text: String
    var items: [AnswerSectionModel]
}

final class IncomingViewModel: BaseViewModel {
    typealias Service = ChatService
    
    var message: ChatModel? {
        didSet {
            process()
        }
    }
    
    // MARK: - Audio
    var isLoading = BehaviorRelay<Bool>(value: false)
    var isPlaying = BehaviorRelay<Bool>(value: false)
    
    var input = BehaviorRelay<InputAnswer?>(value: nil)

    private let service: Service?
    private let voiceManager = VoiceManager.shared
    private let disposeBag = DisposeBag()
    
    private var player: VoiceManager? = VoiceManager.shared
    
    init(service: Service? = ChatService()) {
        self.service = service
        
        bind()
    }
}

extension IncomingViewModel {
    func bind() {
        isLoading
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] flag in
                self?.load()
            })
            .disposed(by: disposeBag)
    }
}

private extension IncomingViewModel {
    
    func process() {
        var inputAnswer = InputAnswer(text: message?.text ?? "", items: [])
        
        guard message?.buttons?.isEmpty == false else {
            input.accept(inputAnswer)
            return }

        var text = message?.text ?? ""
        text = text + (text.isEmpty ? "" : "\n\n") + "\(message?.buttonsDescription ?? "")\n"
        var current = 1
        var newAnswers = [AnswerSectionModel]()
        message?.buttons?.forEach {
            let description = $0.description ?? ""
            text = text + description

            newAnswers.append(AnswerSectionModel(model: .main, items: [.button(answer: $0)]))

            if current != message?.buttons?.count, !description.isEmpty  {
                text += "\n"
            }
            current += 1
        }
        inputAnswer.text = text
        inputAnswer.items = newAnswers
        input.accept(inputAnswer)
    }
    
    func load() {
        guard let text = input.value?.text, isLoading.value else {
            isLoading.accept(false)
            return }

        isLoading.accept(true)
        
        let clearText = removeSpecialCharsFromString(text: text)

        service?.synthesize(text: clearText)
            .subscribe(onNext: { [weak self] model in
                self?.isLoading.accept(false)
                self?.convertAndPlay(text: model.someString)
                }, onError: { [weak self] _ in
                    self?.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars: Set<Character> = Set("\"")
            //Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(text.filter { !okayChars.contains($0) })
    }
    
    func convertAndPlay(text : String?) {
        isPlaying.accept(true)

        guard let audioData = Data(base64Encoded: text ?? "", options: .ignoreUnknownCharacters) else {
            isPlaying.accept(false)
            return }
        
        let filename = getDocumentsDirectory().appendingPathComponent("input.mp3")
        do {
            try audioData.write(to: filename, options: .atomicWrite)
        } catch (let error) {
            isPlaying.accept(false)
            print(error)
        }
        player?.startPlaying()
        player?.audioPlayerDidFinished = { [weak self] in
            self?.isPlaying.accept(false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
