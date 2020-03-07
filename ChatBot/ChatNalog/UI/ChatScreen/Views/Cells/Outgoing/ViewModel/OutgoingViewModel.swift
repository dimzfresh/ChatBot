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
    
    private let player: VoiceManager = .shared
    
    var input = BehaviorRelay<ChatModel?>(value: nil)

    private let service: Service?
    private let disposeBag = DisposeBag()
    
    var isPlaying = BehaviorRelay<Bool?>(value: nil)
    var isOnPause = BehaviorRelay<Bool?>(value: nil)
    var isLoading = BehaviorRelay<Bool?>(value: nil)
        
    init(service: Service? = ChatService()) {
        self.service = service
        
        bind()
    }
}

extension OutgoingViewModel {
    func bind() {
        isLoading
            .observeOn(MainScheduler.asyncInstance)
            .share(replay: 1)
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag, flag else { return }
                self?.load()
        })
        .disposed(by: disposeBag)
        
        isPlaying
            .observeOn(MainScheduler.asyncInstance)
            .share(replay: 1)
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag, flag else { return }
                self?.play()
                FirebaseEventManager.shared.logEvent(input: .init(.voice(.playAnswer)))
        })
        .disposed(by: disposeBag)
        
        isOnPause
            .observeOn(MainScheduler.asyncInstance)
            .share(replay: 1)
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag, flag else { return }
                self?.pausePlaying()
        })
        .disposed(by: disposeBag)
    }
    
    func resetFlags() {
        isOnPause.accept(nil)
        isPlaying.accept(false)
        isLoading.accept(nil)
    }
}

private extension OutgoingViewModel {
    func load() {
        guard let text = input.value?.text else { return }
        
        let clearText = removeSpecialCharsFromString(text: text)

        service?
            .synthesize(text: clearText)
            .subscribe(onNext: { [weak self] model in
                guard self?.isLoading.value == true else { return }
                
                self?.isLoading.accept(false)
                self?.play(text: model.someString)
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
        
        isPlaying.accept(true)
    }
    
    func play() {
        player.startPlaying()
        player.audioPlayerDidFinished = { [weak self] in
            self?.resetFlags()
        }
    }
    
    func pausePlaying() {
        player.pausePlaying()
    }
    
    func continuePlaying() {
        player.startPlaying()
        player.audioPlayerDidFinished = { [weak self] in
            self?.resetFlags()
        }
    }
    
    func stopPlaying() {
        player.stopPlaying()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
