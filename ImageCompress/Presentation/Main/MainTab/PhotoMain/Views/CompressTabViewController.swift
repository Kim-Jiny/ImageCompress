//
//  CompressTabViewController.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//  Refactored for Clean Architecture
//

import UIKit
import GoogleMobileAds

class CompressTabViewController: UIViewController, StoryboardInstantiable {
    var viewModel: MainViewModel?
    var adService: AdService?

    /// 효과적인 AdService (주입되지 않으면 기본값 사용)
    private var effectiveAdService: AdService {
        adService ?? AdmobService.shared
    }

    // 다중 이미지 UI 요소
    private lazy var thumbnailCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var imageCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private lazy var prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(prevImageTapped), for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(nextImageTapped), for: .touchUpInside)
        return button
    }()

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
        setupMultiImageUI()
        if let viewModel = viewModel {
            bind(to: viewModel)
        }
        setupAdView()
    }

    private func setupMultiImageUI() {
        thumbnailCollectionView.delegate = self
        thumbnailCollectionView.dataSource = self

        // 썸네일 컬렉션뷰를 이미지뷰 아래에 추가
        if let imageView = selectedImgView {
            imageView.superview?.addSubview(thumbnailCollectionView)
            imageView.superview?.addSubview(imageCountLabel)
            imageView.superview?.addSubview(prevButton)
            imageView.superview?.addSubview(nextButton)

            NSLayoutConstraint.activate([
                // 썸네일 컬렉션뷰
                thumbnailCollectionView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                thumbnailCollectionView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                thumbnailCollectionView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
                thumbnailCollectionView.heightAnchor.constraint(equalToConstant: 70),

                // 이미지 카운트 라벨
                imageCountLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
                imageCountLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
                imageCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
                imageCountLabel.heightAnchor.constraint(equalToConstant: 24),

                // 이전 버튼
                prevButton.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
                prevButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                prevButton.widthAnchor.constraint(equalToConstant: 44),
                prevButton.heightAnchor.constraint(equalToConstant: 44),

                // 다음 버튼
                nextButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
                nextButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                nextButton.widthAnchor.constraint(equalToConstant: 44),
                nextButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }

    @objc private func prevImageTapped() {
        guard let currentIndex = viewModel?.currentImageIndex.value, currentIndex > 0 else { return }
        viewModel?.selectCurrentImageAt(index: currentIndex - 1)
    }

    @objc private func nextImageTapped() {
        guard let currentIndex = viewModel?.currentImageIndex.value,
              let total = viewModel?.totalImageCount.value,
              currentIndex < total - 1 else { return }
        viewModel?.selectCurrentImageAt(index: currentIndex + 1)
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
        effectiveAdService.configureBanner(in: adView, from: self, type: .mainBanner)
        effectiveAdService.loadRewardedAd(type: .rewardedInterstitial)
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
                self?.viewModel?.isDownloadSuccess = isSuccess
                print(isSuccess)
                DispatchQueue.main.async {
                    self?.showSaveAlert()
                }
            })

            // 다음 리워드 광고 준비
            self?.effectiveAdService.loadRewardedAd(type: .rewardedInterstitial)
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

        // 다중 이미지 바인딩
        viewModel.selectedImages.observe(on: self) { [weak self] images in
            self?.updateMultiImageUI(images: images)
        }

        viewModel.currentImageIndex.observe(on: self) { [weak self] index in
            self?.updateCurrentImageIndex(index)
        }

        viewModel.totalImageCount.observe(on: self) { [weak self] count in
            self?.updateImageCount(count)
        }
    }

    private func updateMultiImageUI(images: [CompressedImage]) {
        DispatchQueue.main.async { [weak self] in
            let hasMultipleImages = images.count > 1
            self?.thumbnailCollectionView.isHidden = !hasMultipleImages
            self?.prevButton.isHidden = !hasMultipleImages
            self?.nextButton.isHidden = !hasMultipleImages
            self?.imageCountLabel.isHidden = images.isEmpty

            self?.thumbnailCollectionView.reloadData()
        }
    }

    private func updateCurrentImageIndex(_ index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let total = self.viewModel?.totalImageCount.value else { return }
            self.imageCountLabel.text = " \(index + 1) / \(total) "

            // 버튼 활성화 상태 업데이트
            self.prevButton.isEnabled = index > 0
            self.prevButton.alpha = index > 0 ? 1.0 : 0.5
            self.nextButton.isEnabled = index < total - 1
            self.nextButton.alpha = index < total - 1 ? 1.0 : 0.5

            // 현재 선택된 셀 하이라이트
            self.thumbnailCollectionView.reloadData()

            // 선택된 셀로 스크롤
            if total > 0 {
                let indexPath = IndexPath(item: index, section: 0)
                self.thumbnailCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }

    private func updateImageCount(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let index = self.viewModel?.currentImageIndex.value else { return }
            self.imageCountLabel.text = " \(index + 1) / \(count) "
            self.imageCountLabel.isHidden = count == 0
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
        effectiveAdService.showRewardedAd(delegate: self) { [weak self] in
            self?.viewModel?.checkPhotoLibraryOnlyAddPermission()
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

// MARK: - AdFullScreenDelegate (Clean Architecture)
extension CompressTabViewController: AdFullScreenDelegate {

    func adDidFailToPresent() {
        print("Ad did fail to present full screen content.")
        // 광고가 준비되지 않은 상태에서도 동작해야함.
        self.viewModel?.checkPhotoLibraryOnlyAddPermission()
    }

    func adWillPresent() {
        print("Ad will present full screen content.")
        // 광고가 표시될 때
    }

    func adDidDismiss() {
        print("Ad did dismiss full screen content.")
        // 광고를 닫은경우 - 광고 리워드가 지급되었으면 이미지 다운로드완료 팝업을 띄워야함.
        if (self.viewModel?.isDownloadSuccess ?? false) {
            DispatchQueue.main.async {
                self.showSaveAlert()
            }
        }
    }
}

// MARK: - GADFullScreenContentDelegate (Legacy Support)
extension CompressTabViewController: GADFullScreenContentDelegate {

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        adDidFailToPresent()
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        adWillPresent()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        adDidDismiss()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension CompressTabViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.selectedImages.value.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.reuseIdentifier, for: indexPath) as? ThumbnailCell else {
            return UICollectionViewCell()
        }

        if let images = viewModel?.selectedImages.value, indexPath.item < images.count {
            let image = images[indexPath.item]
            let isSelected = indexPath.item == viewModel?.currentImageIndex.value
            cell.configure(with: image.compressedData, isSelected: isSelected)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel?.selectCurrentImageAt(index: indexPath.item)
    }
}

// MARK: - ThumbnailCell
class ThumbnailCell: UICollectionViewCell {
    static let reuseIdentifier = "ThumbnailCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectionOverlay)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectionOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with imageData: Data, isSelected: Bool) {
        imageView.image = UIImage(data: imageData)
        selectionOverlay.isHidden = !isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        selectionOverlay.isHidden = true
    }
}
