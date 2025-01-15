//
//  CompressTabViewController.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//

import UIKit

class CompressTabViewController: UIViewController, StoryboardInstantiable {
    var viewModel: MainViewModel?
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyTitle: UILabel!
    @IBOutlet weak var emptyBody: UILabel!
    
    @IBOutlet weak var infoView: UIStackView!
    
    @IBOutlet weak var settingView: UIView!
    @IBOutlet weak var qualityTitle: UILabel!
    @IBOutlet weak var qualityBody: UILabel!
    @IBOutlet weak var sizeTitle: UILabel!
    @IBOutlet weak var sizeBody: UILabel!
    
    @IBOutlet weak var selectedImgView: UIImageView!
    @IBOutlet weak var imgNameLB: UILabel!
    @IBOutlet weak var imgTimeLB: UILabel!
    @IBOutlet weak var imgSizeLB: UILabel!
    @IBOutlet weak var changePhotoBtn: UIButton!
    @IBOutlet weak var saveView: UIStackView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var qualityLevel: UISegmentedControl!
    @IBOutlet weak var sizeLevel: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCV()
        if let viewModel = viewModel {
            bind(to: viewModel)
        }
        setupAdView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.changePhotoBtn.layer.cornerRadius = self.changePhotoBtn.bounds.height / 2
    }
    private func setupCV() {
        self.infoView.isHidden = true
        self.settingView.isHidden = true
        self.emptyView.layer.cornerRadius = 35
        self.shareBtn.layer.cornerRadius = 35
        self.saveBtn.layer.cornerRadius = 35
        self.navigationController?.navigationBar.isHidden = true
        self.emptyTitle.text = NSLocalizedString("add_photo_title", comment: "")
        self.emptyBody.text = NSLocalizedString("add_photo_body", comment: "")
        self.qualityTitle.text = NSLocalizedString("image_weight", comment: "")
        self.qualityBody.text = NSLocalizedString("image_weight_body", comment: "")
        self.sizeTitle.text = NSLocalizedString("image_size", comment: "")
        self.sizeBody.text = NSLocalizedString("image_size_body", comment: "")
        self.qualityLevel.setTitle(NSLocalizedString("original", comment: ""), forSegmentAt: 0)
        self.qualityLevel.setTitle(NSLocalizedString("normal", comment: ""), forSegmentAt: 1)
        self.qualityLevel.setTitle(NSLocalizedString("low", comment: ""), forSegmentAt: 2)
        self.qualityLevel.setTitle(NSLocalizedString("minimum", comment: ""), forSegmentAt: 3)
        
        self.sizeLevel.setTitle(NSLocalizedString("original", comment: ""), forSegmentAt: 0)
    }
    
    private func setupSegment() {
        
    }
    
    private func setupAdView() {
        AdmobManager.shared.setMainBanner(adView, self, .mainBanner)
        AdmobManager.shared.setRewardAds(self, .createPage)
    }
     
    private func bind(to viewModel: MainViewModel) {
        viewModel.photoLibraryOnlyAddPermission.observe(on: self) { [weak self] hasPermission in
            guard let hasPermission = hasPermission, let img = self?.viewModel?.selectedImg.value else { return }
            guard hasPermission else {
                DispatchQueue.main.async {
                    self?.showPermissionAlert()
                }
                return
            }
            
            viewModel.imageSave(completion: { isSuccess in
                print(isSuccess)
                // TODO: - 광고가 닫히고 팝업을 띄워줘야함.
                DispatchQueue.main.async {
                    self?.showSaveAlert()
                }
            })
            
            AdmobManager.shared.setRewardAds(self!, .createPage)
        }
        viewModel.photoLibraryPermission.observe(on: self) { [weak self] hasPermission in
            guard let hasPermission = hasPermission else { return }
            guard hasPermission else {
                DispatchQueue.main.async {
                    self?.showPermissionAlert()
                }
                return
            }
            guard let strongSelf = self else { return }
            self?.viewModel?.openImagePicker(strongSelf)
        }
        
        viewModel.selectedImg.observe(on: self) { [weak self] image in
            self?.updateImageView(image)
        }
        
        viewModel.needReset.observe(on: self) { [weak self] _ in
            self?.resetSg()
        }
    }
    
    private func resetSg() {
        self.sizeLevel.selectedSegmentIndex = 0
        self.qualityLevel.selectedSegmentIndex = 0
    }
    
    private func updateImageView(_ imageData: ImageWithMetadata?) {
        DispatchQueue.main.async { [weak self] in
            if let data = imageData {
                self?.updateEmptyView(false)
                self?.selectedImgView.image = UIImage(data: data.imgData)
                self?.updateImageInfoView(data)
            }else {
                self?.updateEmptyView(true)
            }
        }
    }
    
    private func updateEmptyView(_ isEmpty: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.emptyView.isHidden = !isEmpty
            self?.infoView.isHidden = isEmpty
            self?.settingView.isHidden = isEmpty
            self?.saveView.isUserInteractionEnabled = !isEmpty
            self?.saveView.alpha = isEmpty ? 0.5 : 1
        }
    }
    
    private func updateImageInfoView(_ img: ImageWithMetadata) {
        DispatchQueue.main.async { [weak self] in
            self?.imgNameLB.text = img.imgName
            if let dateTime = img.asset?.creationDate as? Date, let time = self?.viewModel?.formatImageDate(dateTime) {
                self?.imgTimeLB.text = time
            }else {
                self?.imgTimeLB.isHidden = true
            }
            if let image = UIImage(data: img.imgData) {
                self?.imgSizeLB.text = "\(Int(image.size.width)) x \(Int(image.size.height)) | \(formatByteCount(img.originImgData.count))"
                
                // 사람이 읽기 좋은 파일 크기 형식으로 변환
                func formatByteCount(_ byteCount: Int) -> String {
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useBytes, .useKB, .useMB]
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: Int64(byteCount))
                }
                
            }else {
                self?.imgSizeLB.isHidden = true
            }
        }
    }
    
    private func showSaveAlert() {
        let alert = UIAlertController(title: NSLocalizedString("download_complete", comment: "Download Complete"),
                                      message: NSLocalizedString("download_complete_body", comment: "The image has been saved to the gallery."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment:"OK"), style: .default) {_ in
            
        })
        present(alert, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(title: NSLocalizedString("photo_permission_title", comment:"Photo Access Permission Required"),
                                      message: NSLocalizedString("photo_permission_body", comment:"Photo access permission is required to save the photo. Please change the permission in Settings."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment:"Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("go_setting", comment:"Go to Settings"), style: .default, handler: { [weak self] _ in
            self?.viewModel?.openAppSettings()
        }))
        present(alert, animated: true)
    }
    
    @IBAction func addPhotoBtn(_ sender: Any) {
        self.viewModel?.checkPhotoLibraryPermission()
    }
    
    @IBAction func changePhotoBtn(_ sender: Any) {
        self.viewModel?.openImagePicker(self)
    }
    
    @IBAction func shareBtn(_ sender: Any) {
        self.viewModel?.shareImage(self)
    }
    
    @IBAction func saveBtn(_ sender: Any) {
        AdmobManager.shared.showRewardAds {
            self.viewModel?.checkPhotoLibraryOnlyAddPermission()
        }
    }
    
    @IBAction func qualitySg(_ sender: Any) {
        guard let sg = sender as? UISegmentedControl else {
            return
        }
        
        self.viewModel?.changeImageQuality(level: sg.selectedSegmentIndex)
    }
    @IBAction func sizeSg(_ sender: Any) {
        guard let sg = sender as? UISegmentedControl else {
            return
        }
        
        self.viewModel?.changeImageSize(level: sg.selectedSegmentIndex)
    }
    
}

