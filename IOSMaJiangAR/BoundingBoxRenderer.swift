import UIKit

final class BoundingBoxRenderer: UIView {
    private var boxLayers: [CAShapeLayer] = []
    private var textLayers: [CATextLayer] = []

    func render(detections: [MahjongDetection]) {
        clear()
        for detection in detections {
            let rect = normalizedToViewRect(detection.boundingBox)
            let shape = CAShapeLayer()
            shape.path = UIBezierPath(rect: rect).cgPath
            shape.lineWidth = 2
            shape.fillColor = UIColor.clear.cgColor
            shape.strokeColor = (detection.confidence >= 0.7 ? UIColor.systemGreen : UIColor.systemRed).cgColor
            layer.addSublayer(shape)
            boxLayers.append(shape)

            let text = CATextLayer()
            let label = detection.tile?.displayName ?? detection.label
            text.string = "\(label) \(Int(detection.confidence * 100))%"
            text.fontSize = 13
            text.foregroundColor = UIColor.white.cgColor
            text.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
            text.contentsScale = UIScreen.main.scale
            text.frame = CGRect(x: rect.minX, y: max(0, rect.minY - 20), width: max(70, rect.width), height: 18)
            layer.addSublayer(text)
            textLayers.append(text)
        }
    }

    func clear() {
        boxLayers.forEach { $0.removeFromSuperlayer() }
        textLayers.forEach { $0.removeFromSuperlayer() }
        boxLayers.removeAll()
        textLayers.removeAll()
    }

    private func normalizedToViewRect(_ rect: CGRect) -> CGRect {
        let width = rect.width * bounds.width
        let height = rect.height * bounds.height
        let x = rect.minX * bounds.width
        let y = (1 - rect.maxY) * bounds.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
