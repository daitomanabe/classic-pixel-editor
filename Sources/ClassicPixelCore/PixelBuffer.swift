import Foundation

public enum PixelBufferError: Error, Equatable {
    case invalidDimensions(width: Int, height: Int)
    case outOfBounds(x: Int, y: Int)
    case mismatchedStorage(expected: Int, actual: Int)
}

public struct PixelBuffer: Equatable, Sendable {
    public let width: Int
    public let height: Int
    private var storage: [PixelColor]

    public init(width: Int, height: Int, fill: PixelColor = .clear) throws {
        guard width > 0, height > 0 else {
            throw PixelBufferError.invalidDimensions(width: width, height: height)
        }
        self.width = width
        self.height = height
        self.storage = Array(repeating: fill, count: width * height)
    }

    public init(width: Int, height: Int, pixels: [PixelColor]) throws {
        guard width > 0, height > 0 else {
            throw PixelBufferError.invalidDimensions(width: width, height: height)
        }
        guard pixels.count == width * height else {
            throw PixelBufferError.mismatchedStorage(expected: width * height, actual: pixels.count)
        }
        self.width = width
        self.height = height
        self.storage = pixels
    }

    public var pixels: [PixelColor] {
        storage
    }

    public func contains(x: Int, y: Int) -> Bool {
        x >= 0 && y >= 0 && x < width && y < height
    }

    public func pixel(x: Int, y: Int) throws -> PixelColor {
        guard contains(x: x, y: y) else {
            throw PixelBufferError.outOfBounds(x: x, y: y)
        }
        return storage[y * width + x]
    }

    public mutating func setPixel(x: Int, y: Int, color: PixelColor) throws {
        guard contains(x: x, y: y) else {
            throw PixelBufferError.outOfBounds(x: x, y: y)
        }
        storage[y * width + x] = color
    }

    public func row(y: Int) throws -> ArraySlice<PixelColor> {
        guard y >= 0 && y < height else {
            throw PixelBufferError.outOfBounds(x: 0, y: y)
        }
        let start = y * width
        return storage[start ..< start + width]
    }

    public mutating func fill(_ color: PixelColor, selection: SelectionMask? = nil) {
        if let selection {
            for y in 0 ..< height {
                for x in 0 ..< width where selection.isSelected(x: x, y: y) {
                    storage[y * width + x] = color
                }
            }
        } else {
            storage = Array(repeating: color, count: width * height)
        }
    }

    public mutating func mutateEachPixel(_ transform: (PixelColor, Int, Int) -> PixelColor) {
        for y in 0 ..< height {
            for x in 0 ..< width {
                let index = y * width + x
                storage[index] = transform(storage[index], x, y)
            }
        }
    }
}
