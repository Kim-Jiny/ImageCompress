//
//  ImageWithMetadata.swift
//  ImageCompress
//
//  Created by 김미진 on 12/26/24.
//

import Foundation
import Photos

struct ImageWithMetadata {
    var imgName: String
    var imgData: Data
    var metaData: [String: Any]
    var asset: PHAsset?
}
