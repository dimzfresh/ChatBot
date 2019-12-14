//
//  ViewController.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 20/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

enum ScorllPosition {
    case top
    case middle(index: Int)
    case bottom
}

final class ChatViewController: UIViewController, BindableType {
    
    @IBOutlet private weak var titleButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var inputTextView: CustomInputView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var inputStackViewConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var recordingView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var recordingStackView: UIStackView!
    @IBOutlet private weak var emptyStackView: UIStackView!
    
    @IBOutlet private weak var searchTableView: UITableView!
    
    private var timer: Observable<NSInteger>?
    private var timerBag = DisposeBag()

    private let voiceManager = VoiceManager.shared
    private var pulseLayers = [CAShapeLayer]()
    
    private var isShownSearchResult = BehaviorRelay<Bool>(value: false)
    
    var viewModel: ChatViewModel!
    
    private let disposeBag = DisposeBag()
            
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionOfChat>(configureCell: configureCell)
    private lazy var configureCell: RxTableViewSectionedReloadDataSource<SectionOfChat>.ConfigureCell = { [weak self] (dataSource, tableView, indexPath, item) in
        guard let self = self else { return UITableViewCell() }
        
        let section = dataSource.sectionModels[indexPath.section]
        guard case let TableViewItem.message(message) = item else {
            return UITableViewCell()
        }
        
        switch section.model {
        case .outgoing:
            return self.configOutgoingCell(for: message, atIndex: indexPath)
        case .incoming:
            return self.configIncomingCell(for: message, atIndex: indexPath)
        }
    }
                    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

extension ChatViewController: UITableViewDelegate {
    func configOutgoingCell(for message: ChatModel, atIndex: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeue(OutgoingBubbleTableViewCell.self) else {
            return UITableViewCell()
        }
        let vm = OutgoingViewModel()
        vm.message = message
        cell.bind(to: vm)
        cell.selectedMic
            .subscribe(onNext: { [weak self, atIndex] _ in
                self?.removeCellAnimations(without: atIndex)
             }).disposed(by: disposeBag)
    
        return cell
    }
    
    func configIncomingCell(for message: ChatModel, atIndex: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeue(IncomingBubbleTableViewCell.self) else {
            return UITableViewCell()
        }
        let vm = IncomingViewModel()
        vm.message = message
        cell.bind(to: vm)
        cell.selectedItem
            .subscribe(onNext: { [weak self, atIndex] answer in
                guard let self = self, let answer = answer else { return }
                var input = AnswerRequestInput(text: "")
                input.content = answer.content ?? ""
                let section = self.dataSource.sectionModels[atIndex.section]
                if case let TableViewItem.message(message) = section.items[atIndex.row] {
                    input.id = "\(message.dialogID ?? 0)"
                }
                input.type = "\(answer.type ?? 0)"

                self.viewModel.answerOutput.on(.next(input))
            }).disposed(by: disposeBag)
        cell.selectedMic
            .subscribe(onNext: { [weak self, atIndex] _ in
                self?.removeCellAnimations(without: atIndex)
             }).disposed(by: disposeBag)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ChatViewController {
    private func setup() {
        setupViews()
        bindTitle()
        keyboard()
    }
    
    private func setupViews() {
        //inputTextView.addDoneButtonOnKeyboard()
        recordingStackView.alpha = 0
        searchTableView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        searchTableView.tableFooterView = UIView(frame: .zero)
    }
    
    func stringFromTimeInterval(ms: NSInteger) -> String {
        return String(format: "%0.2d:%0.2d,%0.2d",
            arguments: [(ms / 600) % 600, (ms % 600) / 20, ms % 20])
    }
    
    func startTimer() {
        timer = Observable<NSInteger>.interval(.milliseconds(50), scheduler: MainScheduler.instance)
//        timer?.subscribe(onNext: { [weak self] ms in
//            print(ms)
//        })
//        .disposed(by: timerBag)
        
        timer?.map(stringFromTimeInterval)
            .bind(to: timeLabel.rx.text)
            .disposed(by: timerBag)
    }
    
    func stopTimer() {
        timerBag = DisposeBag()
        timer = nil
    }
    
    private func bindTitle() {
        viewModel.title
            .subscribe(onNext: { [weak self] title in
                guard let self = self else { return }
                self.setupTitle(title: title)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupTitle(title: ChatTitle) {
        let partOne = NSAttributedString(string: title.main,
                                         attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold)])
        let partTwo = NSAttributedString(string: title.sub,
                                         attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular)])
        let buttonTitle = NSMutableAttributedString()
        buttonTitle.append(partOne)
        buttonTitle.append(partTwo)
        
        titleButton.titleLabel?.numberOfLines = 0
        titleButton.titleLabel?.lineBreakMode = .byWordWrapping
        titleButton.setAttributedTitle(buttonTitle, for: .normal)
        titleButton.titleLabel?.textAlignment = .left
        titleButton.sizeToFit()
    }
        
    private func setupTableView() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.keyboardDismissMode = .interactive
        
        tableView.register(OutgoingBubbleTableViewCell.nib, forCellReuseIdentifier: OutgoingBubbleTableViewCell.identifier)
        tableView.register(IncomingBubbleTableViewCell.nib, forCellReuseIdentifier: IncomingBubbleTableViewCell.identifier)
    }
    
    // MARK: BindableType
    
    func bindViewModel() {
        setupTableView()
        bind()
    }
    
    private func bind() {
        guard let viewModel = viewModel else { return }
                        
        viewModel.messages
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.scrollPosition
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] position in
                    self?.scrollToPosition(position: position)
               }).disposed(by: disposeBag)

        inputTextView.rx.text
            .orEmpty
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
//            .flatMapLatest({ query -> BehaviorRelay<String> in
//                if query.isEmpty {
//                    return .init(value: "")
//                } else {
//                    return
//                }
//            })
            .do(onNext: { [weak self] text in
                self?.viewModel.questionInput.accept(text)
                self?.viewModel.searchSuggestions()
                self?.updateControls(empty: text.isEmpty)
            })
            .bind(to: viewModel.questionInput)
            .disposed(by: disposeBag)
        
        viewModel.questionInput
            .asObservable()
            .bind { [weak self] text in
                self?.inputTextView.text = text
        }
        .disposed(by: disposeBag)
        
        viewModel.searchResult
            .asObservable()
            .do(onNext: { items in
                let alpha: CGFloat = items.isEmpty ? 0 : 0.99
                UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
                    self.searchTableView.alpha = alpha
                    self.searchTableView.isHidden = items.isEmpty
                })
            })
            .bind(to: searchTableView.rx.items) { (tv, index, text) -> UITableViewCell in
                let cell = UITableViewCell(style: .default, reuseIdentifier: "SuggestionCell")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = text
                return cell
            }
        .disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: nil)
        tapGesture.cancelsTouchesInView = true
        tableView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: { [weak self] recognizer in
            guard recognizer.state == .ended else { return }
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
                
        searchTableView.rx.itemSelected
            .map({ index -> String in
                do {
                    return try self.viewModel.searchResult.value()[index.row]
                } catch {
                    return ""
                }
            })
        .subscribe(onNext: { [weak self] text in
            self?.viewModel.questionInput.accept(text)
            self?.viewModel.sendQuestion()
        })
        .disposed(by: disposeBag)
        
        sendButton.rx.tap
            //.debounce(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
                self?.viewModel.sendQuestion()
            })
            .disposed(by: disposeBag)
        
        micButton.rx.tap
            .subscribe({ [weak self] _ in
                let state = viewModel.microphoneState.value
                self?.viewModel.microphoneState.accept(state.opposite)
                  //self?.viewModel.beginRecording()
              })
              .disposed(by: disposeBag)
        
        viewModel.microphoneState.subscribe(onNext: { [weak self] state in
            guard state != .none else { return }
            self?.animateMicrophone(state: state)
            self?.animateRecordingTime(state: state)
            self?.viewModel.record(for: state)
        }).disposed(by: disposeBag)
        
        voiceManager.audioRecordingDidFinished = { [weak self] text in
            guard let text = text else { return }
            self?.viewModel.voice.accept(text)
        }
    }
    
    // MARK: - Keyboard
    private func keyboard() {
        inputTextView.autocorrectionType = .no
        keyboardHeight
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { keyboardHeight in
                if keyboardHeight == 0 {
                    self.inputStackViewConstraint.constant = 20
                } else {
                    if self.bigScreens.contains(UIDevice.current.type) {
                        self.inputStackViewConstraint.constant = 18 + keyboardHeight
                    } else {
                        self.inputStackViewConstraint.constant = 8 + keyboardHeight
                    }
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
                self.scrollToPosition(position: .bottom)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Scroll
    private func scrollToPosition(position: ScorllPosition) {
        switch position {
        case .top:
            let indexPath = IndexPath.init(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            break
        case let .middle(index: index):
            let indexPath = IndexPath.init(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            break
        case .bottom:
            scrollToBottom(animated: true)
            break
        }
    }
    
    private func removeCellAnimations(without indexPath: IndexPath) {
        let indexPaths = tableView.indexPathsForVisibleRows?.filter { indexPath != $0 }
        indexPaths?.forEach {
            (tableView.cellForRow(at: $0) as? IncomingBubbleTableViewCell)?.clear()
            (tableView.cellForRow(at: $0) as? OutgoingBubbleTableViewCell)?.clear()
        }
    }
    
    private func scrollToBottom(animated: Bool) {
        let section = tableView.numberOfSections - 1
        let row = tableView.numberOfRows(inSection: section) - 1
        let indexPath = IndexPath(row: row, section: section)
        let _ = dataSource.tableView(self.tableView, cellForRowAt: indexPath)
        let t: DispatchTime = .now() + TimeInterval(0.001)// magic
        
        DispatchQueue.main.asyncAfter(deadline: t) {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    // MARK: - Controls
    func updateControls(empty: Bool) {
        if empty {
            UIView.animate(withDuration: 0.25, animations: {
                self.inputTextView.placeHolderLabel.alpha = 0.5
            }, completion: nil)
            UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
                self.searchTableView.alpha = 0
                self.searchTableView.isHidden = true
            })
        }
        self.sendButton.isEnabled = !empty
        let image: UIImage = empty ? #imageLiteral(resourceName: "send_button_empty") : #imageLiteral(resourceName: "send_button_ok")
        UIView.transition(with: self.sendButton, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.sendButton.setImage(image, for: .normal)
        })
    }
    
    // MARK: - Microphone animation
    
    func animateMicrophone(state: MicrophoneState) {
        UIView.transition(with: micButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            let image: UIImage = state == .recording ? #imageLiteral(resourceName: "send_mic_tapped") : #imageLiteral(resourceName: "send_mic")
            self.micButton.setImage(image, for: .normal)
        }) { _ in
            guard state == .recording else {
                self.micButton.layer.removeAllAnimations()
                self.pulseLayers.forEach { $0.removeFromSuperlayer() }
                self.pulseLayers.removeAll()
                return
            }
            
            self.micButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.createPulse()

            UIView.animate(withDuration: 1.0,
                                       delay: 0,
                                       usingSpringWithDamping: 0.2,
                                       initialSpringVelocity: 5,
                                       options: [.autoreverse, .curveLinear,
                                                 .repeat, .allowUserInteraction],
                                       animations: {
                                        self.micButton.transform = .identity
                })
        }
    }
    
    func createPulse() {
        for _ in 0...2 {
            let circularPath = UIBezierPath(arcCenter: .zero, radius: 44, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            let pulseLayer = CAShapeLayer()
            pulseLayer.path = circularPath.cgPath
            pulseLayer.lineWidth = 3.0
            pulseLayer.fillColor = UIColor.clear.cgColor
            pulseLayer.lineCap = .round
            pulseLayer.position = micButton.center
            micButton.layer.addSublayer(pulseLayer)
            pulseLayers.append(pulseLayer)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.animatePulse(index: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.animatePulse(index: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.animatePulse(index: 2)
                }
            }
        }
    }
    
    func animatePulse(index: Int) {
        guard !pulseLayers.isEmpty else { return }
        pulseLayers[index].strokeColor = UIColor.brandColor.cgColor

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 2.3
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 0.9
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleAnimation.repeatCount = .greatestFiniteMagnitude
        pulseLayers[index].add(scaleAnimation, forKey: "scale")
        
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.duration = 2.3
        opacityAnimation.fromValue = 0.9
        opacityAnimation.toValue = 0.05
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        opacityAnimation.repeatCount = .greatestFiniteMagnitude
        pulseLayers[index].add(opacityAnimation, forKey: "opacity")
    }
    
    func animateRecordingTime(state: MicrophoneState) {
        if state == .recording {
            recordingStackView.alpha = 1
            startTimer()
        } else {
            recordingStackView.alpha = 0
            stopTimer()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.recordingView.alpha = 0.25
        })
    }
}
