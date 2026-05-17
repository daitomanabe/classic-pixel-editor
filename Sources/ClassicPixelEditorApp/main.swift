import AppKit
import ClassicPixelCore
import UniformTypeIdentifiers

@main
final class ClassicPixelEditorApp: NSObject, NSApplicationDelegate {
    private var controllers: [EditorWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = makeMainMenu()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.controllers.isEmpty else { return }
            self.newDocument(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        openImageURLs([URL(fileURLWithPath: filename)])
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let didOpen = openImageURLs(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: didOpen ? .success : .failure)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        _ = openImageURLs(urls)
    }

    @objc func newDocument(_ sender: Any?) {
        let panel = NewDocumentPanel()
        guard let request = panel.runModal() else { return }
        do {
            let model = try DocumentModel(
                title: "Untitled",
                width: request.width,
                height: request.height,
                colorMode: request.colorMode,
                background: request.background
            )
            show(model: model, fileURL: nil)
        } catch {
            showError(error)
        }
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            _ = openImageURLs(panel.urls)
        }
    }

    @objc func saveAs(_ sender: Any?) {
        activeController()?.saveAs()
    }

    @objc func undo(_ sender: Any?) {
        activeController()?.undoEdit()
    }

    @objc func redo(_ sender: Any?) {
        activeController()?.redoEdit()
    }

    @objc func copy(_ sender: Any?) {
        activeController()?.copySelection()
    }

    @objc func paste(_ sender: Any?) {
        activeController()?.pasteImage()
    }

    @objc func invert(_ sender: Any?) {
        activeController()?.applyEdit(name: "Invert") { ImageOperations.inverted($0, selection: self.activeController()?.model.selection) }
    }

    @objc func threshold(_ sender: Any?) {
        activeController()?.applyEdit(name: "Threshold") { ImageOperations.threshold($0, cutoff: 128, selection: self.activeController()?.model.selection) }
    }

    @objc func brighten(_ sender: Any?) {
        activeController()?.applyEdit(name: "Brightness") { ImageOperations.brightnessContrast($0, brightness: 24, contrast: 0, selection: self.activeController()?.model.selection) }
    }

    @objc func desaturate(_ sender: Any?) {
        activeController()?.applyEdit(name: "Desaturate") { ImageOperations.desaturated($0, selection: self.activeController()?.model.selection) }
    }

    @objc func blur(_ sender: Any?) {
        activeController()?.applyEdit(name: "Blur") { try ImageOperations.blur3x3($0) }
    }

    @objc func sharpen(_ sender: Any?) {
        activeController()?.applyEdit(name: "Sharpen") { try ImageOperations.sharpen3x3($0) }
    }

    @objc func edgeDetect(_ sender: Any?) {
        activeController()?.applyEdit(name: "Edge Detect") { try ImageOperations.edgeDetect3x3($0) }
    }

    @objc func emboss(_ sender: Any?) {
        activeController()?.applyEdit(name: "Emboss") { try ImageOperations.emboss3x3($0) }
    }

    @objc func rotate90(_ sender: Any?) {
        activeController()?.applyEdit(name: "Rotate 90") { try ImageOperations.rotated90Clockwise($0) }
    }

    @objc func rotate180(_ sender: Any?) {
        activeController()?.applyEdit(name: "Rotate 180") { try ImageOperations.rotated180($0) }
    }

    @objc func flipHorizontal(_ sender: Any?) {
        activeController()?.applyEdit(name: "Flip Horizontal") { try ImageOperations.flippedHorizontal($0) }
    }

    @objc func flipVertical(_ sender: Any?) {
        activeController()?.applyEdit(name: "Flip Vertical") { try ImageOperations.flippedVertical($0) }
    }

    private func show(model: DocumentModel, fileURL: URL?) {
        let controller = EditorWindowController(model: model, fileURL: fileURL)
        controllers.append(controller)
        controller.onClose = { [weak self, weak controller] in
            guard let controller else { return }
            self?.controllers.removeAll { $0 === controller }
        }
        controller.showWindow(nil)
    }

    @discardableResult
    private func openImageURLs(_ urls: [URL]) -> Bool {
        var openedAny = false
        for url in urls {
            do {
                let buffer = try ImageIOBridge.load(from: url)
                show(model: DocumentModel(title: url.lastPathComponent, buffer: buffer), fileURL: url)
                openedAny = true
            } catch {
                showError(error)
            }
        }
        return openedAny
    }

    private func activeController() -> EditorWindowController? {
        NSApp.keyWindow?.windowController as? EditorWindowController ?? controllers.last
    }

    private func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    private func makeMainMenu() -> NSMenu {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Classic Pixel Editor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let fileItem = NSMenuItem()
        menu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New", action: #selector(newDocument(_:)), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Save As...", action: #selector(saveAs(_:)), keyEquivalent: "s")
        fileItem.submenu = fileMenu

        let editItem = NSMenuItem()
        menu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(undo(_:)), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(redo(_:)), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Copy", action: #selector(copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(paste(_:)), keyEquivalent: "v")
        editItem.submenu = editMenu

        let imageItem = NSMenuItem()
        menu.addItem(imageItem)
        let imageMenu = NSMenu(title: "Image")
        imageMenu.addItem(withTitle: "Invert", action: #selector(invert(_:)), keyEquivalent: "i")
        imageMenu.addItem(withTitle: "Threshold", action: #selector(threshold(_:)), keyEquivalent: "")
        imageMenu.addItem(withTitle: "Brighten", action: #selector(brighten(_:)), keyEquivalent: "")
        imageMenu.addItem(withTitle: "Desaturate", action: #selector(desaturate(_:)), keyEquivalent: "")
        imageMenu.addItem(.separator())
        imageMenu.addItem(withTitle: "Rotate 90", action: #selector(rotate90(_:)), keyEquivalent: "r")
        imageMenu.addItem(withTitle: "Rotate 180", action: #selector(rotate180(_:)), keyEquivalent: "")
        imageMenu.addItem(withTitle: "Flip Horizontal", action: #selector(flipHorizontal(_:)), keyEquivalent: "")
        imageMenu.addItem(withTitle: "Flip Vertical", action: #selector(flipVertical(_:)), keyEquivalent: "")
        imageItem.submenu = imageMenu

        let filterItem = NSMenuItem()
        menu.addItem(filterItem)
        let filterMenu = NSMenu(title: "Filters")
        filterMenu.addItem(withTitle: "Blur", action: #selector(blur(_:)), keyEquivalent: "b")
        filterMenu.addItem(withTitle: "Sharpen", action: #selector(sharpen(_:)), keyEquivalent: "")
        filterMenu.addItem(withTitle: "Edge Detect", action: #selector(edgeDetect(_:)), keyEquivalent: "")
        filterMenu.addItem(withTitle: "Emboss", action: #selector(emboss(_:)), keyEquivalent: "")
        filterItem.submenu = filterMenu
        return menu
    }
}

struct NewDocumentRequest {
    let width: Int
    let height: Int
    let colorMode: ColorMode
    let background: PixelColor
}

final class NewDocumentPanel {
    private let widthField = NSTextField(string: "640")
    private let heightField = NSTextField(string: "480")
    private let modePopup = NSPopUpButton(frame: .zero)
    private let transparentCheck = NSButton(checkboxWithTitle: "Transparent background", target: nil, action: nil)

    func runModal() -> NewDocumentRequest? {
        modePopup.addItems(withTitles: ColorMode.allCases.map(\.rawValue))
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.addArrangedSubview(labeled("Width", widthField))
        stack.addArrangedSubview(labeled("Height", heightField))
        stack.addArrangedSubview(labeled("Color mode", modePopup))
        stack.addArrangedSubview(transparentCheck)

        let alert = NSAlert()
        alert.messageText = "New Document"
        alert.accessoryView = stack
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let width = max(1, min(8192, Int(widthField.stringValue) ?? 640))
        let height = max(1, min(8192, Int(heightField.stringValue) ?? 480))
        let mode = ColorMode(rawValue: modePopup.titleOfSelectedItem ?? "") ?? .rgba
        return NewDocumentRequest(width: width, height: height, colorMode: mode, background: transparentCheck.state == .on ? .clear : .white)
    }

    private func labeled(_ title: String, _ view: NSView) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.frame.size.width = 88
        let row = NSStackView(views: [label, view])
        row.orientation = .horizontal
        row.spacing = 8
        return row
    }
}

final class EditorWindowController: NSWindowController, NSWindowDelegate {
    var model: DocumentModel
    var onClose: (() -> Void)?

    private var toolController = ToolController()
    private var activeTool: EditorTool = .pencil
    private var fileURL: URL?
    private let canvasView = CanvasView(frame: .zero)
    private let statusLabel = NSTextField(labelWithString: "")
    private let foregroundWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 44, height: 28))
    private let zoomPopup = NSPopUpButton(frame: .zero)

    init(model: DocumentModel, fileURL: URL?) {
        self.model = model
        self.fileURL = fileURL
        let window = NSWindow(
            contentRect: NSRect(x: 80, y: 80, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = model.title
        window.delegate = self
        canvasView.controller = self
        canvasView.zoom = 1.0
        foregroundWell.color = .black
        configureContent()
        refresh()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    func applyEdit(name: String, transform: (PixelBuffer) throws -> PixelBuffer) {
        do {
            try model.apply(name: name, transform: transform)
            refresh()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func undoEdit() {
        _ = model.undo()
        refresh()
    }

    func redoEdit() {
        _ = model.redo()
        refresh()
    }

    var activeToolInteractionKind: ToolInteractionKind {
        activeTool.interactionKind
    }

    func draw(at x: Int, y: Int) {
        toolController.foreground = PixelColor(nsColor: foregroundWell.color)
        do {
            switch activeTool {
            case .paintBucket:
                try model.apply(name: "Paint Bucket") { try ImageOperations.paintBucket($0, startX: x, startY: y, replacement: self.toolController.foreground, tolerance: self.toolController.tolerance) }
            case .eyedropper:
                foregroundWell.color = try toolController.eyedropper(from: model.buffer, x: x, y: y).nsColor
            case .magicWand:
                model.selection = try ImageOperations.floodSelection(in: model.buffer, startX: x, startY: y, tolerance: toolController.tolerance)
            case .pencil, .brush, .eraser:
                try model.apply(name: activeTool.rawValue) { try self.toolController.drawPoint(on: $0, x: x, y: y, tool: self.activeTool) }
            default:
                break
            }
            refresh(cursorX: x, cursorY: y)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func beginContinuousStroke(at x: Int, y: Int) {
        guard activeTool.interactionKind == .continuousDrawing else { return }
        toolController.foreground = PixelColor(nsColor: foregroundWell.color)
        let tool = activeTool
        model.beginStroke(name: tool.rawValue)
        do {
            try model.extendStroke { try self.toolController.drawPoint(on: $0, x: x, y: y, tool: tool) }
        } catch {
            model.endStroke()
            NSAlert(error: error).runModal()
        }
        refresh(cursorX: x, cursorY: y)
    }

    func extendContinuousStroke(at x: Int, y: Int) {
        guard activeTool.interactionKind == .continuousDrawing, model.isStrokeActive else { return }
        let tool = activeTool
        do {
            try model.extendStroke { try self.toolController.drawPoint(on: $0, x: x, y: y, tool: tool) }
        } catch {
            model.endStroke()
            NSAlert(error: error).runModal()
        }
        refresh(cursorX: x, cursorY: y)
    }

    func endContinuousStroke(at x: Int?, y: Int?) {
        guard model.isStrokeActive else { return }
        model.endStroke()
        refresh(cursorX: x, cursorY: y)
    }

    func finishSelection(start: NSPoint, end: NSPoint, lassoCanvasPoints: [NSPoint] = []) {
        guard activeTool.interactionKind == .dragSelection else { return }
        let s = canvasView.pixelCoordinate(from: start)
        let e = canvasView.pixelCoordinate(from: end)
        guard let s, let e else { return }
        do {
            if activeTool == .lassoSelection {
                let lassoPoints = pixelPath(from: lassoCanvasPoints)
                model.selection = lassoPoints.count >= 3
                    ? try toolController.selection(on: model.buffer, tool: activeTool, startX: s.x, startY: s.y, endX: e.x, endY: e.y, lassoPoints: lassoPoints)
                    : nil
            } else {
                model.selection = try toolController.selection(on: model.buffer, tool: activeTool, startX: s.x, startY: s.y, endX: e.x, endY: e.y)
            }
            refresh(cursorX: e.x, cursorY: e.y)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func refresh(cursorX: Int? = nil, cursorY: Int? = nil) {
        canvasView.needsDisplay = true
        canvasView.frame = NSRect(x: 0, y: 0, width: CGFloat(model.buffer.width) * canvasView.zoom, height: CGFloat(model.buffer.height) * canvasView.zoom)
        window?.title = model.title
        let cursorText: String
        if let cursorX, let cursorY, let color = try? model.buffer.pixel(x: cursorX, y: cursorY) {
            cursorText = "  cursor \(cursorX),\(cursorY)  rgba(\(color.r), \(color.g), \(color.b), \(color.a))"
        } else {
            cursorText = "  cursor -, -"
        }
        let selectionText: String
        if let selection = model.selection, selection.selectedCount > 0 {
            selectionText = "  selected \(selection.selectedCount) px"
        } else {
            selectionText = ""
        }
        statusLabel.stringValue = "tool \(toolTitle(activeTool))\(cursorText)  zoom \(Int(canvasView.zoom * 100))%  size \(model.buffer.width)x\(model.buffer.height)\(selectionText)"
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .tiff]
        panel.nameFieldStringValue = model.title.replacingOccurrences(of: "/", with: "-")
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let format: ExportFormat = url.pathExtension.lowercased().contains("tif") ? .tiff : .png
                try ImageIOBridge.save(model.buffer, to: url, format: format)
                fileURL = url
                model.title = url.lastPathComponent
                refresh()
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    func copySelection() {
        do {
            let buffer = try selectedBufferForClipboard()
            let image = try ImageIOBridge.cgImage(from: buffer)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([NSImage(cgImage: image, size: NSSize(width: buffer.width, height: buffer.height))])
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func pasteImage() {
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self])?.first as? NSImage,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        do {
            let pasted = try ImageIOBridge.pixelBuffer(from: cgImage)
            try model.apply(name: "Paste") { source in
                var output = source
                for y in 0 ..< min(source.height, pasted.height) {
                    for x in 0 ..< min(source.width, pasted.width) {
                        try output.setPixel(x: x, y: y, color: pasted.pixels[y * pasted.width + x])
                    }
                }
                return output
            }
            refresh()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func selectedBufferForClipboard() throws -> PixelBuffer {
        guard let selection = model.selection, selection.selectedCount > 0 else {
            return model.buffer
        }
        var minX = model.buffer.width
        var minY = model.buffer.height
        var maxX = 0
        var maxY = 0
        for y in 0 ..< model.buffer.height {
            for x in 0 ..< model.buffer.width where selection.isSelected(x: x, y: y) {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        var output = try ImageOperations.cropped(model.buffer, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        for y in 0 ..< output.height {
            for x in 0 ..< output.width where !selection.isSelected(x: minX + x, y: minY + y) {
                try output.setPixel(x: x, y: y, color: .clear)
            }
        }
        return output
    }

    private func pixelPath(from canvasPoints: [NSPoint]) -> [(x: Int, y: Int)] {
        var path: [(x: Int, y: Int)] = []
        for canvasPoint in canvasPoints {
            guard let point = canvasView.pixelCoordinate(from: canvasPoint) else { continue }
            if let last = path.last, last.x == point.x, last.y == point.y {
                continue
            }
            path.append(point)
        }
        return path
    }

    private func configureContent() {
        guard let window else { return }
        let sidebar = NSStackView()
        sidebar.orientation = .vertical
        sidebar.alignment = .leading
        sidebar.spacing = 8
        sidebar.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        for tool in [EditorTool.pencil, .brush, .eraser, .paintBucket, .eyedropper, .rectangularSelection, .ellipticalSelection, .lassoSelection, .magicWand] {
            let button = NSButton(title: toolTitle(tool), target: self, action: #selector(selectTool(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(tool.rawValue)
            button.setButtonType(.toggle)
            button.widthAnchor.constraint(equalToConstant: 148).isActive = true
            sidebar.addArrangedSubview(button)
        }
        sidebar.addArrangedSubview(NSTextField(labelWithString: "Color"))
        sidebar.addArrangedSubview(foregroundWell)
        zoomPopup.addItems(withTitles: ["50%", "100%", "200%", "400%"])
        zoomPopup.selectItem(withTitle: "100%")
        zoomPopup.target = self
        zoomPopup.action = #selector(changeZoom(_:))
        sidebar.addArrangedSubview(zoomPopup)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.documentView = canvasView
        scrollView.borderType = .lineBorder

        statusLabel.lineBreakMode = .byTruncatingTail
        let main = NSStackView(views: [scrollView, statusLabel])
        main.orientation = .vertical
        main.spacing = 6

        let root = NSStackView(views: [sidebar, main])
        root.orientation = .horizontal
        root.spacing = 0
        root.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = root
        NSLayoutConstraint.activate([
            sidebar.widthAnchor.constraint(equalToConstant: 180),
            root.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            root.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            root.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor)
        ])
        updateToolButtons()
    }

    @objc private func selectTool(_ sender: NSButton) {
        if let raw = sender.identifier?.rawValue, let tool = EditorTool(rawValue: raw) {
            activeTool = tool
            updateToolButtons()
            refresh()
        }
    }

    @objc private func changeZoom(_ sender: NSPopUpButton) {
        let raw = sender.titleOfSelectedItem?.replacingOccurrences(of: "%", with: "") ?? "100"
        canvasView.zoom = CGFloat(Double(raw) ?? 100) / 100.0
        refresh()
    }

    private func updateToolButtons() {
        guard let stack = (window?.contentView as? NSStackView)?.arrangedSubviews.first as? NSStackView else { return }
        for view in stack.arrangedSubviews {
            guard let button = view as? NSButton, let raw = button.identifier?.rawValue else { continue }
            button.state = raw == activeTool.rawValue ? .on : .off
        }
    }

    private func toolTitle(_ tool: EditorTool) -> String {
        switch tool {
        case .paintBucket: return "Paint Bucket"
        case .rectangularSelection: return "Rectangle Select"
        case .ellipticalSelection: return "Ellipse Select"
        case .lassoSelection: return "Lasso Select"
        case .magicWand: return "Magic Wand"
        default: return tool.rawValue.capitalized
        }
    }
}

final class CanvasView: NSView {
    weak var controller: EditorWindowController?
    var zoom: CGFloat = 1.0
    private var dragStart: NSPoint?
    private var dragPoints: [NSPoint] = []

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let controller else { return }
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
        drawCheckerboard(size: controller.model.buffer)
        if let cgImage = try? ImageIOBridge.cgImage(from: controller.model.buffer) {
            let image = NSImage(cgImage: cgImage, size: NSSize(width: controller.model.buffer.width, height: controller.model.buffer.height))
            image.draw(in: NSRect(x: 0, y: 0, width: CGFloat(controller.model.buffer.width) * zoom, height: CGFloat(controller.model.buffer.height) * zoom), from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        drawSelection(controller.model.selection)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        dragStart = location
        dragPoints = [location]
        guard let controller, let point = pixelCoordinate(from: location) else { return }
        switch controller.activeToolInteractionKind {
        case .continuousDrawing:
            controller.beginContinuousStroke(at: point.x, y: point.y)
        case .clickEditing, .clickSelection:
            controller.draw(at: point.x, y: point.y)
        case .dragSelection:
            controller.refresh(cursorX: point.x, cursorY: point.y)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let controller, let point = pixelCoordinate(from: location) else { return }
        switch controller.activeToolInteractionKind {
        case .continuousDrawing:
            controller.extendContinuousStroke(at: point.x, y: point.y)
        case .dragSelection:
            dragPoints.append(location)
            controller.refresh(cursorX: point.x, cursorY: point.y)
        case .clickEditing, .clickSelection:
            controller.refresh(cursorX: point.x, cursorY: point.y)
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard let controller, let start = dragStart else { return }
        let end = convert(event.locationInWindow, from: nil)
        dragPoints.append(end)
        let endPoint = pixelCoordinate(from: end)
        switch controller.activeToolInteractionKind {
        case .dragSelection:
            controller.finishSelection(start: start, end: end, lassoCanvasPoints: dragPoints)
        case .continuousDrawing:
            controller.endContinuousStroke(at: endPoint?.x, y: endPoint?.y)
        case .clickEditing, .clickSelection:
            if let endPoint {
                controller.refresh(cursorX: endPoint.x, cursorY: endPoint.y)
            }
        }
        dragStart = nil
        dragPoints = []
    }

    override func mouseMoved(with event: NSEvent) {
        guard let point = pixelCoordinate(from: convert(event.locationInWindow, from: nil)) else { return }
        controller?.refresh(cursorX: point.x, cursorY: point.y)
    }

    func pixelCoordinate(from point: NSPoint) -> (x: Int, y: Int)? {
        guard let buffer = controller?.model.buffer else { return nil }
        let x = Int(point.x / zoom)
        let y = Int(point.y / zoom)
        guard buffer.contains(x: x, y: y) else { return nil }
        return (x, y)
    }

    private func drawCheckerboard(size buffer: PixelBuffer) {
        let tile = max(4.0, 8.0 * zoom)
        for y in stride(from: CGFloat(0), to: CGFloat(buffer.height) * zoom, by: tile) {
            for x in stride(from: CGFloat(0), to: CGFloat(buffer.width) * zoom, by: tile) {
                (((Int(x / tile) + Int(y / tile)) % 2 == 0) ? NSColor(calibratedWhite: 0.86, alpha: 1) : NSColor(calibratedWhite: 0.72, alpha: 1)).setFill()
                NSRect(x: x, y: y, width: tile, height: tile).fill()
            }
        }
    }

    private func drawSelection(_ selection: SelectionMask?) {
        guard let selection else { return }
        NSColor.selectedControlColor.withAlphaComponent(0.28).setFill()
        for y in 0 ..< selection.height {
            for x in 0 ..< selection.width where selection.isSelected(x: x, y: y) {
                NSRect(x: CGFloat(x) * zoom, y: CGFloat(y) * zoom, width: zoom, height: zoom).fill()
            }
        }
    }
}

extension PixelColor {
    init(nsColor: NSColor) {
        let color = nsColor.usingColorSpace(.deviceRGB) ?? .black
        self.init(
            r: UInt8.clamped(Int((color.redComponent * 255).rounded())),
            g: UInt8.clamped(Int((color.greenComponent * 255).rounded())),
            b: UInt8.clamped(Int((color.blueComponent * 255).rounded())),
            a: UInt8.clamped(Int((color.alphaComponent * 255).rounded()))
        )
    }

    var nsColor: NSColor {
        NSColor(
            calibratedRed: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
