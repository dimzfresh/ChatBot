//
//  CaseItarable.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 04.06.2020.
//  Copyright © 2020 kvantsoft. All rights reserved.
//

import Foundation

extension CaseIterable where Self: RawRepresentable, Self.RawValue == String {
    static var all: [String] {
        return Array(self.allCases).map { $0.rawValue }
    }
}

extension CaseIterable where Self: RawRepresentable, Self.RawValue == Int {
    static var all: [Int] {
        return Array(self.allCases).map { $0.rawValue }
    }
}

extension CaseIterable where Self: Equatable {
    func ordinal() -> Self.AllCases.Index? {
        return Self.allCases.firstIndex(of: self)
    }
}
