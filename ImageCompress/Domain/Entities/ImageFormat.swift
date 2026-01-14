//
//  ImageFormat.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 포맷을 나타내는 enum
/// Domain Layer - Pure Swift, UIKit 무의존
enum ImageFormat: String, CaseIterable {
    case jpeg = "jpeg"
    case png = "png"

    /// 파일 확장자
    var fileExtension: String {
        return self.rawValue
    }

    /// MIME 타입
    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        }
    }

    /// UserDefaults 저장용 키 값으로부터 생성
    static func from(storedValue: String?) -> ImageFormat {
        guard let value = storedValue else { return .jpeg }
        return ImageFormat(rawValue: value) ?? .jpeg
    }
}
