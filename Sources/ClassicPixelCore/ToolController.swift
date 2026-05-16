import Foundation

public enum EditorTool: String, CaseIterable, Sendable {
    case pencil
    case brush
    case eraser
    case paintBucket
    case eyedropper
    case rectangularSelection
    case ellipticalSelection
    case lassoSelection
    case magicWand
}

public enum ToolInteractionKind: Equatable, Sendable {
    case continuousDrawing
    case clickEditing
    case dragSelection
    case clickSelection
}

extension EditorTool {
    public var interactionKind: ToolInteractionKind {
        switch self {
        case .pencil, .brush, .eraser:
            return .continuousDrawing
        case .paintBucket, .eyedropper:
            return .clickEditing
        case .rectangularSelection, .ellipticalSelection, .lassoSelection:
            return .dragSelection
        case .magicWand:
            return .clickSelection
        }
    }

    public var createsSelection: Bool {
        switch interactionKind {
        case .dragSelection, .clickSelection:
            return true
        case .continuousDrawing, .clickEditing:
            return false
        }
    }
}

public struct ToolController: Sendable {
    public var foreground = PixelColor.black
    public var background = PixelColor.white
    public var brushRadius = 4
    public var tolerance: UInt8 = 0

    public init() {}

    public func drawPoint(on source: PixelBuffer, x: Int, y: Int, tool: EditorTool) throws -> PixelBuffer {
        var output = source
        let color: PixelColor
        let radius: Int
        switch tool {
        case .pencil:
            color = foreground
            radius = 0
        case .brush:
            color = foreground
            radius = max(1, brushRadius)
        case .eraser:
            color = .clear
            radius = max(1, brushRadius)
        default:
            return output
        }
        for yy in (y - radius) ... (y + radius) {
            for xx in (x - radius) ... (x + radius) where output.contains(x: xx, y: yy) {
                if radius == 0 || (xx - x) * (xx - x) + (yy - y) * (yy - y) <= radius * radius {
                    try output.setPixel(x: xx, y: yy, color: color)
                }
            }
        }
        return output
    }

    public func eyedropper(from source: PixelBuffer, x: Int, y: Int) throws -> PixelColor {
        try source.pixel(x: x, y: y)
    }

    public func selection(on source: PixelBuffer, tool: EditorTool, startX: Int, startY: Int, endX: Int, endY: Int, lassoPoints: [(x: Int, y: Int)] = []) throws -> SelectionMask? {
        switch tool {
        case .rectangularSelection:
            let x = min(startX, endX)
            let y = min(startY, endY)
            return try SelectionMask.rectangle(width: source.width, height: source.height, x: x, y: y, rectWidth: abs(endX - startX) + 1, rectHeight: abs(endY - startY) + 1)
        case .ellipticalSelection:
            let x = min(startX, endX)
            let y = min(startY, endY)
            return try SelectionMask.ellipse(width: source.width, height: source.height, x: x, y: y, rectWidth: abs(endX - startX) + 1, rectHeight: abs(endY - startY) + 1)
        case .lassoSelection:
            return try SelectionMask.polygon(width: source.width, height: source.height, points: lassoPoints)
        case .magicWand:
            return try ImageOperations.floodSelection(in: source, startX: startX, startY: startY, tolerance: tolerance)
        default:
            return nil
        }
    }
}
