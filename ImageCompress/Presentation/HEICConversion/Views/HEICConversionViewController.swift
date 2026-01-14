//
//  HEICConversionViewController.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import UIKit

/// HEIC 변환 화면 ViewController
final class HEICConversionViewController: UIViewController {

    // MARK: - Properties
    var viewModel: HEICConversionViewModel!
    var adService: AdService?

    private var effectiveAdService: AdService {
        adService ?? AdmobService.shared
    }

    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        return sv
    }()

    private lazy var contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var adView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("heic_conversion_title", comment: "HEIC → JPEG 변환")
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("heic_conversion_desc", comment: "여러 HEIC 이미지를 JPEG로 일괄 변환합니다.")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("select_images", comment: "이미지 선택"), for: .normal)
        button.setImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        button.backgroundColor = .speedMain0
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(selectImagesTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private lazy var selectedCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(ImageThumbnailCell.self, forCellWithReuseIdentifier: "ImageThumbnailCell")
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.heightAnchor.constraint(equalToConstant: 90).isActive = true
        return cv
    }()

    private lazy var settingsView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var formatSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["JPEG", "PNG"])
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(formatChanged), for: .valueChanged)
        return segment
    }()

    private lazy var qualitySegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: [
            NSLocalizedString("high", comment: "고품질"),
            NSLocalizedString("normal", comment: "보통"),
            NSLocalizedString("low", comment: "저품질")
        ])
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(qualityChanged), for: .valueChanged)
        return segment
    }()

    private lazy var progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = .speedMain0
        pv.isHidden = true
        return pv
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .speedMain0
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var convertButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("convert", comment: "변환하기"), for: .normal)
        button.backgroundColor = .speedMain0
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("save_all", comment: "모두 저장"), for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [convertButton, saveButton])
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        return sv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupAdView()
        bind()
        viewModel.viewDidLoad()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Settings View 내부 구성
        let formatLabel = UILabel()
        formatLabel.text = NSLocalizedString("output_format", comment: "출력 포맷")
        formatLabel.font = .systemFont(ofSize: 14, weight: .medium)

        let qualityLabel = UILabel()
        qualityLabel.text = NSLocalizedString("image_quality", comment: "이미지 품질")
        qualityLabel.font = .systemFont(ofSize: 14, weight: .medium)

        let settingsStack = UIStackView(arrangedSubviews: [
            formatLabel, formatSegment,
            qualityLabel, qualitySegment
        ])
        settingsStack.axis = .vertical
        settingsStack.spacing = 8
        settingsStack.translatesAutoresizingMaskIntoConstraints = false

        settingsView.addSubview(settingsStack)
        NSLayoutConstraint.activate([
            settingsStack.topAnchor.constraint(equalTo: settingsView.topAnchor, constant: 16),
            settingsStack.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 16),
            settingsStack.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -16),
            settingsStack.bottomAnchor.constraint(equalTo: settingsView.bottomAnchor, constant: -16)
        ])

        // Content Stack에 추가
        contentStackView.addArrangedSubview(adView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(selectButton)
        contentStackView.addArrangedSubview(selectedCountLabel)
        contentStackView.addArrangedSubview(collectionView)
        contentStackView.addArrangedSubview(settingsView)
        contentStackView.addArrangedSubview(progressView)
        contentStackView.addArrangedSubview(progressLabel)
        contentStackView.addArrangedSubview(resultLabel)
        contentStackView.addArrangedSubview(buttonStackView)

        // 초기 상태
        collectionView.isHidden = true
        settingsView.isHidden = true
        updateButtonState()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            adView.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func setupAdView() {
        effectiveAdService.configureBanner(in: adView, from: self, type: .mainBanner)
    }

    private func bind() {
        viewModel.selectedImages.observe(on: self) { [weak self] images in
            self?.updateSelectedImages(images)
        }

        viewModel.conversionResults.observe(on: self) { [weak self] results in
            self?.updateConversionResults(results)
        }

        viewModel.conversionProgress.observe(on: self) { [weak self] progress in
            self?.updateProgress(progress)
        }

        viewModel.isConverting.observe(on: self) { [weak self] isConverting in
            self?.updateConvertingState(isConverting)
        }

        viewModel.error.observe(on: self) { [weak self] errorMessage in
            if let message = errorMessage {
                self?.showError(message)
            }
        }

        viewModel.savedCount.observe(on: self) { [weak self] count in
            if let count = count {
                self?.showSaveSuccess(count: count)
            }
        }
    }

    // MARK: - Actions
    @objc private func selectImagesTapped() {
        viewModel.selectImages(self)
    }

    @objc private func formatChanged() {
        let format: ImageFormat = formatSegment.selectedSegmentIndex == 0 ? .jpeg : .png
        viewModel.setOutputFormat(format)
    }

    @objc private func qualityChanged() {
        let qualities: [ImageQuality] = [.high, .normal, .low]
        viewModel.setQuality(qualities[qualitySegment.selectedSegmentIndex])
    }

    @objc private func convertTapped() {
        viewModel.convertAll()
    }

    @objc private func saveTapped() {
        viewModel.saveAll()
    }

    // MARK: - UI Updates
    private func updateSelectedImages(_ images: [SelectedImage]) {
        let hasImages = !images.isEmpty
        collectionView.isHidden = !hasImages
        settingsView.isHidden = !hasImages
        selectedCountLabel.isHidden = !hasImages

        if hasImages {
            let heicCount = images.filter { $0.isHEIC }.count
            let totalSize = formatByteCount(images.reduce(0) { $0 + $1.originalSize })
            selectedCountLabel.text = "\(images.count)개 선택됨 (HEIC: \(heicCount)개) - 총 \(totalSize)"
        }

        collectionView.reloadData()
        updateButtonState()
    }

    private func updateConversionResults(_ results: [ConversionResult]) {
        let hasResults = !results.isEmpty
        saveButton.isHidden = !hasResults
        resultLabel.isHidden = !hasResults

        if hasResults {
            let originalSize = viewModel.totalOriginalSize
            let convertedSize = viewModel.totalConvertedSize
            let savedSize = originalSize - convertedSize
            let savedPercentage = Double(savedSize) / Double(originalSize) * 100

            resultLabel.text = """
            변환 완료! \(results.count)개 이미지
            \(formatByteCount(originalSize)) → \(formatByteCount(convertedSize))
            \(String(format: "%.1f", savedPercentage))% 절약
            """
        }
    }

    private func updateProgress(_ progress: ConversionProgress?) {
        let hasProgress = progress != nil
        progressView.isHidden = !hasProgress
        progressLabel.isHidden = !hasProgress

        if let progress = progress {
            progressView.progress = Float(progress.current) / Float(progress.total)
            progressLabel.text = "\(progress.current)/\(progress.total) - \(progress.currentFileName)"
        }
    }

    private func updateConvertingState(_ isConverting: Bool) {
        convertButton.isEnabled = !isConverting
        selectButton.isEnabled = !isConverting
        convertButton.alpha = isConverting ? 0.5 : 1.0
    }

    private func updateButtonState() {
        let hasImages = !viewModel.selectedImages.value.isEmpty
        convertButton.isEnabled = hasImages
        convertButton.alpha = hasImages ? 1.0 : 0.5
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("error", comment: "오류"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "확인"), style: .default))
        present(alert, animated: true)
    }

    private func showSaveSuccess(count: Int) {
        let alert = UIAlertController(
            title: NSLocalizedString("save_complete", comment: "저장 완료"),
            message: String(format: NSLocalizedString("images_saved_format", comment: "%d개 이미지가 저장되었습니다."), count),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "확인"), style: .default))
        present(alert, animated: true)
    }

    private func formatByteCount(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - UICollectionViewDataSource
extension HEICConversionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.selectedImages.value.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageThumbnailCell", for: indexPath) as! ImageThumbnailCell
        let image = viewModel.selectedImages.value[indexPath.row]
        cell.configure(with: image)
        cell.onDelete = { [weak self] in
            self?.viewModel.removeImage(at: indexPath.row)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HEICConversionViewController: UICollectionViewDelegate {
    // 필요시 추가 구현
}

// MARK: - ImageThumbnailCell
final class ImageThumbnailCell: UICollectionViewCell {

    var onDelete: (() -> Void)?

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var heicBadge: UILabel = {
        let label = UILabel()
        label.text = "HEIC"
        label.font = .systemFont(ofSize: 8, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemOrange
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
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
        contentView.addSubview(heicBadge)
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heicBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            heicBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            heicBadge.widthAnchor.constraint(equalToConstant: 30),
            heicBadge.heightAnchor.constraint(equalToConstant: 14),

            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with image: SelectedImage) {
        imageView.image = UIImage(data: image.data)
        heicBadge.isHidden = !image.isHEIC
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}
