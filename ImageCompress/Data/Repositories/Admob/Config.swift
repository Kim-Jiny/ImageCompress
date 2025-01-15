//
//  Config.swift
//  ImageCompress
//
//  Created by 김미진 on 11/18/24.
//

import Foundation

enum AdmobType {
    case mainBanner, createPage
    
    var getKey: String {
        
#if DEBUG
        switch self {
        case .mainBanner:
            "ca-app-pub-3940256099942544/2934735716"
        case .createPage:
            "ca-app-pub-3940256099942544/6978759866"
        }
#else
        switch self {
        case .mainBanner:
            "ca-app-pub-2707874353926722/81341568301"
        case .createPage:
            "ca-app-pub-2707874353926722/2498686773"
        }
#endif
    }
}
