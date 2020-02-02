//
//  FirebaseEvent.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 28.01.2020.
//  Copyright © 2020 kvantsoft. All rights reserved.
//

import Foundation

protocol EventDescribingProtocol: RawRepresentable {
    var name: String { get }
    var identifier: String { get }
}

// MARK: - Enums
enum TargetEvent {
    case chat(ChatEvent)
    case share(ShareEvent)
    case voice(VoiceEvent)
}

enum ChatEvent: String, EventDescribingProtocol {
    case question = "Задан вопрос текстом"
    case hint = "Просмотр или выбор подсказок при вводе"
    case answerButton = "Выбран ответ для просмотра (нажали 1,2,3,4,5)"
    case answerNumber = "Номер выбранного ответа"
    
    var name: String { "chat_event" }
    
    var identifier: String {
        switch self {
        case .question:
            return "text_question"
        case .hint:
            return "view_suggestion"
        case .answerButton:
            return "button_answer_selected"
        case .answerNumber:
            return "selected_answer_number"
        }
    }
}

enum ShareEvent: String, EventDescribingProtocol {
    case open = "Открыто контекстное меню (копировать / поделиться)"
    case share = "Поделиться ответом"
    case copy = "Скопировать ответ"
    var name: String { "share_event" }
    
    var identifier: String {
        switch self {
        case .open:
            return "context_menu_opened"
        case .share:
            return "answer_share"
        case .copy:
            return "answer_copy"
        }
    }
}

enum VoiceEvent: String, EventDescribingProtocol {
    case record = "Записан голосовой вопрос"
    case delete = "Удален голосовой вопрос"
    case playQuestion = "Прослушан голосовой вопрос перед отправкой"
    case question = "Вопрос задан голосом"
    case playAnswer = "Ответ прослушан голосом"
    var name: String { "voice_event" }
    
    var identifier: String {
        switch self {
        case .record:
            return "voice_question_recorded"
        case .delete:
            return "voice_question_deleted"
        case .playQuestion:
            return "voice_question_played"
        case .question:
            return "voice_question_sended"
        case .playAnswer:
            return "voice_answer_played"
        }
    }
}

protocol EventInputProtocol {
    associatedtype TargetEnum
    var event: TargetEnum { get set }
    init(_ event: TargetEnum)
}

struct EventInput: EventInputProtocol {
    typealias TargetEnum = TargetEvent
    var event: TargetEnum
    
    init(_ event: TargetEnum) {
        self.event = event
    }
}
