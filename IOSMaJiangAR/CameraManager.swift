import AVFoundation
import UIKit

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
}

final class CameraManager: NSObject {
    let session = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    weak var delegate: CameraManagerDelegate?

    private let captureQueue = DispatchQueue(label: "camera.capture.queue", qos: .userInteractive)
    private let output = AVCaptureVideoDataOutput()
    private var lastFrameTimestamp = CMTime.zero
    private var frameInterval: CMTime = CMTime(value: 1, timescale: 20)

    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        super.init()
    }

    func configureSession(preferredHD: Bool = true) throws {
        session.beginConfiguration()
        session.sessionPreset = preferredHD ? .hd1280x720 : .vga640x480

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            throw CameraError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        try camera.lockForConfiguration()
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
        }
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
        }
        camera.unlockForConfiguration()

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: captureQueue)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)
        output.connection(with: .video)?.videoOrientation = .portrait
        session.commitConfiguration()
    }

    func setProcessingFPS(_ fps: Int) {
        let clipped = min(25, max(15, fps))
        frameInterval = CMTime(value: 1, timescale: CMTimeScale(clipped))
    }

    func start() {
        guard !session.isRunning else { return }
        captureQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        captureQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func setTorch(enabled: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = enabled ? .on : .off
            device.unlockForConfiguration()
        } catch {
            return
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if lastFrameTimestamp == .zero {
            lastFrameTimestamp = presentationTime
        }
        let delta = CMTimeSubtract(presentationTime, lastFrameTimestamp)
        if delta >= frameInterval {
            lastFrameTimestamp = presentationTime
            delegate?.cameraManager(self, didOutput: sampleBuffer)
        }
    }
}

extension CameraManager {
    enum CameraError: Error {
        case noCamera
        case cannotAddInput
        case cannotAddOutput
    }
}
