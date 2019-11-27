//
//  SearchModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 27/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation

// MARK: - SearchModel
public struct SearchModel: Codable {
    let suggestions: [Suggestion]?
}

// MARK: - Suggestion
public struct Suggestion: Codable {
    let text: String?
}

