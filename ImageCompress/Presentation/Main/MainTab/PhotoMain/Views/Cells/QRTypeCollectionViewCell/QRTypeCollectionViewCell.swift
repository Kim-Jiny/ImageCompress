//
//  QRTypeCollectionViewCell.swift
//  ImageCompress
//
//  Created by 김미진 on 11/8/24.
//

import UIKit

class QRTypeCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var typeImg: UIImageView!
    @IBOutlet weak var typeLB: UILabel!
    
    static var id: String {
        return NSStringFromClass(Self.self).components(separatedBy: ".").last!
    }
    private var viewModel: QRTypeItemViewModel!

    func fill(
        with viewModel: QRTypeItemViewModel
    ) {
        self.viewModel = viewModel
        self.typeImg.image = viewModel.titleImage
        self.typeLB.text = viewModel.title
        self.layer.cornerRadius = 20
        self.backgroundColor = .speedMain3
    }
    
    func setSelectedAppearance(_ selected: Bool) {
        if selected {
            self.layer.borderWidth = 2.0
            self.layer.borderColor = UIColor.speedMain2.cgColor
        } else {
            self.layer.borderWidth = 0.0
            self.layer.borderColor = nil
        }
    }
}
