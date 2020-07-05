//
//  HyperLinks.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 04.06.2020.
//  Copyright © 2020 kvantsoft. All rights reserved.
//

import Foundation

enum HyperLinks: String, CaseIterable {
    case http, https, ftp, ftps, www
    case ru = ".ru"
    case rf = ".рф"
    case com = ".com"
    case org = ".org"
    case rff = ".rf"
    case info = ".info"
    case net = ".net"
    case moscow = ".moscow"
}
