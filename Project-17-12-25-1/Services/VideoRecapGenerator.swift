import Foundation
import AVFoundation
import UIKit

struct VideoRecapGenerator {
    static func generate(items: [WishlistItemEntity], completion: @escaping (URL?) -> Void) {
        let size = CGSize(width: 720, height: 1280)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recap-\(UUID().uuidString).mp4")
        let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard let writer, writer.canAdd(input) else { completion(nil); return }
        writer.add(input)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let queue = DispatchQueue(label: "video.recap.queue")
        var frameCount: Int64 = 0
        let fps: Int32 = 30
        input.requestMediaDataWhenReady(on: queue) {
            for item in items.prefix(30) {
                while !input.isReadyForMoreMediaData { }
                guard let buffer = VideoRecapGenerator.makePixelBuffer(text: "\(item.name) ↓ \(item.currentPrice.currency)", size: size) else { continue }
                let time = CMTime(value: frameCount, timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
                frameCount += Int64(fps)
            }
            input.markAsFinished()
            writer.finishWriting {
                completion(writer.status == .completed ? url : nil)
            }
        }
    }

    private static func makePixelBuffer(text: String, size: CGSize) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: true,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs, &buffer)
        guard let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let attrsText: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 48),
            .foregroundColor: UIColor.white
        ]
        let textSize = text.size(withAttributes: attrsText)
        let rect = CGRect(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        text.draw(in: rect, withAttributes: attrsText)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}

