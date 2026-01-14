//
//  ImageQuality.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 압축 품질을 나타내는 enum
/// Domain Layer - Pure Swift, UIKit 무의존
enum ImageQuality: Double, CaseIterable {
    case original = 1.0
    case high = 0.8
    case normal = 0.5
    case low = 0.3
    case minimum = 0.1

    /// 품질 레벨 인덱스로부터 ImageQuality 생성
    static func from(level: Int) -> ImageQuality {
        switch level {
        case 0: return .original
        case 1: return .normal
        case 2: return .low
        case 3: return .minimum
        default: return .original
        }
    }

    /// 압축 품질 값 (0.0 ~ 1.0)
    var compressionQuality: Double {
        return self.rawValue
    }

    /// CGFloat 값으로부터 가장 가까운 ImageQuality 생성
    static func from(cgFloat value: CGFloat) -> ImageQuality {
        let doubleValue = Double(value)
        if doubleValue >= 0.9 {
            return .original
        } else if doubleValue >= 0.6 {
            return .high
        } else if doubleValue >= 0.4 {
            return .normal
        } else if doubleValue >= 0.2 {
            return .low
        } else {
            return .minimum
        }
    }
}
