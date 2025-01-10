//
//  UIImage+Extensions.swift
//  ImageCompress
//
//  Created by 김미진 on 12/26/24.
//

import Foundation
import UIKit

extension UIImage {
    
    func applyingExifMetadata(_ metadata: [String: Any]) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let properties: CFDictionary = metadata as CFDictionary
        let context = CIContext()

        let ciImage = CIImage(cgImage: cgImage)
        let metadataImage = ciImage.applyingFilter("CIAffineTransform", parameters: ["inputTransform": NSValue(caTransform3D: CATransform3DIdentity)])
        
        let resultCGImage = context.createCGImage(metadataImage, from: ciImage.extent, format: .RGBA8, colorSpace: cgImage.colorSpace!)
        return resultCGImage.map { UIImage(cgImage: $0, scale: self.scale, orientation: self.imageOrientation) }
    }
    
    func pixelSize() -> CGSize {
        guard let cgImage = self.cgImage else {
            return .zero
        }
        
        // cgImage's width and height are in pixels
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        return CGSize(width: width, height: height)
    }
    
    
    func fixedOrientation() -> UIImage {
        // 방향이 .up(기본 방향)이면 그대로 반환
        if imageOrientation == .up {
            return self
        }
        
        // 현재 이미지의 CGImage와 크기를 기반으로 컨텍스트 생성
        guard let cgImage = self.cgImage else { return self }
        
        let contextSize = CGSize(width: self.size.width, height: self.size.height)
        UIGraphicsBeginImageContextWithOptions(contextSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        
        // 변환 설정
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: contextSize.width, y: contextSize.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: contextSize.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: contextSize.height)
            transform = transform.rotated(by: -.pi / 2)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        context?.concatenate(transform)
        
        // 미러링 처리
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -contextSize.width, y: 0)
        case .leftMirrored, .rightMirrored:
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -contextSize.height, y: 0)
        default:
            break
        }
        
        // 이미지 그리기
        context?.draw(cgImage, in: CGRect(origin: .zero, size: contextSize))
        
        // 수정된 이미지 반환
        let fixedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return fixedImage ?? self
    }
}
