//
//  OutgoingViewModel.swift
//  ChatBot
//
//  Created by iOS dev on 05/12/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import RxSwift
import RxCocoa

final class OutgoingViewModel: BaseViewModel {    
    typealias Service = ChatService
    
    var message: ChatModel? {
        didSet {
            input.accept(message)
        }
    }
    
    var input = BehaviorRelay<ChatModel?>(value: nil)

    private let service: Service?
    private let disposeBag = DisposeBag()
    
    var isPlaying = BehaviorRelay<Bool?>(value: nil)
    var isLoading = BehaviorRelay<Bool>(value: false)
        
    init(service: Service? = ChatService()) {
        self.service = service
        
        bind()
    }
}

extension OutgoingViewModel {
    func bind() {
        isPlaying
            .observeOn(MainScheduler.asyncInstance)
            .share(replay: 1)
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag else { return }
                if !flag {
                    self?.stop()
                } else {
                    self?.load()
                }
        })
        .disposed(by: disposeBag)
    }
}

private extension OutgoingViewModel {
    func load() {
        guard let text = input.value?.text,
            let flag = isPlaying.value,
            flag else { return }
        let clearText = removeSpecialCharsFromString(text: text)

        isLoading.accept(true)
        service?.synthesize(text: clearText)
            .subscribe(onNext: { [weak self] model in
                self?.play(text: model.someString)
                }, onError: { [weak self] error in
                    print(error)
                    self?.isPlaying.accept(false)
                }, onCompleted: {
                    self.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars: Set<Character> = Set("\"")
            //Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(text.filter { !okayChars.contains($0) })
    }
    
    func play(text : String?) {
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
        VoiceManager.shared.startPlaying()
        VoiceManager.shared.audioPlayerDidFinished = { [weak self] in
            self?.isPlaying.accept(false)
        }
    }
    
    func stop() {
        VoiceManager.shared.stopPlaying()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
