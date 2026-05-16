import Foundation

public struct ImageEditCommand: Sendable {
    public let name: String
    public let before: PixelBuffer
    public let after: PixelBuffer

    public init(name: String, before: PixelBuffer, after: PixelBuffer) {
        self.name = name
        self.before = before
        self.after = after
    }
}

public struct EditHistory: Sendable {
    private var undoStack: [ImageEditCommand] = []
    private var redoStack: [ImageEditCommand] = []

    public init() {}

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func push(_ command: ImageEditCommand) {
        guard command.before != command.after else { return }
        undoStack.append(command)
        redoStack.removeAll()
    }

    public mutating func undo(current: inout PixelBuffer) -> String? {
        guard let command = undoStack.popLast() else { return nil }
        current = command.before
        redoStack.append(command)
        return command.name
    }

    public mutating func redo(current: inout PixelBuffer) -> String? {
        guard let command = redoStack.popLast() else { return nil }
        current = command.after
        undoStack.append(command)
        return command.name
    }
}
