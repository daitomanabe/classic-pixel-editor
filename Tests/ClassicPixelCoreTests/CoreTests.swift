import XCTest
@testable import ClassicPixelCore

final class CoreTests: XCTestCase {
    func testPixelBufferBoundsAndRows() throws {
        var buffer = try PixelBuffer(width: 2, height: 2, fill: .white)
        try buffer.setPixel(x: 1, y: 1, color: .black)

        XCTAssertEqual(try buffer.pixel(x: 1, y: 1), .black)
        XCTAssertThrowsError(try buffer.pixel(x: 2, y: 0)) { error in
            guard case PixelBufferError.outOfBounds(x: 2, y: 0) = error else {
                XCTFail("Expected out-of-bounds error, got \(error)")
                return
            }
        }
        XCTAssertEqual(Array(try buffer.row(y: 1)), [PixelColor.white, PixelColor.black])
    }

    func testColorConversion() {
        let color = PixelColor(r: 10, g: 20, b: 250, a: 99)
        let gray = color.converted(to: .grayscale)

        XCTAssertEqual(gray.r, gray.g)
        XCTAssertEqual(gray.g, gray.b)
        XCTAssertEqual(gray.a, 99)

        let palette = [PixelColor.black, PixelColor(r: 8, g: 22, b: 245)]
        XCTAssertEqual(color.converted(to: .indexedPalette, palette: palette).b, 245)
        XCTAssertEqual(color.converted(to: .rgb).a, 255)
    }

    func testSelectionMasks() throws {
        let rectangle = try SelectionMask.rectangle(width: 4, height: 4, x: -1, y: 1, rectWidth: 3, rectHeight: 3)
        XCTAssertTrue(rectangle.isSelected(x: 0, y: 1))
        XCTAssertTrue(rectangle.isSelected(x: 1, y: 3))
        XCTAssertFalse(rectangle.isSelected(x: 2, y: 1))
        XCTAssertEqual(rectangle.selectedCount, 6)

        let ellipse = try SelectionMask.ellipse(width: 5, height: 5, x: 0, y: 0, rectWidth: 5, rectHeight: 5)
        XCTAssertTrue(ellipse.isSelected(x: 2, y: 2))
        XCTAssertFalse(ellipse.isSelected(x: 0, y: 0))

        let polygon = try SelectionMask.polygon(width: 5, height: 5, points: [(x: 1, y: 1), (x: 4, y: 1), (x: 1, y: 4)])
        XCTAssertTrue(polygon.isSelected(x: 1, y: 1))
        XCTAssertTrue(polygon.isSelected(x: 2, y: 1))
        XCTAssertFalse(polygon.isSelected(x: 4, y: 4))
    }

    func testLassoPolygonMaskGeneration() throws {
        let points = [(x: 1, y: 1), (x: 4, y: 1), (x: 4, y: 4), (x: 1, y: 4)]
        let mask = try SelectionMask.polygon(width: 6, height: 6, points: points)

        XCTAssertEqual(mask.selectedCount, 9)
        XCTAssertTrue(mask.isSelected(x: 1, y: 1))
        XCTAssertTrue(mask.isSelected(x: 3, y: 3))
        XCTAssertFalse(mask.isSelected(x: 0, y: 0))
        XCTAssertFalse(mask.isSelected(x: 4, y: 4))
    }

    func testToolInteractionKinds() throws {
        XCTAssertEqual(EditorTool.pencil.interactionKind, .continuousDrawing)
        XCTAssertEqual(EditorTool.brush.interactionKind, .continuousDrawing)
        XCTAssertEqual(EditorTool.eraser.interactionKind, .continuousDrawing)
        XCTAssertEqual(EditorTool.paintBucket.interactionKind, .clickEditing)
        XCTAssertEqual(EditorTool.eyedropper.interactionKind, .clickEditing)
        XCTAssertEqual(EditorTool.rectangularSelection.interactionKind, .dragSelection)
        XCTAssertEqual(EditorTool.ellipticalSelection.interactionKind, .dragSelection)
        XCTAssertEqual(EditorTool.lassoSelection.interactionKind, .dragSelection)
        XCTAssertEqual(EditorTool.magicWand.interactionKind, .clickSelection)

        XCTAssertFalse(EditorTool.pencil.createsSelection)
        XCTAssertFalse(EditorTool.paintBucket.createsSelection)
        XCTAssertTrue(EditorTool.rectangularSelection.createsSelection)
        XCTAssertTrue(EditorTool.magicWand.createsSelection)
    }

    func testToolControllerSelectionOnlyForSelectionTools() throws {
        let buffer = try PixelBuffer(width: 4, height: 4, fill: .white)
        let controller = ToolController()

        XCTAssertNil(try controller.selection(on: buffer, tool: .pencil, startX: 0, startY: 0, endX: 2, endY: 2))
        XCTAssertNil(try controller.selection(on: buffer, tool: .paintBucket, startX: 0, startY: 0, endX: 2, endY: 2))

        let rectangle = try XCTUnwrap(controller.selection(on: buffer, tool: .rectangularSelection, startX: 0, startY: 0, endX: 1, endY: 1))
        XCTAssertEqual(rectangle.selectedCount, 4)

        let lasso = try XCTUnwrap(controller.selection(
            on: buffer,
            tool: .lassoSelection,
            startX: 1,
            startY: 1,
            endX: 3,
            endY: 3,
            lassoPoints: [(x: 1, y: 1), (x: 3, y: 1), (x: 3, y: 3), (x: 1, y: 3)]
        ))
        XCTAssertEqual(lasso.selectedCount, 4)
        XCTAssertTrue(lasso.isSelected(x: 1, y: 1))

        let wand = try XCTUnwrap(controller.selection(on: buffer, tool: .magicWand, startX: 0, startY: 0, endX: 0, endY: 0))
        XCTAssertEqual(wand.selectedCount, 16)
    }

    func testFloodFillTransformsAdjustmentsAndFilters() throws {
        var floodSource = try PixelBuffer(width: 3, height: 3, fill: .white)
        try floodSource.setPixel(x: 1, y: 0, color: .black)
        try floodSource.setPixel(x: 1, y: 1, color: .black)
        try floodSource.setPixel(x: 1, y: 2, color: .black)

        let selection = try ImageOperations.floodSelection(in: floodSource, startX: 0, startY: 1, tolerance: 0)
        XCTAssertTrue(selection.isSelected(x: 0, y: 1))
        XCTAssertFalse(selection.isSelected(x: 2, y: 1))
        XCTAssertEqual(selection.selectedCount, 3)

        let pixels = [
            PixelColor(r: 1, g: 0, b: 0),
            PixelColor(r: 2, g: 0, b: 0),
            PixelColor(r: 3, g: 0, b: 0),
            PixelColor(r: 4, g: 0, b: 0)
        ]
        let source = try PixelBuffer(width: 2, height: 2, pixels: pixels)
        XCTAssertEqual(try ImageOperations.flippedHorizontal(source).pixels.map(\.r), [2, 1, 4, 3])
        XCTAssertEqual(try ImageOperations.flippedVertical(source).pixels.map(\.r), [3, 4, 1, 2])
        XCTAssertEqual(try ImageOperations.rotated180(source).pixels.map(\.r), [4, 3, 2, 1])
        XCTAssertEqual(try ImageOperations.rotated90Clockwise(source).pixels.map(\.r), [3, 1, 4, 2])

        let gradient = try PixelBuffer(width: 3, height: 1, pixels: [
            PixelColor(r: 0, g: 0, b: 0),
            PixelColor(r: 120, g: 120, b: 120),
            PixelColor(r: 255, g: 255, b: 255)
        ])
        XCTAssertEqual(ImageOperations.inverted(gradient).pixels.map(\.r), [255, 135, 0])
        XCTAssertEqual(ImageOperations.threshold(gradient, cutoff: 128).pixels.map(\.r), [0, 0, 255])
        XCTAssertGreaterThan(ImageOperations.brightnessContrast(gradient, brightness: 20, contrast: 0).pixels[1].r, 120)
        XCTAssertEqual(ImageOperations.levels(gradient, blackPoint: 0, gamma: 1.0, whitePoint: 255).pixels.map(\.r), [0, 120, 255])
        XCTAssertEqual(try ImageOperations.blur3x3(gradient).pixels.count, 3)
        XCTAssertEqual(try ImageOperations.sharpen3x3(gradient).pixels.count, 3)
        XCTAssertEqual(try ImageOperations.edgeDetect3x3(gradient).pixels.count, 3)
        XCTAssertEqual(try ImageOperations.median3x3(gradient).pixels.count, 3)
    }

    func testPaintBucketResizeAndUndo() throws {
        let source = try PixelBuffer(width: 2, height: 2, pixels: [.white, .black, .white, .black])
        let filled = try ImageOperations.paintBucket(source, startX: 0, startY: 0, replacement: PixelColor(r: 9, g: 9, b: 9))
        XCTAssertEqual(try filled.pixel(x: 0, y: 0), PixelColor(r: 9, g: 9, b: 9))
        XCTAssertEqual(try filled.pixel(x: 0, y: 1), PixelColor(r: 9, g: 9, b: 9))
        XCTAssertEqual(try filled.pixel(x: 1, y: 0), .black)

        let resized = try ImageOperations.resizedNearest(source, width: 4, height: 4)
        XCTAssertEqual(resized.width, 4)
        XCTAssertEqual(resized.height, 4)
        XCTAssertEqual(try resized.pixel(x: 3, y: 0), .black)

        var model = try DocumentModel(width: 2, height: 1, background: .white)
        try model.apply(name: "one pixel") { current in
            var output = current
            try output.setPixel(x: 0, y: 0, color: .black)
            return output
        }

        XCTAssertEqual(try model.buffer.pixel(x: 0, y: 0), .black)
        XCTAssertEqual(model.undo(), "one pixel")
        XCTAssertEqual(try model.buffer.pixel(x: 0, y: 0), .white)
        XCTAssertEqual(model.redo(), "one pixel")
        XCTAssertEqual(try model.buffer.pixel(x: 0, y: 0), .black)
    }
}
