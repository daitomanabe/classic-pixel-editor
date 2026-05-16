import Foundation

public enum ImageOperations {
    public static func converted(_ source: PixelBuffer, to mode: ColorMode, palette: [PixelColor] = []) -> PixelBuffer {
        var output = source
        output.mutateEachPixel { color, _, _ in
            color.converted(to: mode, palette: palette)
        }
        return output
    }

    public static func inverted(_ source: PixelBuffer, selection: SelectionMask? = nil) -> PixelBuffer {
        selectedMap(source, selection: selection) { PixelColor(r: 255 - $0.r, g: 255 - $0.g, b: 255 - $0.b, a: $0.a) }
    }

    public static func threshold(_ source: PixelBuffer, cutoff: UInt8, selection: SelectionMask? = nil) -> PixelBuffer {
        selectedMap(source, selection: selection) { color in
            let value: UInt8 = color.luminance >= cutoff ? 255 : 0
            return PixelColor(r: value, g: value, b: value, a: color.a)
        }
    }

    public static func brightnessContrast(_ source: PixelBuffer, brightness: Int, contrast: Int, selection: SelectionMask? = nil) -> PixelBuffer {
        let c = max(-255, min(255, contrast))
        let factor = Double(259 * (c + 255)) / Double(255 * (259 - c))
        return selectedMap(source, selection: selection) { color in
            func adjust(_ channel: UInt8) -> UInt8 {
                let contrasted = factor * (Double(channel) - 128.0) + 128.0
                return .clamped(Int(contrasted.rounded()) + brightness)
            }
            return PixelColor(r: adjust(color.r), g: adjust(color.g), b: adjust(color.b), a: color.a)
        }
    }

    public static func desaturated(_ source: PixelBuffer, amount: Double = 1.0, selection: SelectionMask? = nil) -> PixelBuffer {
        let mix = max(0.0, min(1.0, amount))
        return selectedMap(source, selection: selection) { color in
            let luminance = Double(color.luminance)
            func desaturate(_ channel: UInt8) -> UInt8 {
                .clamped(Int((Double(channel) * (1.0 - mix) + luminance * mix).rounded()))
            }
            return PixelColor(r: desaturate(color.r), g: desaturate(color.g), b: desaturate(color.b), a: color.a)
        }
    }

    public static func levels(_ source: PixelBuffer, blackPoint: UInt8, gamma: Double = 1.0, whitePoint: UInt8, selection: SelectionMask? = nil) -> PixelBuffer {
        let low = min(blackPoint, whitePoint)
        let high = max(blackPoint, whitePoint)
        let span = max(1, Int(high) - Int(low))
        let correctedGamma = max(0.01, gamma)
        return selectedMap(source, selection: selection) { color in
            func remap(_ channel: UInt8) -> UInt8 {
                let normalized = max(0.0, min(1.0, Double(Int(channel) - Int(low)) / Double(span)))
                return .clamped(Int((pow(normalized, 1.0 / correctedGamma) * 255.0).rounded()))
            }
            return PixelColor(r: remap(color.r), g: remap(color.g), b: remap(color.b), a: color.a)
        }
    }

    public static func resizedNearest(_ source: PixelBuffer, width: Int, height: Int) throws -> PixelBuffer {
        var output = try PixelBuffer(width: width, height: height, fill: .clear)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let sx = min(source.width - 1, x * source.width / width)
                let sy = min(source.height - 1, y * source.height / height)
                try output.setPixel(x: x, y: y, color: source.pixels[sy * source.width + sx])
            }
        }
        return output
    }

    public static func cropped(_ source: PixelBuffer, x: Int, y: Int, width: Int, height: Int) throws -> PixelBuffer {
        var output = try PixelBuffer(width: max(1, width), height: max(1, height), fill: .clear)
        for row in 0 ..< output.height {
            for column in 0 ..< output.width {
                let sx = x + column
                let sy = y + row
                if source.contains(x: sx, y: sy) {
                    try output.setPixel(x: column, y: row, color: source.pixels[sy * source.width + sx])
                }
            }
        }
        return output
    }

    public static func rotated90Clockwise(_ source: PixelBuffer) throws -> PixelBuffer {
        var output = try PixelBuffer(width: source.height, height: source.width, fill: .clear)
        for y in 0 ..< source.height {
            for x in 0 ..< source.width {
                try output.setPixel(x: source.height - 1 - y, y: x, color: source.pixels[y * source.width + x])
            }
        }
        return output
    }

    public static func rotated180(_ source: PixelBuffer) throws -> PixelBuffer {
        var output = try PixelBuffer(width: source.width, height: source.height, fill: .clear)
        for y in 0 ..< source.height {
            for x in 0 ..< source.width {
                try output.setPixel(x: source.width - 1 - x, y: source.height - 1 - y, color: source.pixels[y * source.width + x])
            }
        }
        return output
    }

    public static func flippedHorizontal(_ source: PixelBuffer) throws -> PixelBuffer {
        var output = try PixelBuffer(width: source.width, height: source.height, fill: .clear)
        for y in 0 ..< source.height {
            for x in 0 ..< source.width {
                try output.setPixel(x: source.width - 1 - x, y: y, color: source.pixels[y * source.width + x])
            }
        }
        return output
    }

    public static func flippedVertical(_ source: PixelBuffer) throws -> PixelBuffer {
        var output = try PixelBuffer(width: source.width, height: source.height, fill: .clear)
        for y in 0 ..< source.height {
            for x in 0 ..< source.width {
                try output.setPixel(x: x, y: source.height - 1 - y, color: source.pixels[y * source.width + x])
            }
        }
        return output
    }

    public static func blur3x3(_ source: PixelBuffer) throws -> PixelBuffer {
        try convolved(source, kernel: Array(repeating: Array(repeating: 1.0 / 9.0, count: 3), count: 3))
    }

    public static func sharpen3x3(_ source: PixelBuffer) throws -> PixelBuffer {
        try convolved(source, kernel: [
            [0, -1, 0],
            [-1, 5, -1],
            [0, -1, 0]
        ])
    }

    public static func edgeDetect3x3(_ source: PixelBuffer) throws -> PixelBuffer {
        try convolved(source, kernel: [
            [-1, -1, -1],
            [-1, 8, -1],
            [-1, -1, -1]
        ])
    }

    public static func emboss3x3(_ source: PixelBuffer) throws -> PixelBuffer {
        try convolved(source, kernel: [
            [-1, -1, 0],
            [-1, 0, 1],
            [0, 1, 1]
        ], bias: 128.0)
    }

    public static func median3x3(_ source: PixelBuffer) throws -> PixelBuffer {
        var output = try PixelBuffer(width: source.width, height: source.height, fill: .clear)
        for y in 0 ..< source.height {
            for x in 0 ..< source.width {
                var reds: [UInt8] = []
                var greens: [UInt8] = []
                var blues: [UInt8] = []
                var alphas: [UInt8] = []
                for dy in -1 ... 1 {
                    for dx in -1 ... 1 {
                        let sx = min(source.width - 1, max(0, x + dx))
                        let sy = min(source.height - 1, max(0, y + dy))
                        let color = source.pixels[sy * source.width + sx]
                        reds.append(color.r)
                        greens.append(color.g)
                        blues.append(color.b)
                        alphas.append(color.a)
                    }
                }
                try output.setPixel(x: x, y: y, color: PixelColor(
                    r: reds.sorted()[4],
                    g: greens.sorted()[4],
                    b: blues.sorted()[4],
                    a: alphas.sorted()[4]
                ))
            }
        }
        return output
    }

    public static func floodSelection(in source: PixelBuffer, startX: Int, startY: Int, tolerance: UInt8) throws -> SelectionMask {
        var mask = try SelectionMask(width: source.width, height: source.height)
        guard source.contains(x: startX, y: startY) else { return mask }
        let target = source.pixels[startY * source.width + startX]
        let limit = Int(tolerance) * Int(tolerance) * 3
        var queue = [(startX, startY)]
        var visited = Array(repeating: false, count: source.width * source.height)
        var index = 0
        while index < queue.count {
            let (x, y) = queue[index]
            index += 1
            guard source.contains(x: x, y: y) else { continue }
            let offset = y * source.width + x
            guard !visited[offset] else { continue }
            visited[offset] = true
            guard source.pixels[offset].distanceSquared(to: target) <= limit else { continue }
            mask.setSelected(x: x, y: y)
            queue.append((x + 1, y))
            queue.append((x - 1, y))
            queue.append((x, y + 1))
            queue.append((x, y - 1))
        }
        return mask
    }

    public static func paintBucket(_ source: PixelBuffer, startX: Int, startY: Int, replacement: PixelColor, tolerance: UInt8 = 0) throws -> PixelBuffer {
        let mask = try floodSelection(in: source, startX: startX, startY: startY, tolerance: tolerance)
        var output = source
        output.fill(replacement, selection: mask)
        return output
    }

    private static func selectedMap(_ source: PixelBuffer, selection: SelectionMask?, _ transform: (PixelColor) -> PixelColor) -> PixelBuffer {
        var output = source
        output.mutateEachPixel { color, x, y in
            if selection?.isSelected(x: x, y: y) ?? true {
                return transform(color)
            }
            return color
        }
        return output
    }

    private static func convolved(_ source: PixelBuffer, kernel: [[Double]], bias: Double = 0.0) throws -> PixelBuffer {
        let radiusY = kernel.count / 2
        let radiusX = (kernel.first?.count ?? 1) / 2
        var output = try PixelBuffer(width: source.width, height: source.height, fill: .clear)
        for y in 0 ..< source.height {
            for x in 0 ..< source.width {
                var r = 0.0
                var g = 0.0
                var b = 0.0
                for ky in 0 ..< kernel.count {
                    for kx in 0 ..< kernel[ky].count {
                        let sx = min(source.width - 1, max(0, x + kx - radiusX))
                        let sy = min(source.height - 1, max(0, y + ky - radiusY))
                        let color = source.pixels[sy * source.width + sx]
                        let weight = kernel[ky][kx]
                        r += Double(color.r) * weight
                        g += Double(color.g) * weight
                        b += Double(color.b) * weight
                    }
                }
                let original = source.pixels[y * source.width + x]
                try output.setPixel(x: x, y: y, color: PixelColor(
                    r: .clamped(Int((r + bias).rounded())),
                    g: .clamped(Int((g + bias).rounded())),
                    b: .clamped(Int((b + bias).rounded())),
                    a: original.a
                ))
            }
        }
        return output
    }
}
