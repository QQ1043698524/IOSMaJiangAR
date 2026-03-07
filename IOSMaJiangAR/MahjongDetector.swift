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
        let config = MLModelConfiguration()
        let wrapper = try MahjongYOLOv8n(configuration: config)
        self.model = try VNCoreMLModel(for: wrapper.model)
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
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
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
