import AVFoundation
import UIKit

final class CameraViewController: UIViewController {
    private let cameraManager = CameraManager()
    private let preprocessor = ImagePreprocessor()
    private let calculator = MahjongCalculator()
    private let detector: MahjongDetector?

    private let overlayView = BoundingBoxRenderer()
    private let topBar = UILabel()
    private let resultLabel = ResultLabel()
    private let handView = MahjongHandView()
    private let actionStack = UIStackView()

    private let clearButton = UIButton(type: .system)
    private let ruleButton = UIButton(type: .system)
    private let recognizeButton = UIButton(type: .system)
    private let torchButton = UIButton(type: .system)

    private var handTiles: [MahjongTile] = []
    private var latestDetections: [MahjongDetection] = []
    private var isRecognitionEnabled = true
    private var isTorchEnabled = false
    private var currentRule: MahjongRule = .guobiao

    init() {
        detector = try? MahjongDetector()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        cameraManager.delegate = self
        cameraManager.setProcessingFPS(20)
        setupUI()
        requestCameraPermissionAndStart()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.previewLayer.frame = view.bounds
        overlayView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraManager.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraManager.stop()
    }

    private func setupUI() {
        view.layer.addSublayer(cameraManager.previewLayer)

        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap(_:)))
        overlayView.addGestureRecognizer(tap)
        view.addSubview(overlayView)

        topBar.text = "麻将实时识别"
        topBar.textColor = .white
        topBar.font = .systemFont(ofSize: 17, weight: .semibold)
        topBar.textAlignment = .center
        topBar.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        topBar.layer.cornerRadius = 10
        topBar.clipsToBounds = true

        handView.onDeleteTile = { [weak self] index in
            guard let self, self.handTiles.indices.contains(index) else { return }
            self.handTiles.remove(at: index)
            self.refreshHandAndResult()
        }

        configureActionButtons()
        actionStack.axis = .vertical
        actionStack.spacing = 12
        actionStack.alignment = .fill
        [clearButton, ruleButton, recognizeButton, torchButton].forEach { actionStack.addArrangedSubview($0) }

        view.addSubview(topBar)
        view.addSubview(resultLabel)
        view.addSubview(handView)
        view.addSubview(actionStack)

        [topBar, resultLabel, handView, actionStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: actionStack.leadingAnchor, constant: -12),
            topBar.heightAnchor.constraint(equalToConstant: 40),

            resultLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: actionStack.leadingAnchor, constant: -12),
            resultLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 66),

            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            actionStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            actionStack.widthAnchor.constraint(equalToConstant: 96),

            handView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            handView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            handView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            handView.heightAnchor.constraint(equalToConstant: 72)
        ])
        refreshHandAndResult()
    }

    private func configureActionButtons() {
        configure(button: clearButton, title: "清空手牌", action: #selector(clearHand))
        configure(button: ruleButton, title: "规则:国标", action: #selector(switchRule))
        configure(button: recognizeButton, title: "识别:开", action: #selector(toggleRecognition))
        configure(button: torchButton, title: "闪光灯:关", action: #selector(toggleTorch))
    }

    private func configure(button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 9
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func requestCameraPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startCameraSession()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        default:
            showPermissionDenied()
        }
    }

    private func startCameraSession() {
        do {
            try cameraManager.configureSession(preferredHD: true)
            cameraManager.start()
        } catch {
            topBar.text = "相机启动失败"
        }
    }

    private func showPermissionDenied() {
        topBar.text = "请在系统设置开启相机权限"
    }

    @objc private func clearHand() {
        handTiles.removeAll()
        refreshHandAndResult()
    }

    @objc private func switchRule() {
        let currentIndex = MahjongRule.allCases.firstIndex(of: currentRule) ?? 0
        let nextIndex = (currentIndex + 1) % MahjongRule.allCases.count
        currentRule = MahjongRule.allCases[nextIndex]
        ruleButton.setTitle("规则:\(currentRule.rawValue)", for: .normal)
        refreshHandAndResult()
    }

    @objc private func toggleRecognition() {
        isRecognitionEnabled.toggle()
        recognizeButton.setTitle("识别:\(isRecognitionEnabled ? "开" : "关")", for: .normal)
        if !isRecognitionEnabled {
            latestDetections = []
            overlayView.clear()
        }
    }

    @objc private func toggleTorch() {
        isTorchEnabled.toggle()
        cameraManager.setTorch(enabled: isTorchEnabled)
        torchButton.setTitle("闪光灯:\(isTorchEnabled ? "开" : "关")", for: .normal)
    }

    @objc private func handleOverlayTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: overlayView)
        let matched = latestDetections.first { detection in
            let box = normalizedToViewRect(detection.boundingBox)
            return box.contains(point)
        }
        if let tile = matched?.tile {
            guard handTiles.count < 14 else { return }
            handTiles.append(tile)
            refreshHandAndResult()
        }
    }

    private func normalizedToViewRect(_ rect: CGRect) -> CGRect {
        let width = rect.width * overlayView.bounds.width
        let height = rect.height * overlayView.bounds.height
        let x = rect.minX * overlayView.bounds.width
        let y = (1 - rect.maxY) * overlayView.bounds.height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func refreshHandAndResult() {
        handView.update(tiles: handTiles)
        let result = calculator.analyze(hand: handTiles, rule: currentRule)
        if result.currentWinning {
            resultLabel.text = "已胡牌\n\(result.fanDescription)"
            return
        }
        if result.isTing {
            let names = result.huTiles.map(\.displayName).joined(separator: "/")
            resultLabel.text = "听牌：胡\(names)\n\(result.fanDescription)"
        } else {
            resultLabel.text = "未听牌"
        }
    }
}

extension CameraViewController: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        guard isRecognitionEnabled, let detector else { return }
        guard let pixelBuffer = preprocessor.normalizedPixelBuffer(from: sampleBuffer) else { return }
        detector.detect(pixelBuffer: pixelBuffer) { [weak self] detections in
            DispatchQueue.main.async {
                guard let self else { return }
                self.latestDetections = detections
                self.overlayView.render(detections: detections)
            }
        }
    }
}
