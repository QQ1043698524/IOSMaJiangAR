import AVFoundation
import CoreML
import Vision

struct MahjongDetection {
    let tile: MahjongTile
    let confidence: Float
    let boundingBox: CGRect
}

final class MahjongDetector {
    private let model: VNCoreMLModel
    private let processingQueue = DispatchQueue(label: "detector.queue", qos: .userInitiated)
    private var isBusy = false

    init() throws {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: "MahjongYOLOv8n", withExtension: "mlmodelc") else {
            throw DetectorError.modelNotFound
        }
        let mlModel = try MLModel(contentsOf: url)
        self.model = try VNCoreMLModel(for: mlModel)
    }

    func detect(
        pixelBuffer: CVPixelBuffer,
        completion: @escaping ([MahjongDetection]) -> Void
    ) {
        guard !isBusy else {
            completion([])
            return
        }
        isBusy = true
        processingQueue.async { [weak self] in
            guard let self else { return }
            let request = VNCoreMLRequest(model: self.model) { request, _ in
                defer { self.isBusy = false }
                let observations = request.results as? [VNRecognizedObjectObservation] ?? []
                let detections = observations.compactMap { observation -> MahjongDetection? in
                    guard let top = observation.labels.first,
                          let tile = MahjongTile.modelLookup[top.identifier] else { return nil }
                    return MahjongDetection(
                        tile: tile,
                        confidence: top.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                completion(detections)
            }
            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            do {
                try handler.perform([request])
            } catch {
                self.isBusy = false
                completion([])
            }
        }
    }
}

extension MahjongDetector {
    enum DetectorError: Error {
        case modelNotFound
    }
}
