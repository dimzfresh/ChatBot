//
//  OutgoingBubbleTableViewCell.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Alamofire

final class OutgoingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: UIActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!

    private var disposeBag = DisposeBag()

    private let service = ChatService()
    private var isPlaying = BehaviorRelay<Bool>(value: false)
    private var player: VoiceManager? = VoiceManager()
            
    var message: ChatModel? {
        didSet {
            process()
        }
    }
    
    var answers = BehaviorRelay<[AnswerButton]>(value: [])
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
        bind()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        activity.stopAnimating()
        player?.stopPlaying()
        player = VoiceManager()
        isPlaying.accept(false)
    }
}

private extension OutgoingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
    }
    
    func bind() {
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let flag = self.isPlaying.value
            self.isPlaying.accept(!flag)
        }).disposed(by: disposeBag)
        
        isPlaying.subscribe(onNext: { [weak self] flag in
            self?.load()
            self?.animate()
        })
        .disposed(by: disposeBag)
    }
    
    func process() {
        userNameLabel.text = "Пользователь"
        messageLabel.text = message?.text
    }
    
    func animate() {
        // Image
        let image: UIImage = isPlaying.value ? #imageLiteral(resourceName: "play_sound_tapped") : #imageLiteral(resourceName: "play_sound")

        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(image, for: .normal)
        })
        
        speakerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        guard isPlaying.value else {
            speakerButton.transform = .identity
            speakerButton.alpha = 1
            speakerButton.layer.removeAllAnimations()
            return
        }
        
        // Scale
        UIView.animate(withDuration: 0.9,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 5,
                       options: [.autoreverse, .curveLinear,
                                 .repeat, .allowUserInteraction],
                       animations: {
                        self.speakerButton.transform = .identity
                        self.speakerButton.alpha = 0.75
        })
    }
    
    func load() {
        guard let text = message?.text, isPlaying.value else {
            activity.stopAnimating()
            speakerButton.isHidden = false
            return }
        
        activity.startAnimating()
        speakerButton.isHidden = true
        
        cancelAllRequests()
        
        service.synthesize(text: text)
        .subscribe(onNext: { [weak self] model in
            self?.activity.stopAnimating()
            self?.speakerButton.isHidden = false
            self?.convertAndPlay(text: model.someString)
            })
        .disposed(by: disposeBag)
    }
    
    func cancelAllRequests() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
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

