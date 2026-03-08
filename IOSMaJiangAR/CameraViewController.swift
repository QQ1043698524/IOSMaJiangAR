import AVFoundation
import UIKit
import CoreML
import Vision

final class CameraViewController: UIViewController {
    private let cameraManager = CameraManager()
    private let preprocessor = ImagePreprocessor()
    private let calculator = MahjongCalculator()
    private var detector: MahjongDetector?

    private let overlayView = BoundingBoxRenderer()
    private let scanAreaView = UIView()
    private let topBar = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let topBarLabel = UILabel()
    private let resultLabel = ResultLabel()
    private let handView = MahjongHandView()
    private let actionStack = UIStackView()
    private let debugLogView = UITextView()

    private let clearButton = UIButton(type: .system)
    private let ruleButton = UIButton(type: .system)
    private let recognizeButton = UIButton(type: .system)
    private let torchButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let autoAddSwitch = UISwitch()
    private let autoAddLabel = UILabel()

    private var handTiles: [MahjongTile] = []
    private var latestDetections: [MahjongDetection] = []
    private var isRecognitionEnabled = true
    private var isTorchEnabled = false
    private var isAutoAddEnabled = false
    private var lastAutoAddTimestamp: TimeInterval = 0
    private var currentRule: MahjongRule = .guobiao

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        detector = MahjongDetector()
        if detector == nil {
            print("Failed to init detector")
        }
        
        cameraManager.delegate = self
        cameraManager.setProcessingFPS(20)
        setupUI()
        requestCameraPermissionAndStart()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.previewLayer.frame = view.bounds
        cameraManager.updateVideoOrientation(.landscapeRight)
        overlayView.frame = view.bounds
        
        // 扫描区域：屏幕底部更紧凑的区域
        let scanH = view.bounds.height * 0.25
        let scanY = (view.bounds.height - scanH) / 2 + 20
        scanAreaView.frame = CGRect(x: 40, y: scanY, width: view.bounds.width - 80, height: scanH)
        scanAreaView.layer.borderColor = UIColor.green.withAlphaComponent(0.6).cgColor
        scanAreaView.layer.borderWidth = 2
        scanAreaView.layer.cornerRadius = 8
        
        // 更新渐变层 Frame
        if let gradientLayer = scanAreaView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
            gradientLayer.frame = scanAreaView.bounds
            gradientLayer.mask?.frame = scanAreaView.bounds
            (gradientLayer.mask as? CAShapeLayer)?.path = UIBezierPath(roundedRect: scanAreaView.bounds, cornerRadius: 8).cgPath
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraManager.updateVideoOrientation(.landscapeRight)
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
            self.scanAreaView.alpha = 0.6
        }, completion: nil)

        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap(_:)))
        overlayView.addGestureRecognizer(tap)
        view.addSubview(overlayView)

        // Debug Log View
        debugLogView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        debugLogView.textColor = .green
        debugLogView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        debugLogView.isEditable = false
        debugLogView.isUserInteractionEnabled = false
        debugLogView.text = "初始化完成...\n等待识别..."
        view.addSubview(debugLogView)

        topBarLabel.text = "麻将实时识别"
        topBarLabel.textColor = .white
        topBarLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        topBarLabel.textAlignment = .center
        
        topBar.layer.cornerRadius = 12
        topBar.clipsToBounds = true
        topBar.contentView.addSubview(topBarLabel)
        topBarLabel.frame = topBar.bounds
        topBarLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        handView.onDeleteTile = { [weak self] index in
            guard let self = self, self.handTiles.indices.contains(index) else { return }
            self.handTiles.remove(at: index)
            self.refreshHandAndResult()
        }

        configureActionButtons()

        // Simplified action stack
        actionStack.axis = .vertical
        actionStack.spacing = 8
        actionStack.alignment = .fill
        
        [ruleButton, recognizeButton, torchButton].forEach { actionStack.addArrangedSubview($0) }
        
        view.addSubview(topBar)
        view.addSubview(resultLabel)
        view.addSubview(handView)
        view.addSubview(actionStack)

        [topBar, resultLabel, handView, actionStack, debugLogView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // 横屏布局：手牌在底部，按钮在右侧，结果在左上，TopBar在顶中
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            topBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topBar.widthAnchor.constraint(equalToConstant: 120),
            topBar.heightAnchor.constraint(equalToConstant: 28),

            resultLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            resultLabel.widthAnchor.constraint(equalToConstant: 160),
            resultLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            debugLogView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 8),
            debugLogView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            debugLogView.widthAnchor.constraint(equalToConstant: 160),
            debugLogView.bottomAnchor.constraint(equalTo: handView.topAnchor, constant: -8),

            actionStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            actionStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            actionStack.widthAnchor.constraint(equalToConstant: 60),

            handView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            handView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            handView.heightAnchor.constraint(equalToConstant: 50)
        ])
        refreshHandAndResult()
    }

    private func configureActionButtons() {
        configure(button: clearButton, title: "清空手牌", action: #selector(clearHand))
        configure(button: ruleButton, title: "规则:国标", action: #selector(switchRule))
        configure(button: recognizeButton, title: "识别:开", action: #selector(toggleRecognition))
        configure(button: torchButton, title: "闪光灯:关", action: #selector(toggleTorch))
        configure(button: addButton, title: "添加识别", action: #selector(addDetectedTiles))
    }
    
    // 移除之前的 viewDidLoad 中错误的插入，保持代码整洁
    // ... (no changes needed, just cleaning up context)

    @objc private func addDetectedTiles() {
        // 将当前检测到的所有麻将牌添加到手牌
        let newTiles = latestDetections.compactMap { $0.tile }
        
        guard !newTiles.isEmpty else {
            // 提示无识别结果
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
            return 
        }

        // 避免重复添加完全相同的一组牌（简单防抖）
        // 这里只是简单追加，用户可以手动删除多余的
        for tile in newTiles {
            if handTiles.count < 14 {
                handTiles.append(tile)
            }
        }
        refreshHandAndResult()
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }

    private var detectionHistory: [[MahjongTile]] = []
    private let historyCapacity = 5 // 稳定窗口大小

    @objc private func toggleAutoAdd() {
        // 废弃旧的自动添加逻辑，现在总是实时识别
    }
    
    // ... (remove appendDebugLog)

    // ... (keep configureActionButtons but remove autoAddSwitch/autoAddLabel/addButton related code)
    
    // Replace detection handling
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        guard isRecognitionEnabled else { return }
        
        guard let detector = detector else { return }
        guard let pixelBuffer = preprocessor.normalizedPixelBuffer(from: sampleBuffer) else { return }
        
        detector.detect(pixelBuffer: pixelBuffer) { [weak self] detections in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.latestDetections = detections
                self.overlayView.render(detections: detections)
                
                // 1. 提取当前帧所有识别到的麻将牌（已按X坐标排序）
                let currentFrameTiles = detections.compactMap { $0.tile }
                
                // 2. 如果识别数量太少（比如少于4张），可能是不完整的帧，忽略
                if currentFrameTiles.count < 4 { return }
                
                // 3. 加入历史记录
                self.detectionHistory.append(currentFrameTiles)
                if self.detectionHistory.count > self.historyCapacity {
                    self.detectionHistory.removeFirst()
                }
                
                // 4. 寻找最稳定的结果（众数算法简化版）
                // 如果连续 N 帧识别出的手牌序列完全一致，或者大部分一致，则更新手牌
                if self.detectionHistory.count == self.historyCapacity {
                    if let stableHand = self.findStableHand(in: self.detectionHistory) {
                        self.handTiles = stableHand
                        self.refreshHandAndResult()
                    }
                }
            }
        }
    }
    
    private func findStableHand(in history: [[MahjongTile]]) -> [MahjongTile]? {
        // 简单策略：如果最近 5 帧里有 3 帧的结果完全一样，就认为是稳定的
        // 将数组转换为字符串作为 Key 进行统计
        var counts: [String: Int] = [:]
        var mapping: [String: [MahjongTile]] = [:]
        
        for hand in history {
            let key = hand.map { $0.modelLabel }.joined(separator: ",")
            counts[key, default: 0] += 1
            mapping[key] = hand
        }
        
        // 找到出现次数最多的
        if let maxEntry = counts.max(by: { $0.value < $1.value }) {
            // 阈值：5帧里至少3帧一致
            if maxEntry.value >= 3 {
                return mapping[maxEntry.key]
            }
        }
        return nil
    }

    private func configure(button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.layer.cornerRadius = 7
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
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
        if let detection = matched, let tile = detection.tile {
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
            let names = result.huTiles.map { $0.displayName }.joined(separator: "/")
            resultLabel.text = "听牌：胡\(names)\n\(result.fanDescription)"
        } else {
            resultLabel.text = "未听牌"
        }
    }
}

extension CameraViewController: CameraManagerDelegate {
    // cameraManager method was implemented directly in class body above, removing this extension block or merging it
    // To keep it clean, let's remove the redundant extension block at the bottom
}
