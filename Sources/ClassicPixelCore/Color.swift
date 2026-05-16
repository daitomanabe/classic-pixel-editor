import Foundation

public enum ColorMode: String, CaseIterable, Sendable {
    case grayscale
    case indexedPalette
    case rgb
    case rgba
}

public struct PixelColor: Equatable, Sendable {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8
    public var a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public static let clear = PixelColor(r: 0, g: 0, b: 0, a: 0)
    public static let white = PixelColor(r: 255, g: 255, b: 255)
    public static let black = PixelColor(r: 0, g: 0, b: 0)

    public var luminance: UInt8 {
        UInt8.clamped((Int(r) * 299 + Int(g) * 587 + Int(b) * 114) / 1000)
    }

    public func distanceSquared(to other: PixelColor, includeAlpha: Bool = false) -> Int {
        let dr = Int(r) - Int(other.r)
        let dg = Int(g) - Int(other.g)
        let db = Int(b) - Int(other.b)
        let da = includeAlpha ? Int(a) - Int(other.a) : 0
        return dr * dr + dg * dg + db * db + da * da
    }

    public func converted(to mode: ColorMode, palette: [PixelColor] = []) -> PixelColor {
        switch mode {
        case .grayscale:
            let y = luminance
            return PixelColor(r: y, g: y, b: y, a: a)
        case .indexedPalette:
            guard let nearest = palette.min(by: { distanceSquared(to: $0) < distanceSquared(to: $1) }) else {
                return self
            }
            return PixelColor(r: nearest.r, g: nearest.g, b: nearest.b, a: a)
        case .rgb:
            return PixelColor(r: r, g: g, b: b, a: 255)
        case .rgba:
            return self
        }
    }
}

extension UInt8 {
    public static func clamped(_ value: Int) -> UInt8 {
        UInt8(Swift.max(0, Swift.min(255, value)))
    }
}
