//
//  ScanQRTabViewController.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//

import Foundation
import UIKit
import AVFoundation

class ScanQRTabViewController: UIViewController, StoryboardInstantiable, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    var viewModel: MainViewModel?
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var photoBtn: UIButton!
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
//    let qrView: QRScanView = QRScanView()
    lazy var dismissBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        return btn
    }()
    
    // 카메라 미리보기 뷰
    private let cameraPreviewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        setupBindings()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ScanQRTabViewController viewDidAppear")
        setupView()
        setupCameraView()
        viewModel?.checkCameraPermission()
    }
    
    private func setupView() {
        bottomView.backgroundColor = .speedMain3
        bottomView.roundTopCorners(cornerRadius: 30)
        
        photoBtn.setTitle(NSLocalizedString("Scan from Gallery", comment: ""), for: .normal)
        photoBtn.layer.cornerRadius = 10
        photoBtn.layer.borderWidth = 2.0
        photoBtn.layer.borderColor = UIColor.speedMain2.cgColor
    }
    
    private func setupCameraView() {
        cameraView.addSubview(cameraPreviewView)
        cameraPreviewView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: AVCaptureSession())
        previewLayer?.frame = self.view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        cameraPreviewView.layer.addSublayer(previewLayer!)
        
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("ScanQRTabViewController viewDidDisappear")
        previewLayer?.removeFromSuperlayer()
        self.previewLayer = nil
    }
    
    private func setupBindings() {
        
    }
    
    // 권한 요청 알림
    private func showPermissionAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Camera Permission Required", comment:"Camera Permission Required"),
                                      message: NSLocalizedString("Please allow camera access to scan the QR code.", comment:"Please allow camera access to scan the QR code."),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Go to Settings", comment:"Go to Settings"), style: .default, handler: { [weak self] _ in
            self?.viewModel?.openAppSettings()
        }))
        present(alert, animated: true)
    }
    
}
