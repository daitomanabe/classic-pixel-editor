import ClassicPixelCore
import Foundation

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): return message
        }
    }
}

func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    guard try condition() else {
        throw TestFailure.failed(message)
    }
}

func testPixelBufferBoundsAndRows() throws {
    var buffer = try PixelBuffer(width: 2, height: 2, fill: .white)
    try buffer.setPixel(x: 1, y: 1, color: .black)
    try expect(try buffer.pixel(x: 1, y: 1) == .black, "pixel write/read failed")
    do {
        _ = try buffer.pixel(x: 2, y: 0)
        throw TestFailure.failed("out-of-bounds access did not throw")
    } catch PixelBufferError.outOfBounds(x: 2, y: 0) {}
    try expect(Array(try buffer.row(y: 1)) == [PixelColor.white, PixelColor.black], "safe row read failed")
}

func testColorConversion() throws {
    let color = PixelColor(r: 10, g: 20, b: 250, a: 99)
    let gray = color.converted(to: .grayscale)
    try expect(gray.r == gray.g && gray.g == gray.b, "grayscale conversion did not equalize channels")
    try expect(gray.a == 99, "grayscale conversion did not preserve alpha")
    let palette = [PixelColor.black, PixelColor(r: 8, g: 22, b: 245)]
    try expect(color.converted(to: .indexedPalette, palette: palette).b == 245, "palette nearest-color conversion failed")
    try expect(color.converted(to: .rgb).a == 255, "rgb conversion did not force opaque alpha")
}

func testSelectionMasks() throws {
    let rectangle = try SelectionMask.rectangle(width: 4, height: 4, x: -1, y: 1, rectWidth: 3, rectHeight: 3)
    try expect(rectangle.isSelected(x: 0, y: 1), "rectangle selection missed clipped origin")
    try expect(rectangle.isSelected(x: 1, y: 3), "rectangle selection missed clipped edge")
    try expect(!rectangle.isSelected(x: 2, y: 1), "rectangle selection over-selected")
    try expect(rectangle.selectedCount == 6, "rectangle selection count was not deterministic")

    let ellipse = try SelectionMask.ellipse(width: 5, height: 5, x: 0, y: 0, rectWidth: 5, rectHeight: 5)
    try expect(ellipse.isSelected(x: 2, y: 2), "ellipse selection missed center")
    try expect(!ellipse.isSelected(x: 0, y: 0), "ellipse selection included corner")

    let polygon = try SelectionMask.polygon(width: 5, height: 5, points: [(x: 1, y: 1), (x: 4, y: 1), (x: 1, y: 4)])
    try expect(polygon.isSelected(x: 1, y: 1), "polygon selection missed edge")
    try expect(polygon.isSelected(x: 2, y: 1), "polygon selection missed interior")
    try expect(!polygon.isSelected(x: 4, y: 4), "polygon selection included exterior")
}

func testFloodFillTransformsAndAdjustments() throws {
    var floodSource = try PixelBuffer(width: 3, height: 3, fill: .white)
    try floodSource.setPixel(x: 1, y: 0, color: .black)
    try floodSource.setPixel(x: 1, y: 1, color: .black)
    try floodSource.setPixel(x: 1, y: 2, color: .black)
    let selection = try ImageOperations.floodSelection(in: floodSource, startX: 0, startY: 1, tolerance: 0)
    try expect(selection.isSelected(x: 0, y: 1), "flood fill missed start side")
    try expect(!selection.isSelected(x: 2, y: 1), "flood fill crossed color boundary")
    try expect(selection.selectedCount == 3, "flood fill selected wrong region size")

    let pixels = [
        PixelColor(r: 1, g: 0, b: 0),
        PixelColor(r: 2, g: 0, b: 0),
        PixelColor(r: 3, g: 0, b: 0),
        PixelColor(r: 4, g: 0, b: 0)
    ]
    let source = try PixelBuffer(width: 2, height: 2, pixels: pixels)
    try expect(try ImageOperations.flippedHorizontal(source).pixels.map(\.r) == [2, 1, 4, 3], "horizontal flip failed")
    try expect(try ImageOperations.flippedVertical(source).pixels.map(\.r) == [3, 4, 1, 2], "vertical flip failed")
    try expect(try ImageOperations.rotated180(source).pixels.map(\.r) == [4, 3, 2, 1], "rotate 180 failed")
    try expect(try ImageOperations.rotated90Clockwise(source).pixels.map(\.r) == [3, 1, 4, 2], "rotate 90 failed")

    let gradient = try PixelBuffer(width: 3, height: 1, pixels: [
        PixelColor(r: 0, g: 0, b: 0),
        PixelColor(r: 120, g: 120, b: 120),
        PixelColor(r: 255, g: 255, b: 255)
    ])
    try expect(ImageOperations.inverted(gradient).pixels.map(\.r) == [255, 135, 0], "invert failed")
    try expect(ImageOperations.threshold(gradient, cutoff: 128).pixels.map(\.r) == [0, 0, 255], "threshold failed")
    try expect(ImageOperations.brightnessContrast(gradient, brightness: 20, contrast: 0).pixels[1].r > 120, "brightness failed")
    try expect(ImageOperations.levels(gradient, blackPoint: 0, gamma: 1.0, whitePoint: 255).pixels.map(\.r) == [0, 120, 255], "levels identity failed")
    try expect(try ImageOperations.blur3x3(gradient).pixels.count == 3, "blur output size failed")
    try expect(try ImageOperations.sharpen3x3(gradient).pixels.count == 3, "sharpen output size failed")
    try expect(try ImageOperations.edgeDetect3x3(gradient).pixels.count == 3, "edge detect output size failed")
    try expect(try ImageOperations.median3x3(gradient).pixels.count == 3, "median output size failed")
}

func testBucketResizeAndUndo() throws {
    let source = try PixelBuffer(width: 2, height: 2, pixels: [.white, .black, .white, .black])
    let filled = try ImageOperations.paintBucket(source, startX: 0, startY: 0, replacement: PixelColor(r: 9, g: 9, b: 9))
    try expect(try filled.pixel(x: 0, y: 0) == PixelColor(r: 9, g: 9, b: 9), "paint bucket missed start")
    try expect(try filled.pixel(x: 0, y: 1) == PixelColor(r: 9, g: 9, b: 9), "paint bucket missed contiguous pixel")
    try expect(try filled.pixel(x: 1, y: 0) == .black, "paint bucket overfilled")

    let resized = try ImageOperations.resizedNearest(source, width: 4, height: 4)
    try expect(resized.width == 4 && resized.height == 4, "resize dimensions failed")
    try expect(try resized.pixel(x: 3, y: 0) == .black, "nearest resize sample failed")

    var model = try DocumentModel(width: 2, height: 1, background: .white)
    try model.apply(name: "one pixel") { current in
        var output = current
        try output.setPixel(x: 0, y: 0, color: .black)
        return output
    }
    try expect(try model.buffer.pixel(x: 0, y: 0) == .black, "undo setup failed")
    try expect(model.undo() == "one pixel", "undo name failed")
    try expect(try model.buffer.pixel(x: 0, y: 0) == .white, "undo restore failed")
    try expect(model.redo() == "one pixel", "redo name failed")
    try expect(try model.buffer.pixel(x: 0, y: 0) == .black, "redo restore failed")
}

func testStrokeSessionGroupsExtendsIntoSingleUndo() throws {
    var model = try DocumentModel(width: 4, height: 4, background: .white)
    try expect(!model.history.canUndo, "history started non-empty")
    try expect(!model.isStrokeActive, "stroke incorrectly active before begin")

    model.beginStroke(name: "Pencil")
    try expect(model.isStrokeActive, "stroke not active after begin")
    for x in 0 ..< 3 {
        try model.extendStroke { current in
            var output = current
            try output.setPixel(x: x, y: 0, color: .black)
            return output
        }
    }
    model.endStroke()
    try expect(!model.isStrokeActive, "stroke still active after end")

    try expect(try model.buffer.pixel(x: 0, y: 0) == .black, "stroke sample 0 missing")
    try expect(try model.buffer.pixel(x: 1, y: 0) == .black, "stroke sample 1 missing")
    try expect(try model.buffer.pixel(x: 2, y: 0) == .black, "stroke sample 2 missing")
    try expect(model.history.canUndo, "stroke did not push a history entry")

    try expect(model.undo() == "Pencil", "stroke undo did not return name")
    try expect(try model.buffer.pixel(x: 0, y: 0) == .white, "stroke undo did not restore pixel 0")
    try expect(try model.buffer.pixel(x: 1, y: 0) == .white, "stroke undo did not restore pixel 1")
    try expect(try model.buffer.pixel(x: 2, y: 0) == .white, "stroke undo did not restore pixel 2")
    try expect(!model.history.canUndo, "stroke undo did not consume the only history entry")

    try expect(model.redo() == "Pencil", "stroke redo did not return name")
    try expect(try model.buffer.pixel(x: 0, y: 0) == .black, "stroke redo did not restore pixel 0")
    try expect(try model.buffer.pixel(x: 2, y: 0) == .black, "stroke redo did not restore pixel 2")
}

func testStrokeSessionEmptyStrokeDoesNotPushHistory() throws {
    var model = try DocumentModel(width: 2, height: 2, background: .white)

    model.beginStroke(name: "Pencil")
    model.endStroke()
    try expect(!model.history.canUndo, "empty stroke pushed to history")

    model.beginStroke(name: "Brush")
    try model.extendStroke { $0 }
    try model.extendStroke { $0 }
    model.endStroke()
    try expect(!model.history.canUndo, "identity-extend stroke pushed to history")
}

func testStrokeSessionFollowedByApplyProducesTwoUndoSteps() throws {
    var model = try DocumentModel(width: 2, height: 1, background: .white)

    model.beginStroke(name: "Pencil")
    try model.extendStroke { current in
        var output = current
        try output.setPixel(x: 0, y: 0, color: .black)
        return output
    }
    model.endStroke()

    try model.apply(name: "Invert") { ImageOperations.inverted($0) }

    try expect(try model.buffer.pixel(x: 0, y: 0) == .white, "invert did not flip stroke pixel")
    try expect(try model.buffer.pixel(x: 1, y: 0) == .black, "invert did not flip background pixel")

    try expect(model.undo() == "Invert", "expected invert on top of undo stack")
    try expect(try model.buffer.pixel(x: 0, y: 0) == .black, "invert undo did not restore stroke pixel")
    try expect(try model.buffer.pixel(x: 1, y: 0) == .white, "invert undo did not restore background pixel")

    try expect(model.undo() == "Pencil", "expected stroke beneath invert on undo stack")
    try expect(try model.buffer.pixel(x: 0, y: 0) == .white, "stroke undo did not restore initial pixel")
    try expect(!model.history.canUndo, "history not empty after two undos")
}

func testStrokeSessionApplyDuringActiveStrokeAutoEndsStroke() throws {
    var model = try DocumentModel(width: 2, height: 1, background: .white)

    model.beginStroke(name: "Pencil")
    try model.extendStroke { current in
        var output = current
        try output.setPixel(x: 0, y: 0, color: .black)
        return output
    }
    try model.apply(name: "Invert") { ImageOperations.inverted($0) }

    try expect(!model.isStrokeActive, "stroke still active after defensive auto-end")
    try expect(model.undo() == "Invert", "menu command not on top of undo stack")
    try expect(model.undo() == "Pencil", "auto-ended stroke not beneath menu command")
    try expect(!model.history.canUndo, "history not empty after two undos")
}

let tests: [(String, () throws -> Void)] = [
    ("PixelBuffer bounds and rows", testPixelBufferBoundsAndRows),
    ("Color conversion", testColorConversion),
    ("Selection masks", testSelectionMasks),
    ("Flood fill, transforms, adjustments, filters", testFloodFillTransformsAndAdjustments),
    ("Bucket, resize, undo", testBucketResizeAndUndo),
    ("Stroke session groups extends into single undo", testStrokeSessionGroupsExtendsIntoSingleUndo),
    ("Stroke session empty stroke does not push history", testStrokeSessionEmptyStrokeDoesNotPushHistory),
    ("Stroke session followed by apply produces two undo steps", testStrokeSessionFollowedByApplyProducesTwoUndoSteps),
    ("Stroke session apply during active stroke auto-ends stroke", testStrokeSessionApplyDuringActiveStrokeAutoEndsStroke)
]

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("PASS \(name)")
    } catch {
        failures += 1
        print("FAIL \(name): \(error)")
    }
}

if failures > 0 {
    exit(1)
}
print("All \(tests.count) core test groups passed")
