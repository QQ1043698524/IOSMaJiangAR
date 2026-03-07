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

    init?() {
        let bundle = Bundle.main
        var candidateURLs: [URL] = []
        if let url = bundle.url(forResource: "MahjongYOLOv8n", withExtension: "mlmodelc") {
            candidateURLs.append(url)
        }
        let compiledURLs = bundle.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil) ?? []
        candidateURLs.append(contentsOf: compiledURLs.filter { $0.lastPathComponent.contains("MahjongYOLOv8n") })
        candidateURLs.append(contentsOf: compiledURLs)
        if let url = bundle.url(forResource: "MahjongYOLOv8n", withExtension: "mlpackage") {
            candidateURLs.append(url)
        }

        var loadedModel: VNCoreMLModel?
        for url in candidateURLs {
            if let mlModel = try? MLModel(contentsOf: url),
               let vnModel = try? VNCoreMLModel(for: mlModel) {
                loadedModel = vnModel
                break
            }
        }

        guard let model = loadedModel else {
            let resourceNames = bundle.urls(forResourcesWithExtension: nil, subdirectory: nil)?
                .map { $0.lastPathComponent }
                .filter { $0.contains("MahjongYOLOv8n") } ?? []
            print("Error: Could not load MahjongYOLOv8n model. Found resources: \(resourceNames)")
            return nil
        }
        self.model = model
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
            guard let self = self else { return }
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
