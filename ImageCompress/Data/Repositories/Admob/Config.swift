//
//  Config.swift
//  ImageCompress
//
//  Created by 김미진 on 11/18/24.
//

import Foundation

enum AdmobType {
    case mainBanner, createPage, settingBanner
    
    var getKey: String {
        
#if DEBUG
        switch self {
        case .mainBanner:
            "ca-app-pub-3940256099942544/2934735716"
        case .createPage:
            "ca-app-pub-3940256099942544/6978759866"
        case .settingBanner:
            "ca-app-pub-3940256099942544/2934735716"
        }
#else
        switch self {
        case .mainBanner:
            "ca-app-pub-2707874353926722/8134156830"
        case .createPage:
            "ca-app-pub-2707874353926722/2498686773"
        case .settingBanner:
            "ca-app-pub-2707874353926722/5450247191"
        }
#endif
    }
}
