import Foundation

public struct SelectionMask: Equatable, Sendable {
    public let width: Int
    public let height: Int
    private var values: [UInt8]

    public init(width: Int, height: Int, selected: Bool = false) throws {
        guard width > 0, height > 0 else {
            throw PixelBufferError.invalidDimensions(width: width, height: height)
        }
        self.width = width
        self.height = height
        self.values = Array(repeating: selected ? 255 : 0, count: width * height)
    }

    public func contains(x: Int, y: Int) -> Bool {
        x >= 0 && y >= 0 && x < width && y < height
    }

    public func alpha(x: Int, y: Int) -> UInt8 {
        guard contains(x: x, y: y) else { return 0 }
        return values[y * width + x]
    }

    public func isSelected(x: Int, y: Int) -> Bool {
        alpha(x: x, y: y) > 0
    }

    public mutating func setSelected(x: Int, y: Int, alpha: UInt8 = 255) {
        guard contains(x: x, y: y) else { return }
        values[y * width + x] = alpha
    }

    public var selectedCount: Int {
        values.filter { $0 > 0 }.count
    }

    public static func rectangle(width: Int, height: Int, x: Int, y: Int, rectWidth: Int, rectHeight: Int) throws -> SelectionMask {
        var mask = try SelectionMask(width: width, height: height)
        let minX = max(0, x)
        let minY = max(0, y)
        let maxX = min(width, x + max(0, rectWidth))
        let maxY = min(height, y + max(0, rectHeight))
        for row in minY ..< maxY {
            for column in minX ..< maxX {
                mask.setSelected(x: column, y: row)
            }
        }
        return mask
    }

    public static func ellipse(width: Int, height: Int, x: Int, y: Int, rectWidth: Int, rectHeight: Int) throws -> SelectionMask {
        var mask = try SelectionMask(width: width, height: height)
        guard rectWidth > 0, rectHeight > 0 else { return mask }
        let rx = Double(rectWidth) / 2.0
        let ry = Double(rectHeight) / 2.0
        let cx = Double(x) + rx
        let cy = Double(y) + ry
        for row in max(0, y) ..< min(height, y + rectHeight) {
            for column in max(0, x) ..< min(width, x + rectWidth) {
                let nx = (Double(column) + 0.5 - cx) / rx
                let ny = (Double(row) + 0.5 - cy) / ry
                if nx * nx + ny * ny <= 1.0 {
                    mask.setSelected(x: column, y: row)
                }
            }
        }
        return mask
    }

    public static func polygon(width: Int, height: Int, points: [(x: Int, y: Int)]) throws -> SelectionMask {
        var mask = try SelectionMask(width: width, height: height)
        guard points.count >= 3 else { return mask }
        for row in 0 ..< height {
            for column in 0 ..< width where pointInPolygon(x: Double(column) + 0.5, y: Double(row) + 0.5, points: points) {
                mask.setSelected(x: column, y: row)
            }
        }
        return mask
    }

    private static func pointInPolygon(x: Double, y: Double, points: [(x: Int, y: Int)]) -> Bool {
        var inside = false
        var j = points.count - 1
        for i in 0 ..< points.count {
            let xi = Double(points[i].x)
            let yi = Double(points[i].y)
            let xj = Double(points[j].x)
            let yj = Double(points[j].y)
            let intersects = ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / ((yj - yi) == 0 ? .leastNonzeroMagnitude : (yj - yi)) + xi)
            if intersects { inside.toggle() }
            j = i
        }
        return inside
    }
}
