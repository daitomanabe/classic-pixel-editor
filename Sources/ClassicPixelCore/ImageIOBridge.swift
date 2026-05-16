import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImageIOBridgeError: Error {
    case cannotCreateSource
    case cannotDecodeImage
    case cannotCreateContext
    case cannotCreateDestination
    case cannotFinalizeDestination
}

public enum ExportFormat: String, CaseIterable {
    case png
    case tiff

    public var utType: UTType {
        switch self {
        case .png: return .png
        case .tiff: return .tiff
        }
    }
}

public enum ImageIOBridge {
    public static func load(from url: URL) throws -> PixelBuffer {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ImageIOBridgeError.cannotCreateSource
        }
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageIOBridgeError.cannotDecodeImage
        }
        return try pixelBuffer(from: image)
    }

    public static func save(_ buffer: PixelBuffer, to url: URL, format: ExportFormat) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, format.utType.identifier as CFString, 1, nil) else {
            throw ImageIOBridgeError.cannotCreateDestination
        }
        CGImageDestinationAddImage(destination, try cgImage(from: buffer), nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ImageIOBridgeError.cannotFinalizeDestination
        }
    }

    public static func cgImage(from buffer: PixelBuffer) throws -> CGImage {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(buffer.width * buffer.height * 4)
        for pixel in buffer.pixels {
            bytes.append(pixel.r)
            bytes.append(pixel.g)
            bytes.append(pixel.b)
            bytes.append(pixel.a)
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else {
            throw ImageIOBridgeError.cannotCreateContext
        }
        guard let image = CGImage(
            width: buffer.width,
            height: buffer.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: buffer.width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw ImageIOBridgeError.cannotCreateContext
        }
        return image
    }

    public static func pixelBuffer(from image: CGImage) throws -> PixelBuffer {
        let width = image.width
        let height = image.height
        var bytes = Array(repeating: UInt8(0), count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImageIOBridgeError.cannotCreateContext
        }
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var pixels: [PixelColor] = []
        pixels.reserveCapacity(width * height)
        for index in stride(from: 0, to: bytes.count, by: 4) {
            pixels.append(PixelColor(r: bytes[index], g: bytes[index + 1], b: bytes[index + 2], a: bytes[index + 3]))
        }
        return try PixelBuffer(width: width, height: height, pixels: pixels)
    }
}
