//
// MahjongYOLOv8n.swift
// IOSMaJiangAR
//
// Manually created wrapper for CoreML model loading
//

import CoreML

/// Model wrapper class for MahjongYOLOv8n
final class MahjongYOLOv8n {
    let model: MLModel

    /// URL of the underlying .mlmodelc directory.
    class var urlOfModelInThisBundle: URL {
        let bundle = Bundle.main
        let url = bundle.url(forResource: "MahjongYOLOv8n", withExtension: "mlmodelc")!
        return url
    }

    /// Construct MahjongYOLOv8n instance with an existing MLModel object.
    /// Usually the application does not use this initializer unless it makes a subclass of MahjongYOLOv8n.
    init(model: MLModel) {
        self.model = model
    }

    /// Construct MahjongYOLOv8n instance by automatically loading the model from the app's bundle.
    convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: "MahjongYOLOv8n", withExtension: "mlmodelc") else {
            throw NSError(domain: "MahjongYOLOv8n", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file not found in bundle"])
        }
        let model = try MLModel(contentsOf: url, configuration: configuration)
        self.init(model: model)
    }
}
