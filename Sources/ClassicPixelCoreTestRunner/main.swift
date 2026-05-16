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

let tests: [(String, () throws -> Void)] = [
    ("PixelBuffer bounds and rows", testPixelBufferBoundsAndRows),
    ("Color conversion", testColorConversion),
    ("Selection masks", testSelectionMasks),
    ("Flood fill, transforms, adjustments, filters", testFloodFillTransformsAndAdjustments),
    ("Bucket, resize, undo", testBucketResizeAndUndo)
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
