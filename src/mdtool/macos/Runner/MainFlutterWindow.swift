import Cocoa
import FlutterMacOS
import QuickLookUI

class MainFlutterWindow: NSWindow {
  private var previewItemURL: URL?
  private var flutterEngine: FlutterEngine?
  
  override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
    super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    setupFlutterContent()
  }
  
  convenience init() {
    let contentRect = NSRect(x: 100, y: 100, width: 1200, height: 800)
    self.init(contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: true)
  }
  
  override func awakeFromNib() {
    setupFlutterContent()
    super.awakeFromNib()
  }
  
  deinit {
    // Flutter engines are automatically cleaned up
  }
  
  private func setupFlutterContent() {
    // Create a new Flutter engine for this window
    flutterEngine = FlutterEngine(name: "window-\(UUID().uuidString)", project: nil)
    _ = flutterEngine?.run(withEntrypoint: nil)
    
    guard let engine = flutterEngine else { return }
    
    let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Setup custom method channels
    setupMethodChannels(flutterViewController: flutterViewController)
    
    // Setup simple folder picker channel
    setupSimpleFolderPicker(flutterViewController: flutterViewController)
  }
  
  private func setupMethodChannels(flutterViewController: FlutterViewController) {
    // QuickLook channel
    let quickLookChannel = FlutterMethodChannel(
      name: "quicklook_channel",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    quickLookChannel.setMethodCallHandler { [weak self] call, result in
      if call.method == "showQuickLook",
         let args = call.arguments as? [String: Any],
         let path = args["filePath"] as? String {
        print("🔍 QuickLook called with path: \(path)")
        let fileExists = FileManager.default.fileExists(atPath: path)
        print("🔍 File exists: \(fileExists)")
        guard fileExists else {
          result(false); return
        }

        self?.previewItemURL = URL(fileURLWithPath: path)

        NSApp.activate(ignoringOtherApps: true)
        let panel = QLPreviewPanel.shared()
        panel?.updateController()
        panel?.makeKeyAndOrderFront(self)

        print("🔍 QLPanel is visible: \(panel?.isVisible ?? false)")
        print("🔍 QLPanel controller: \(panel?.currentController ?? "nil")")
        print("🔍 mainWindow: \(NSApp.mainWindow?.description ?? "nil")")
        print("🔍 keyWindow: \(NSApp.keyWindow?.description ?? "nil")")

        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Directory permissions channel
    let directoryPermissionsChannel = FlutterMethodChannel(
      name: "md_tool/directory_permissions",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    directoryPermissionsChannel.setMethodCallHandler { [weak self] call, result in
      print("🔧 Method channel received call: \(call.method)")
      print("🔧 Arguments: \(call.arguments ?? "nil")")
      
      switch call.method {
      case "pickDirectories":
        print("🔧 Handling pickDirectories")
        self?.handleDirectoryPermissionsCall(call, result: result)
      case "resolveBookmarks":
        print("🔧 Handling resolveBookmarks")
        self?.handleResolveBookmarks(call, result: result)
      case "startAccessingDirectory":
        print("🔧 Handling startAccessingDirectory")
        self?.handleStartAccessingDirectory(call, result: result)
      default:
        print("🔧 Method not implemented: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func setupSimpleFolderPicker(flutterViewController: FlutterViewController) {
    // Simple, reliable folder picker method channel
    let simpleFolderChannel = FlutterMethodChannel(
      name: "simple_folder_picker",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    
    simpleFolderChannel.setMethodCallHandler { [weak self] call, result in
      print("🟢 Simple folder picker called: \(call.method)")
      
      if call.method == "pickFolder" {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.title = "Choose a folder"
        
        print("🟢 Showing NSOpenPanel...")
        NSApp.activate(ignoringOtherApps: true)
        
        // Force the panel to appear in front
        panel.level = NSWindow.Level.modalPanel
        panel.orderFrontRegardless()
        
        let response = panel.runModal()
        print("🟢 NSOpenPanel response: \(response.rawValue)")
        
        if response == .OK {
          let path = panel.url?.path
          print("🟢 User selected: \(path ?? "nil")")
          result(path)
        } else {
          print("🟢 User cancelled")
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  // MARK: - Directory permissions

  /// Opens an NSOpenPanel to select one or multiple directories and returns
  /// an array of { path: String, bookmark: String(Base64) } to Flutter.
  func handleDirectoryPermissionsCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("🔧 handleDirectoryPermissionsCall started")
    
    let args = call.arguments as? [String: Any]
    let allowsMultiple = (args?["multiple"] as? Bool) ?? false
    print("🔧 allowsMultiple: \(allowsMultiple)")

    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = allowsMultiple
    panel.prompt = "Grant Access"

    print("🔧 About to show NSOpenPanel")
    NSApp.activate(ignoringOtherApps: true)
    
    // Force the panel to appear in front of everything
    panel.level = NSWindow.Level.modalPanel
    panel.orderFrontRegardless()
    
    // Use synchronous runModal instead of async begin
    print("🔧 Using synchronous runModal approach")
    
    let response = panel.runModal()
    print("🔧 NSOpenPanel runModal response: \(response.rawValue)")
    
    guard response == .OK else {
      print("🔧 User cancelled or dialog failed to show")
      result(nil)
      return
    }
    
    print("🔧 User selected \(panel.urls.count) directories")
    var out: [[String: Any]] = []
    
    for url in panel.urls {
      print("🔧 Processing URL: \(url.path)")
      do {
        let bookmark = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        out.append([
          "path": url.path,
          "bookmark": bookmark.base64EncodedString()
        ])
        print("🔧 Successfully created bookmark for: \(url.path)")
      } catch {
        print("🔧 Bookmark error for \(url.path): \(error)")
        result(FlutterError(code: "BOOKMARK_ERROR", message: error.localizedDescription, details: nil))
        return
      }
    }
    
    print("🔧 Returning \(out.count) directories to Flutter")
    result(["directories": out])
  }

  /// Resolves previously saved Base64 security-scoped bookmarks and (re)starts access.
  /// Args: [ String(Base64Bookmark), ... ]
  /// Returns: [{ path, bookmark (possibly refreshed), stale: Bool }, ...]
  func handleResolveBookmarks(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arr = call.arguments as? [String] else {
      result(FlutterError(code: "ARG_ERROR", message: "Expected [String] of base64 bookmarks", details: nil))
      return
    }

    var out: [[String: Any]] = []

    for b64 in arr {
      guard let data = Data(base64Encoded: b64) else { continue }
      var stale = false
      do {
        let url = try URL(
          resolvingBookmarkData: data,
          options: [.withSecurityScope],
          relativeTo: nil,
          bookmarkDataIsStale: &stale
        )
        _ = url.startAccessingSecurityScopedResource()
        // Refresh if stale
        let refreshed = try url.bookmarkData(options: [.withSecurityScope],
                                             includingResourceValuesForKeys: nil,
                                             relativeTo: nil)
        out.append([
          "path": url.path,
          "bookmark": refreshed.base64EncodedString(),
          "stale": stale
        ])
      } catch {
        // Skip broken bookmarks and continue
      }
    }

    result(out)
  }
  
  /// Start accessing a security-scoped resource using a bookmark
  func handleStartAccessingDirectory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("🔧 handleStartAccessingDirectory started")
    
    guard let args = call.arguments as? [String: Any],
          let bookmarkString = args["bookmark"] as? String,
          let bookmarkData = Data(base64Encoded: bookmarkString) else {
      result(FlutterError(code: "ARG_ERROR", message: "Expected bookmark string", details: nil))
      return
    }
    
    do {
      var stale = false
      let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
      
      let success = url.startAccessingSecurityScopedResource()
      print("🔧 startAccessingSecurityScopedResource result: \(success)")
      result(success)
    } catch {
      print("🔧 Error starting access to directory: \(error)")
      result(FlutterError(code: "BOOKMARK_ERROR", message: error.localizedDescription, details: nil))
    }
  }
}

// MARK: - QLPreviewPanelDataSource & Delegate
extension MainFlutterWindow: QLPreviewPanelDataSource, QLPreviewPanelDelegate {
  func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
    return previewItemURL != nil ? 1 : 0
  }

  func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
    return previewItemURL as NSURL?
  }

  override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
    print("🔍 acceptsPreviewPanelControl called - returning true")
    return true
  }

  override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
    print("🔍 beginPreviewPanelControl called")
    panel.delegate = self
    panel.dataSource = self
  }

  override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
    print("🔍 endPreviewPanelControl called")
    panel.delegate = nil
    panel.dataSource = nil
  }
}
