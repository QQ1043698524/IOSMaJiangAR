import AVFoundation
import UIKit

final class CameraViewController: UIViewController {
    private let cameraManager = CameraManager()
    private let preprocessor = ImagePreprocessor()
    private let calculator = MahjongCalculator()
    private let detector: MahjongDetector?

    private let overlayView = BoundingBoxRenderer()
    private let scanAreaView = UIView()
    private let topBar = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let topBarLabel = UILabel()
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
        do {
            detector = try MahjongDetector()
        } catch {
            print("Error loading detector: \(error)")
            detector = nil
        }
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
        
        // 扫描区域：屏幕底部 20% ~ 50% 区域，高度约 30%
        let scanH = view.bounds.height * 0.3
        let scanY = view.bounds.height * 0.5
        scanAreaView.frame = CGRect(x: 16, y: scanY, width: view.bounds.width - 32, height: scanH)
        scanAreaView.layer.borderColor = UIColor.green.withAlphaComponent(0.6).cgColor
        scanAreaView.layer.borderWidth = 2
        scanAreaView.layer.cornerRadius = 8
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
        
        // 扫描区提示
        scanAreaView.backgroundColor = UIColor.clear
        scanAreaView.isUserInteractionEnabled = false
        view.addSubview(scanAreaView)
        
        // 添加渐变边框层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width - 32, height: view.bounds.height * 0.3))
        gradientLayer.colors = [UIColor.green.cgColor, UIColor.cyan.cgColor, UIColor.green.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        // 使用 ShapeLayer 作为 Mask 实现仅显示边框
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 3
        shapeLayer.path = UIBezierPath(roundedRect: gradientLayer.bounds, cornerRadius: 8).cgPath
        shapeLayer.fillColor = nil
        shapeLayer.strokeColor = UIColor.black.cgColor
        gradientLayer.mask = shapeLayer
        
        scanAreaView.layer.addSublayer(gradientLayer)
        
        // 渐变动画
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = [UIColor.green.cgColor, UIColor.cyan.cgColor, UIColor.green.cgColor]
        animation.toValue = [UIColor.cyan.cgColor, UIColor.green.cgColor, UIColor.cyan.cgColor]
        animation.duration = 3.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")

        let scanLabel = UILabel()
        scanLabel.text = "请将手牌置于此区域内"
        scanLabel.textColor = .green
        scanLabel.font = .systemFont(ofSize: 14)
        scanLabel.textAlignment = .center
        scanAreaView.addSubview(scanLabel)
        scanLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanLabel.centerXAnchor.constraint(equalTo: scanAreaView.centerXAnchor),
            scanLabel.topAnchor.constraint(equalTo: scanAreaView.topAnchor, constant: 8)
        ])
        
        // 呼吸动画 (透明度)
        UIView.animate(withDuration: 1.5, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            scanAreaView.alpha = 0.6
        }, completion: nil)

        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap(_:)))
        overlayView.addGestureRecognizer(tap)
        view.addSubview(overlayView)

        topBarLabel.text = "麻将实时识别"
        topBarLabel.textColor = .white
        topBarLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        topBarLabel.textAlignment = .center
        
        topBar.layer.cornerRadius = 12
        topBar.clipsToBounds = true
        topBar.contentView.addSubview(topBarLabel)
        topBarLabel.frame = topBar.bounds
        topBarLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]

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

        // 横屏布局：手牌在底部，按钮在右侧，结果在左上，TopBar在顶中
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topBar.widthAnchor.constraint(equalToConstant: 200),
            topBar.heightAnchor.constraint(equalToConstant: 36),

            resultLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            resultLabel.widthAnchor.constraint(equalToConstant: 240),
            resultLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 66),

            actionStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            actionStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            actionStack.widthAnchor.constraint(equalToConstant: 80),

            handView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            handView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
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
            topBarLabel.text = "相机启动失败"
        }
    }

    private func showPermissionDenied() {
        topBarLabel.text = "请在系统设置开启相机权限"
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
        guard isRecognitionEnabled else { return }
        
        guard let detector = detector else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.topBarLabel.text = "模型加载失败，请替换文件"
                self.topBar.contentView.backgroundColor = UIColor.red.withAlphaComponent(0.6)
                
                // 震动反馈
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.error)
            }
            return
        }
        
        guard let pixelBuffer = preprocessor.normalizedPixelBuffer(from: sampleBuffer) else { return }
        detector.detect(pixelBuffer: pixelBuffer) { [weak self] detections in
            DispatchQueue.main.async {
                guard let self else { return }
                
                // 过滤逻辑：
                // 1. 必须在扫描区域内（以中心点判断）
                // 2. 面积必须足够大（过滤远处背景牌），例如占扫描区高度的 1/5 以上
                
                let scanFrame = self.scanAreaView.frame
                let validDetections = detections.filter { detection in
                    let rect = self.normalizedToViewRect(detection.boundingBox)
                    let center = CGPoint(x: rect.midX, y: rect.midY)
                    
                    // 检查是否在扫描区域内
                    let inArea = scanFrame.contains(center)
                    
                    // 检查大小（简单阈值：高度 > 扫描区高度的 15%）
                    let sizeCheck = rect.height > (scanFrame.height * 0.15)
                    
                    return inArea && sizeCheck
                }
                
                self.latestDetections = validDetections
                self.overlayView.render(detections: validDetections)
            }
        }
    }
}
