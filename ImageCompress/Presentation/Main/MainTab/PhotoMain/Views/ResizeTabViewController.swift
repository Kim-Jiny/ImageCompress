//
//  ResizeTabViewController.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//
import UIKit


class ResizeTabViewController: UIViewController, StoryboardInstantiable {
    var viewModel: MainViewModel?
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var adView: UIView!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyTitle: UILabel!
    @IBOutlet weak var emptyBody: UILabel!
    
    @IBOutlet weak var infoView: UIStackView!
    
    @IBOutlet weak var settingView: UIView!
    @IBOutlet weak var settingTitle: UILabel!
    @IBOutlet weak var settingBody: UILabel!
    
    @IBOutlet weak var selectedImgView: UIImageView!
    @IBOutlet weak var imgNameLB: UILabel!
    @IBOutlet weak var imgTimeLB: UILabel!
    @IBOutlet weak var imgSizeLB: UILabel!
    @IBOutlet weak var changePhotoBtn: UIButton!
    @IBOutlet weak var saveView: UIStackView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var qualityLevel: UISegmentedControl!
    
    private var isFirstSelectionDone = false
    private var colorPickerManager = ColorPickerManager()
    
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
        
        self.emptyTitle.text = NSLocalizedString("Click the button to add a photo.", comment: "")
        self.emptyBody.text = NSLocalizedString("After adding a photo, the save button will be enabled.", comment: "")
        self.settingTitle.text = NSLocalizedString("Image Size", comment: "")
        self.settingBody.text = NSLocalizedString("Smaller image sizes result in reduced file size.\nCheck the resized image through the image preview at the top.", comment: "")
    }
    
    
    private func setupAdView() {
        AdmobManager.shared.setMainBanner(adView, self, .main)
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
                DispatchQueue.main.async {
                    self?.showSaveAlert()
                }
            })
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
            //TODO: 저장버튼 활성화
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
            if let image = UIImage(data: img.imgData)?.cgImage {
                self?.imgSizeLB.text = "\(image.width) x \(image.height) | \(formatByteCount(img.originImgData.count))"
                
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
        let alert = UIAlertController(title: NSLocalizedString("Download Complete", comment: "Download Complete"),
                                      message: NSLocalizedString("The image has been saved to the gallery.", comment: "The image has been saved to the gallery."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: .default) {_ in
            
        })
        present(alert, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Photo Access Permission Required", comment:"Photo Access Permission Required"),
                                      message: NSLocalizedString("Photo access permission is required to save the photo. Please change the permission in Settings.", comment:"Photo access permission is required to save the photo. Please change the permission in Settings."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Go to Settings", comment:"Go to Settings"), style: .default, handler: { [weak self] _ in
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
        self.viewModel?.checkPhotoLibraryOnlyAddPermission()
    }
    
    @IBAction func qualitySg(_ sender: Any) {
        guard let sg = sender as? UISegmentedControl else {
            return
        }
        
        self.viewModel?.changeImageSize(level: sg.selectedSegmentIndex)
    }
}


// MARK: - Image
extension ResizeTabViewController {
    
    //MARK: - Image Share
    func shareImage() {
        
        guard let imageData = self.viewModel?.selectedImg.value, let qrImage = UIImage(data: imageData.imgData) else {
            print("공유할 이미지가 없습니다.")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [qrImage], applicationActivities: nil)
        
        // iPad에서의 팝오버 설정 (iPad에서는 이 설정이 없으면 앱이 충돌할 수 있음)
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view // 공유 버튼이 있는 뷰를 기준으로 팝오버 표시
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    //MARK: - Image Save
    func saveImage() {
        // TODO: - 권한을 체크하기전에 앱에 저장할지 디바이스 이미지로 저장할지를 선택하는 액션시트 구현
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Save Image to Gallery", comment:"갤러리에 이미지를 저장합니다."), preferredStyle: .alert)
        
        let option1 = UIAlertAction(title: NSLocalizedString("Save", comment:"저장"), style: .default) { action in
            self.viewModel?.checkPhotoLibraryOnlyAddPermission()
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment:"Cancel"), style: .cancel) { action in
            
        }
        
        alert.addAction(option1)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
}
