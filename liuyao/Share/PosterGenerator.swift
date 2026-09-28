import SwiftUI
import UIKit

enum ShareQRCode {
    /// 海报上二维码的点尺寸。像素尺寸按渲染倍率对齐，避免再被放大发糊。
    static let pointSize: CGFloat = 72

    static func image(scale: CGFloat = PosterGenerator.renderScale) -> UIImage? {
        guard let source = bundledImage()?.cgImage else { return nil }
        let pixels = max(1, Int((pointSize * scale).rounded()))
        guard let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: pixels, height: pixels))
        context.draw(source, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
        guard let rendered = context.makeImage() else { return nil }
        return UIImage(cgImage: rendered, scale: scale, orientation: .up)
    }

    private static func bundledImage() -> UIImage? {
        let bundles = [Bundle(for: BundleToken.self), Bundle.main]
        for bundle in bundles {
            if let url = bundle.url(forResource: "AppStoreQR", withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
            if let url = bundle.url(forResource: "AppStoreQR", withExtension: "png", subdirectory: "Share"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return UIImage(named: "AppStoreQR")
    }
}

private final class BundleToken {}

@MainActor
enum PosterGenerator {
    /// 与 iPhone 屏幕倍率一致。完整版和推演之前用 2 倍，存进相册后会发糊。
    static let renderScale: CGFloat = 3

    static func render(_ payload: SharePayload, kind: PosterKind = .summary) throws -> UIImage {
        let scale = renderScale
        let slices = PosterSliceViews.make(payload: payload, kind: kind, qrImage: ShareQRCode.image(scale: scale))
        let images = try slices.map { try renderView($0, scale: scale) }
        if images.count == 1, let image = images.first {
            return image
        }
        return try stitch(images, fill: fillColor(for: payload))
    }

    private static func fillColor(for payload: SharePayload) -> (CGFloat, CGFloat, CGFloat) {
        switch payload {
        case .divination:
            return (26 / 255, 16 / 255, 51 / 255)
        case .deduction:
            return (10 / 255, 10 / 255, 31 / 255)
        }
    }

    private static func renderView<Content: View>(_ view: Content, scale: CGFloat) throws -> UIImage {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark))
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
        guard let image = renderer.uiImage,
              let cgImage = image.cgImage,
              cgImage.width > 1,
              cgImage.height > 1 else {
            throw ShareExportError.renderFailed
        }
        return image
    }

    private static func stitch(_ images: [UIImage], fill: (CGFloat, CGFloat, CGFloat)) throws -> UIImage {
        let sources = images.compactMap(\.cgImage)
        guard let first = sources.first else { throw ShareExportError.renderFailed }
        let totalHeight = sources.reduce(0) { $0 + $1.height }
        guard totalHeight > 0 else { throw ShareExportError.renderFailed }
        let longest = max(CGFloat(first.width), CGFloat(totalHeight))
        let ratio = longest > PosterPhotoEncoder.maxPixelLength ? PosterPhotoEncoder.maxPixelLength / longest : 1
        let outputWidth = max(1, Int((CGFloat(first.width) * ratio).rounded(.down)))
        let outputHeight = max(1, Int((CGFloat(totalHeight) * ratio).rounded(.down)))
        guard let context = CGContext(
            data: nil,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw ShareExportError.renderFailed
        }
        context.interpolationQuality = ratio == 1 ? .none : .high
        context.setFillColor(CGColor(srgbRed: fill.0, green: fill.1, blue: fill.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
        var y = outputHeight
        for (index, source) in sources.enumerated() {
            let sliceHeight: Int
            if index == sources.count - 1 {
                sliceHeight = y
            } else {
                let proportional = Int((CGFloat(source.height) * CGFloat(outputHeight) / CGFloat(totalHeight)).rounded())
                let reserved = sources.count - 1 - index
                sliceHeight = min(max(proportional, 1), max(1, y - reserved))
            }
            y -= sliceHeight
            context.draw(
                source,
                in: CGRect(x: 0, y: CGFloat(y), width: CGFloat(outputWidth), height: CGFloat(sliceHeight))
            )
        }
        guard let stitched = context.makeImage() else { throw ShareExportError.renderFailed }
        return UIImage(cgImage: stitched)
    }
}
