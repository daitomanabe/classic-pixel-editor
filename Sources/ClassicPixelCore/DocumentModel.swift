import Foundation

public struct DocumentModel: Sendable {
    public var title: String
    public var colorMode: ColorMode
    public var buffer: PixelBuffer
    public var selection: SelectionMask?
    public var metadata: [String: String]
    public private(set) var history: EditHistory

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

    public mutating func apply(name: String, transform: (PixelBuffer) throws -> PixelBuffer) throws {
        let before = buffer
        let after = try transform(buffer)
        buffer = after
        history.push(ImageEditCommand(name: name, before: before, after: after))
    }

    public mutating func undo() -> String? {
        history.undo(current: &buffer)
    }

    public mutating func redo() -> String? {
        history.redo(current: &buffer)
    }
}
