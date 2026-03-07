import CoreImage
import CoreVideo
import AVFoundation
import UIKit

final class ImagePreprocessor {
    private let context = CIContext(options: [.cacheIntermediates: false])

    func normalizedPixelBuffer(from sampleBuffer: CMSampleBuffer) -> CVPixelBuffer? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        return pixelBuffer
    }

    func resized(pixelBuffer: CVPixelBuffer, target: CGSize) -> CVPixelBuffer? {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = target.width / image.extent.width
        let sy = target.height / image.extent.height
        let transformed = image.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        var outBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(target.width),
            Int(target.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &outBuffer
        )
        guard let outBuffer else { return nil }
        context.render(transformed, to: outBuffer)
        return outBuffer
    }
}
