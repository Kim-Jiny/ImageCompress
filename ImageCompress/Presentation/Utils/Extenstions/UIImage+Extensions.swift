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
}
