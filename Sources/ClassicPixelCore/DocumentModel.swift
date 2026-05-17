import Foundation

public struct DocumentModel: Sendable {
    public var title: String
    public var colorMode: ColorMode
    public var buffer: PixelBuffer
    public var selection: SelectionMask?
    public var metadata: [String: String]
    public private(set) var history: EditHistory

    private var strokeName: String?
    private var strokeBefore: PixelBuffer?

    public init(title: String = "Untitled", width: Int, height: Int, colorMode: ColorMode = .rgba, background: PixelColor = .white) throws {
        self.title = title
        self.colorMode = colorMode
        self.buffer = try PixelBuffer(width: width, height: height, fill: background.converted(to: colorMode))
        self.metadata = [:]
        self.history = EditHistory()
    }

    public init(title: String, colorMode: ColorMode = .rgba, buffer: PixelBuffer, metadata: [String: String] = [:]) {
        self.title = title
        self.colorMode = colorMode
        self.buffer = buffer
        self.metadata = metadata
        self.history = EditHistory()
    }

    public var isStrokeActive: Bool { strokeBefore != nil }

    public mutating func apply(name: String, transform: (PixelBuffer) throws -> PixelBuffer) throws {
        if isStrokeActive { endStroke() }
        let before = buffer
        let after = try transform(buffer)
        buffer = after
        history.push(ImageEditCommand(name: name, before: before, after: after))
    }

    public mutating func beginStroke(name: String) {
        if isStrokeActive { endStroke() }
        strokeName = name
        strokeBefore = buffer
    }

    public mutating func extendStroke(_ transform: (PixelBuffer) throws -> PixelBuffer) throws {
        guard isStrokeActive else {
            try apply(name: strokeName ?? "Stroke", transform: transform)
            return
        }
        buffer = try transform(buffer)
    }

    public mutating func endStroke() {
        guard let before = strokeBefore, let name = strokeName else { return }
        let after = buffer
        strokeBefore = nil
        strokeName = nil
        history.push(ImageEditCommand(name: name, before: before, after: after))
    }

    public mutating func undo() -> String? {
        if isStrokeActive { endStroke() }
        return history.undo(current: &buffer)
    }

    public mutating func redo() -> String? {
        if isStrokeActive { endStroke() }
        return history.redo(current: &buffer)
    }
}
