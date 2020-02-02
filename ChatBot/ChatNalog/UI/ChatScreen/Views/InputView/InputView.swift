//
//  InputView.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 22/12/2019.
//  Copyright © 2019 kvantsoft. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum MicrophoneState {
    case none
    case recording
    case stopped
    
    var opposite: MicrophoneState {
        self == .recording ? .stopped : .recording
    }
}

fileprivate enum PlayerState {
    case none
    case play
    case pause
    
    var opposite: PlayerState {
        self == .play ? .pause : .play
    }
}

protocol InputViewProtocol where Self: UIView {
    var onChangeText: ((String) -> Void)? { get set }
    var onSendText: (() -> Void)? { get set }
    
    var onStartRecordingVoice: (() -> Void)? { get set }
    var onStopRecordingVoice: (() -> Void)? { get set }
    var onPlayVoice: (() -> Void)? { get set }
    var onSendVoice: (() -> Void)? { get set }
    var onClearVoice: (() -> Void)? { get set }
    
    func clear()
}

final class InputView: UIView, InputViewProtocol {
    
    @IBOutlet private weak var rootStackView: UIStackView!

    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var inputTextView: CustomInputTextView!
    
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var cancelRecordingButton: UIButton!
    @IBOutlet private weak var recordingView: UIView!
    @IBOutlet private weak var recordingPulseView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    
    @IBOutlet private weak var recordingResultView: UIView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var resultTimeLabel: UILabel!
    @IBOutlet private weak var removeButton: UIButton!
    @IBOutlet private weak var waveImageView: UIImageView!
    
    
    private let inputStackTag: Int = 1
    private let recordingStackTag: Int = 2
    private let recordingResultStackTag: Int = 3
    
    private let micState = BehaviorRelay<MicrophoneState>(value: .none)
    private let playerState = BehaviorRelay<PlayerState>(value: .pause)
    private var canSend: Bool = false

    private var timer: Observable<NSInteger>?
    private var time: NSInteger = 0
    private var currentTime: NSInteger = 0
    private var timerBag = DisposeBag()
    private var disposeBag = DisposeBag()
    //private var pulseLayers = [CAShapeLayer]()
    
    var onChangeText: ((String) -> Void)?
    var onSendText: (() -> Void)?
    
    var onSendVoice: (() -> Void)?
    var onRecordVoice: (() -> Void)?
    var onClearVoice: (() -> Void)?
    var onPlayVoice: (() -> Void)?
    
    var onStartRecordingVoice: (() -> Void)?
    var onStopRecordingVoice: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
        bind()
    }
    
    func clear() {
        inputTextView.text = nil
        inputTextView.showPlaceholder()
    }
}

private extension InputView {
    func setup() {
        setupViews()
    }
    
    func setupViews() {
        backView.layer.borderWidth = 2
        backView.layer.borderColor = #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 0.5)
        backView.cornerRadius = 8
        
        inputTextView.autocorrectionType = .no
    }
    
    func bind() {
        inputTextView.rx.text
            .orEmpty
            .throttle(.milliseconds(150), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                self?.updateControls(empty: text.isEmpty)
                self?.onChangeText?(text)
            })
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .subscribe({ [weak self] _ in
                let text = self?.inputTextView.text ?? ""
                guard let self = self, !text.isEmpty else { return }
                self.onSendText?()
              })
              .disposed(by: disposeBag)
        
        micButton.rx.tap
            .subscribe({ [weak self] _ in
                guard let self = self else { return }
                //let state = viewModel.microphoneState.value
                //self?.viewModel.microphoneState.accept(state.opposite)
                  //self?.viewModel.beginRecording()
                self.micState.accept(self.micState.value.opposite)
              })
              .disposed(by: disposeBag)
        
        cancelRecordingButton.rx.tap
        .subscribe({ [weak self] _ in
            self?.micState.accept(.none)
          })
          .disposed(by: disposeBag)
        
        removeButton.rx.tap
        .subscribe({ [weak self] _ in
            self?.canSend = false
            self?.onClearVoice?()
            self?.micState.accept(.none)
            self?.playerState.accept(.none)
            self?.removeRecordingResult()
          })
          .disposed(by: disposeBag)
        
        playButton.rx.tap
        .subscribe({ [weak self] _ in
            guard let self = self else { return }
            self.playerState.accept(self.playerState.value.opposite)
          })
          .disposed(by: disposeBag)
        
        micState.subscribe(onNext: { [weak self] state in
            //guard state != .none else { return }
            if self?.canSend == true {
                self?.canSend = false
                self?.onSendVoice?()
                self?.micState.accept(.none)
                self?.playerState.accept(.none)
                self?.removeRecordingResult()
                return
            }
            
            switch state {
            case .recording:
                self?.onStartRecordingVoice?()
            case .stopped:
                self?.onStopRecordingVoice?()
            default: break
            }
            self?.canSend = state == .stopped
            self?.animateMic(state: state)
        }).disposed(by: disposeBag)
        
        playerState.subscribe(onNext: { [weak self] state in
            switch state {
            case .play:
                self?.onPlayVoice?()
            default: break
            }
            self?.animatePlayer(state: state)
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Controls
    func updateControls(empty: Bool) {
        sendButton.isEnabled = !empty
        let image: UIImage = empty ? #imageLiteral(resourceName: "input_send_message") : #imageLiteral(resourceName: "input_recorder_send")
        
        var borderColor: UIColor {
            if empty {
                return #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 0.5)
            } else {
                return #colorLiteral(red: 0.3411764706, green: 0.3019607843, blue: 0.7921568627, alpha: 1)
            }
        }
        
        UIView.transition(with: self.sendButton, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.sendButton.setImage(image, for: .normal)
            self.backView.layer.borderColor = borderColor.cgColor
        })
    }
    
    
    // MARK: - Timer
    
    func stringFromTimeInterval(ms: NSInteger) -> String {
        if playerState.value == .play {
            return String(format: "%0.2d:%0.2d",
                          arguments: [(ms / 600) % 600, (ms % 600) / 20])
        } else {
            return String(format: "%0.2d:%0.2d,%0.2d",
                          arguments: [(ms / 600) % 600, (ms % 600) / 20, ms % 20])
        }
    }
    
    func startTimer() {
        if currentTime >= time {
            currentTime = 0
            resultTimeLabel.text = "00:00"
        }
        
        timer = Observable<NSInteger>
            .interval(.milliseconds(50), scheduler: MainScheduler.instance)
            //.startWith(currentTime)
        
        timer?.subscribe(onNext: { [weak self] ms in
            guard let self = self else { return }
            if self.playerState.value == .play {
                self.currentTime += ms

                if self.currentTime > self.time {
                    self.playerState.accept(.none)
                    self.stopTimer()
                }
            } else {
                self.time += ms
            }
        })
            .disposed(by: timerBag)
        
        if playerState.value == .play {
            timer?.map(stringFromTimeInterval)
                .bind(to: resultTimeLabel.rx.text)
                .disposed(by: timerBag)
        } else {
            timer?.map(stringFromTimeInterval)
                .bind(to: timeLabel.rx.text)
                .disposed(by: timerBag)
        }
    }
    
    func stopTimer() {
        timerBag = DisposeBag()
        timer = nil
        timeLabel.text = "00:00,00"
        recordingPulseView.layer.removeAllAnimations()
    }
    
    // MARK: - States and animation
    func animateMic(state: MicrophoneState) {
        let arrangedInputStackView = rootStackView.arrangedSubviews.first { $0.tag == inputStackTag }
        let arrangedRecordingStackView = rootStackView.arrangedSubviews.first { $0.tag == recordingStackTag }
        let arrangedRecordingResultStackView = rootStackView.arrangedSubviews.first { $0.tag == recordingResultStackTag }

        switch state {
        case .recording:
            arrangedInputStackView?.isHidden = true
            arrangedRecordingStackView?.isHidden = false
            arrangedRecordingResultStackView?.isHidden = true
            startTimer()
            animatePulseView()
        case .stopped:
            arrangedInputStackView?.isHidden = true
            arrangedRecordingStackView?.isHidden = true
            arrangedRecordingResultStackView?.isHidden = false
            stopTimer()
        default:
            arrangedInputStackView?.isHidden = false
            arrangedRecordingStackView?.isHidden = true
            arrangedRecordingResultStackView?.isHidden = true
            stopTimer()
        }
        
        // Mic button
        var image: UIImage
        switch state {
        case .recording:
           image = #imageLiteral(resourceName: "input_recorder_stop")
        case .stopped:
           image = #imageLiteral(resourceName: "input_recorder_send")
        default:
           image = #imageLiteral(resourceName: "input_recorder")
        }
        
        UIView.transition(with: self.sendButton, duration: 0.15, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.micButton.setImage(image, for: .normal)
        })
    }
    
    func animatePlayer(state: PlayerState) {
        // Mic button
        var playImage: UIImage
        switch state {
        case .play:
            playImage = #imageLiteral(resourceName: "input_pause")
            startTimer()
            animateWaveColor()
        case .pause:
            playImage = #imageLiteral(resourceName: "input_play")
            stopTimer()
        case .none:
            playImage = #imageLiteral(resourceName: "input_play")
            stopTimer()
            animateWaveColor(isPlaying: false)
        }
        
        UIView.transition(with: playButton, duration: 0.15, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.playButton.setImage(playImage, for: .normal)
        })
    }
    
    func animateWaveColor(isPlaying: Bool = true) {
        if isPlaying {
            waveImageView.tintColor = #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 1)
        } else {
            waveImageView.tintColor = #colorLiteral(red: 0.3411764706, green: 0.3019607843, blue: 0.7921568627, alpha: 1)
        }
    }
    
    func removeRecordingResult() {
        let arrangedInputStackView = rootStackView.arrangedSubviews.first { $0.tag == inputStackTag }
        let arrangedRecordingStackView = rootStackView.arrangedSubviews.first { $0.tag == recordingStackTag }
        let arrangedRecordingResultStackView = rootStackView.arrangedSubviews.first { $0.tag == recordingResultStackTag }
        
        arrangedInputStackView?.isHidden = false
        arrangedRecordingStackView?.isHidden = true
        arrangedRecordingResultStackView?.isHidden = true
        
        let micImage = #imageLiteral(resourceName: "input_recorder")
        let playImage = #imageLiteral(resourceName: "input_play")
        UIView.transition(with: playButton, duration: 0.15, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.playButton.setImage(playImage, for: .normal)
        })
        
        UIView.transition(with: micButton, duration: 0.15, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.micButton.setImage(micImage, for: .normal)
        })
        
        resultTimeLabel.text = "00:00"
        canSend = false
    }
    
    func animatePulseView() {
        // Pulse view
        recordingPulseView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.recordingPulseView.alpha = 0.75
            self.recordingPulseView.transform = .identity
        })
    }
    
    // MARK: - Microphone animation
    
//    func animateMicrophone(state: MicrophoneState) {
//        UIView.transition(with: micButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
//            let image: UIImage = state == .recording ? #imageLiteral(resourceName: "send_mic_tapped") : #imageLiteral(resourceName: "send_mic")
//            self.micButton.setImage(image, for: .normal)
//        }) { _ in
//            guard state == .recording else {
//                self.micButton.layer.removeAllAnimations()
//                self.pulseLayers.forEach { $0.removeFromSuperlayer() }
//                self.pulseLayers.removeAll()
//                return
//            }
//
//            self.micButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
//            self.createPulse()
//
//            UIView.animate(withDuration: 1.0,
//                                       delay: 0,
//                                       usingSpringWithDamping: 0.2,
//                                       initialSpringVelocity: 5,
//                                       options: [.autoreverse, .curveLinear,
//                                                 .repeat, .allowUserInteraction],
//                                       animations: {
//                                        self.micButton.transform = .identity
//                })
//        }
//    }
    
//    func createPulse() {
//        for _ in 0...2 {
//            let circularPath = UIBezierPath(arcCenter: .zero, radius: 44, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
//            let pulseLayer = CAShapeLayer()
//            pulseLayer.path = circularPath.cgPath
//            pulseLayer.lineWidth = 3.0
//            pulseLayer.fillColor = UIColor.clear.cgColor
//            pulseLayer.lineCap = .round
//            pulseLayer.position = micButton.center
//            micButton.layer.addSublayer(pulseLayer)
//            pulseLayers.append(pulseLayer)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            self.animatePulse(index: 0)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                self.animatePulse(index: 1)
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.animatePulse(index: 2)
//                }
//            }
//        }
//    }
    
//    func animatePulse(index: Int) {
//        guard !pulseLayers.isEmpty else { return }
//        pulseLayers[index].strokeColor = UIColor.brandColor.cgColor
//
//        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
//        scaleAnimation.duration = 2.3
//        scaleAnimation.fromValue = 0.0
//        scaleAnimation.toValue = 0.9
//        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
//        scaleAnimation.repeatCount = .greatestFiniteMagnitude
//        pulseLayers[index].add(scaleAnimation, forKey: "scale")
//
//        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
//        opacityAnimation.duration = 2.3
//        opacityAnimation.fromValue = 0.9
//        opacityAnimation.toValue = 0.05
//        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
//        opacityAnimation.repeatCount = .greatestFiniteMagnitude
//        pulseLayers[index].add(opacityAnimation, forKey: "opacity")
//    }
}
