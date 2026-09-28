import Photos
import UIKit

enum PhotoLibrarySaver {
    static func save(_ image: UIImage) async throws {
        let status = await authorization()
        guard status == .authorized || status == .limited else {
            throw ShareExportError.permissionDenied
        }
        guard let data = PosterPhotoEncoder.jpegData(from: image) else {
            throw ShareExportError.saveFailed
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }) { success, error in
                if success {
                    continuation.resume()
                } else if let error {
                    continuation.resume(throwing: classify(error))
                } else {
                    continuation.resume(throwing: ShareExportError.saveFailed)
                }
            }
        }
    }

    private static func authorization() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current != .notDetermined { return current }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private static func classify(_ error: Error) -> ShareExportError {
        let ns = error as NSError
        if ns.domain == PHPhotosErrorDomain && ns.code == PHPhotosError.Code.notEnoughSpace.rawValue {
            return .diskFull
        }
        return ShareExportError.fromFileError(error)
    }
}

enum PosterPhotoEncoder {
    /// ImageIO 的 PNG 编码器遇到超长图会报 zlib error / No IDATs。长边压到这个像素以内再存 JPEG。
    static let maxPixelLength: CGFloat = 16_000
    static let jpegQuality: CGFloat = 0.98

    static func targetPixelSize(width: CGFloat, height: CGFloat) -> CGSize {
        let longest = max(width, height)
        guard longest > maxPixelLength, longest > 0 else {
            return CGSize(width: max(1, floor(width)), height: max(1, floor(height)))
        }
        let ratio = maxPixelLength / longest
        return CGSize(width: max(1, floor(width * ratio)), height: max(1, floor(height * ratio)))
    }

    static func jpegData(from image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else {
            return image.jpegData(compressionQuality: jpegQuality)
        }
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        guard max(pixelWidth, pixelHeight) > maxPixelLength else {
            return image.jpegData(compressionQuality: jpegQuality)
        }
        let target = targetPixelSize(width: pixelWidth, height: pixelHeight)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(target.width),
            height: Int(target.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return image.jpegData(compressionQuality: jpegQuality)
        }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: target))
        guard let scaled = context.makeImage() else { return nil }
        return UIImage(cgImage: scaled).jpegData(compressionQuality: jpegQuality)
    }
}
