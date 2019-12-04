//
//  OutgoingViewModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 05/12/2019.
//  Copyright © 2019 di. All rights reserved.
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
    private let voiceManager = VoiceManager.shared
    private let disposeBag = DisposeBag()
    
    private var isPlaying = BehaviorRelay<Bool>(value: false)
    private var player: VoiceManager? = VoiceManager.shared
    
    init(service: Service? = ChatService()) {
        self.service = service
        
        bind()
    }
}

extension OutgoingViewModel {
    func bind() {
        
        
    }
    
    func load() {
        guard let text = input.value?.text, isPlaying.value else {
            //activity.stopAnimating()
            //speakerButton.isHidden = false
            return }

        //activity.startAnimating()
        //speakerButton.isHidden = true

        service?.synthesize(text: text)
        .subscribe(onNext: { [weak self] model in
            //self?.activity.stopAnimating()
            //self?.speakerButton.isHidden = false
            self?.convertAndPlay(text: model.someString)
            })
        .disposed(by: disposeBag)
    }
    
    func convertAndPlay(text : String?) {
        guard let audioData = Data(base64Encoded: text ?? "", options: .ignoreUnknownCharacters) else { return }
        
        let filename = getDocumentsDirectory().appendingPathComponent("input.mp3")
        do {
            try audioData.write(to: filename, options: .atomicWrite)
        } catch (let error) {
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
