//
//  ViewController.swift
//  ChatBot
//
//  Created by iOS dev on 20/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

enum ScrollPosition {
    case top
    case middle(index: Int)
    case bottom
}

final class ChatViewController: UIViewController {
    
    @IBOutlet private weak var titleView: UIView!
    @IBOutlet private weak var titleViewOffsetConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: CopyableLabel!
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchTableView: UITableView!

    @IBOutlet private weak var inputCustomView: UIView!
    @IBOutlet private weak var inputViewConstraint: NSLayoutConstraint!

    private let voiceManager = VoiceManager.shared
    
    private var isShownSearchResult = BehaviorRelay<Bool>(value: false)
    var inputViewProvider: InputViewProtocol!
    
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
    
    private var didLayoutTitle: Bool = false
                    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupTitle(title: (main: "ПОМОЩНИК ПО САМОЗАНЯТЫМ",
        sub: "\nОнлайн"))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.scrollToBottom(animated: true)
        }
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
        cell.onSelectMic = { [weak self, atIndex] in
            self?.removeCellAnimations(without: atIndex)
        }
//        cell.selectedMic
//            .subscribe(onNext: { [weak self, atIndex] _ in
//                self?.removeCellAnimations(without: atIndex)
//             }).disposed(by: disposeBag)
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

                self.viewModel.answerOutput.onNext(input)
            }).disposed(by: disposeBag)
        cell.onSelectMic = { [weak self, atIndex] in
            self?.removeCellAnimations(without: atIndex)
        }
//        cell.selectedMic
//            .subscribe(onNext: { [weak self, atIndex] _ in
//                self?.removeCellAnimations(without: atIndex)
//                }, onDisposed: {
//                    print("Incoming Mic disposed!")
//            }).disposed(by: disposeBag)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
        
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
//        header.backgroundColor = .clear
//        return header
//    }
}

// MARK: -BindableType
extension ChatViewController: BindableType {
    func bindViewModel() {
        setupTableView()
        bind()
    }
}

private extension ChatViewController {
    func setup() {
        setupViews()
        bindTitle()
        keyboard()
    }
    
    func setupViews() {
        //inputTextView.addDoneButtonOnKeyboard()
        navigationController?.navigationBar.shadowImage = nil
        tableView.roundCorners([.topLeft, .topRight], radius: 32)
        searchTableView.backgroundColor = #colorLiteral(red: 0.9635888934, green: 0.9744213223, blue: 1, alpha: 1)
        searchTableView.tableFooterView = UIView(frame: .zero)
        
        setupInputView()
    }
    
    func setupInputView() {
        let input = InputView.loadNib()
        inputCustomView.addSubview(input)
        inputViewProvider = input
        inputViewProvider?.onChangeText = { [weak self] text in
            self?.viewModel.questionInput.accept(text)
            self?.viewModel.searchSuggestions()
        }
        inputViewProvider?.onSendText = { [weak self] in
              self?.viewModel.sendQuestion()
              self?.inputViewProvider.clear()
        }
        
        inputViewProvider?.onStartRecordingVoice = { [weak self] in
            self?.viewModel.searchResult.onNext([])
            self?.viewModel.record(for: .recording)
        }
        inputViewProvider?.onStopRecordingVoice = { [weak self] in
            self?.viewModel.record(for: .stopped)
        }
        inputViewProvider?.onSendVoice = { [weak self] in
            self?.viewModel.recognizeVoice()
        }
        inputViewProvider?.onPlayVoice = { [weak self] in
            self?.viewModel.play()
        }
        inputViewProvider?.onClearVoice = { [weak self] in
            self?.viewModel.voice.accept(nil)
            self?.viewModel.stop()
        }
        

        input.activateAnchors()
        input.leadingAnchor(to: inputCustomView.leadingAnchor)
            .trailingAnchor(to: inputCustomView.trailingAnchor)
            .topAnchor(to: inputCustomView.topAnchor)
            .heightAnchor(constant: 72)
    }
    
    func bindTitle() {
        viewModel.title
            .subscribe(onNext: { [weak self] title in
                guard let self = self else { return }
                self.setupTitle(title: title)
            })
            .disposed(by: disposeBag)
    }
    
    func setupTitle(title: ChatTitle) {
        let partOne = NSAttributedString(string: title.main,
                                         attributes: [NSAttributedString.Key.font : UIFont.fontTo(.brandFontRegular, size: 19, weight: .bold)])
        let partTwo = NSAttributedString(string: title.sub,
                                         attributes: [NSAttributedString.Key.font : UIFont.fontTo(.brandFontRegular, size: 11, weight: .medium)])
        let buttonTitle = NSMutableAttributedString()
        buttonTitle.append(partOne)
        buttonTitle.append(partTwo)
                        
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.attributedText = buttonTitle
        //navigationItem.titleView = titleLabel
        titleLabel.sizeToFit()
    }
        
    func setupTableView() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = true
                
        tableView.register(OutgoingBubbleTableViewCell.nib, forCellReuseIdentifier: OutgoingBubbleTableViewCell.identifier)
        tableView.register(IncomingBubbleTableViewCell.nib, forCellReuseIdentifier: IncomingBubbleTableViewCell.identifier)
    }
    
    func bind() {
        guard let viewModel = viewModel else { return }
        
        viewModel.messages
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.scrollPosition
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] position in
                self?.scrollToPosition(position: position)
            }).disposed(by: disposeBag)
        
        viewModel.questionInput
            .map { $0 }
            .bind { [weak self] text in
                guard text.isEmpty else { return }
                UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
                    self?.searchTableView.alpha = 0
                    self?.searchTableView.isHidden = true
                })
                self?.inputViewProvider?.clear()
        }
        .disposed(by: disposeBag)
        
        viewModel.searchResult
            .do(onNext: { items in
                let alpha: CGFloat = items.isEmpty ? 0 : 0.99
                UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCrossDissolve, animations: {
                    self.searchTableView.alpha = alpha
                    self.searchTableView.isHidden = items.isEmpty
                })
            })
            .bind(to: searchTableView.rx.items) { (tv, index, text) -> UITableViewCell in
                let cell = UITableViewCell(style: .default, reuseIdentifier: "SuggestionCell")
                cell.backgroundColor = #colorLiteral(red: 0.9635888934, green: 0.9744213223, blue: 1, alpha: 1)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.textColor = #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 1)
                cell.textLabel?.text = text
                return cell
        }
        .disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = true
        tapGesture.delaysTouchesBegan = true
        
        tableView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: { [weak self] recognizer in
            guard recognizer.state == .ended else { return }
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        searchTableView.rx.itemSelected
            .map { index -> String in
                do {
                    return try self.viewModel.searchResult.value()[index.row]
                } catch {
                    return ""
                }
        }
        .subscribe(onNext: { [weak self] text in
            self?.viewModel.questionInput.accept(text)
            self?.viewModel.sendHintQuestion()
            self?.view.endEditing(true)
        })
            .disposed(by: disposeBag)
        
        //        viewModel.microphoneState.subscribe(onNext: { [weak self] state in
        //            guard state != .none else { return }
        //            //self?.animateMicrophone(state: state)
        //            //self?.animateRecordingTime(state: state)
        //            self?.viewModel.record(for: state)
        //        }).disposed(by: disposeBag)
        
        voiceManager.audioRecordingDidFinished = { [weak self] text in
            guard let text = text else { return }
            self?.viewModel.voice.accept(text)
        }
    }
    
    // MARK: - Keyboard
    func keyboard() {
        keyboardHeight
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { keyboardHeight in
                if keyboardHeight == 0 {
                    self.inputViewConstraint.constant = 0
                } else {
                    //if self.bigScreens.contains(UIDevice.current.type) {
                    self.inputViewConstraint.constant = keyboardHeight
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
                self.scrollToPosition(position: .bottom)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Scroll
    func scrollToPosition(position: ScrollPosition) {
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
    
    func scrollToBottom(animated: Bool) {
        let section = tableView.numberOfSections - 1
        let row = tableView.numberOfRows(inSection: section) - 1
        let indexPath = IndexPath(row: row, section: section)
        let _ = dataSource.tableView(self.tableView, cellForRowAt: indexPath)
        let t: DispatchTime = .now() + TimeInterval(0.001)// magic
        
        DispatchQueue.main.asyncAfter(deadline: t) {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    // MARK: - TableView cells
    func removeCellAnimations(without indexPath: IndexPath) {
        let indexPaths = tableView.indexPathsForVisibleRows?.filter { indexPath != $0 }
        indexPaths?.forEach {
            (tableView.cellForRow(at: $0) as? IncomingBubbleTableViewCell)?.clear()
            (tableView.cellForRow(at: $0) as? OutgoingBubbleTableViewCell)?.clear()
        }
    }
}

