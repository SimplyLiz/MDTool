import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    // Process any pending file that was requested before the app finished launching
    if let pendingFile = pendingFileToOpen {
      // Give Flutter a moment to fully initialize
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.openPendingFile(pendingFile)
        self?.pendingFileToOpen = nil
      }
    }
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      // If no windows are visible, create a new one
      createNewWindow()
    }
    return true
  }
  
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    print("DEBUG AppDelegate: openFile called with: \(filename)")

    // Only handle file opening if app is in /Applications
    guard isAppInApplicationsFolder() else {
      let alert = NSAlert()
      alert.messageText = "MDTool Location Required"
      alert.informativeText = "To use \"Open with MDTool\", please move MDTool to your Applications folder."
      alert.addButton(withTitle: "OK")
      alert.runModal()
      return false
    }

    // Try to find Flutter view controller from any window
    if let flutterVC = findFlutterViewController() {
      print("DEBUG AppDelegate: Found Flutter VC, sending openFile")
      let channel = FlutterMethodChannel(
        name: "open_file_channel",
        binaryMessenger: flutterVC.engine.binaryMessenger
      )
      channel.invokeMethod("openFile", arguments: filename)
      return true
    } else {
      // Store the file path to open after the app fully launches
      print("DEBUG AppDelegate: No Flutter VC found, queuing file: \(filename)")
      pendingFileToOpen = filename
      return true
    }
  }

  // Handle multiple files
  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    print("DEBUG AppDelegate: openFiles called with \(filenames.count) files")
    if let firstFile = filenames.first {
      _ = application(sender, openFile: firstFile)
    }
  }

  // Handle URL schemes (file:// URLs from terminal)
  override func application(_ application: NSApplication, open urls: [URL]) {
    print("DEBUG AppDelegate: open urls called with \(urls.count) URLs")
    for url in urls {
      print("DEBUG AppDelegate: URL = \(url)")
      if url.isFileURL {
        _ = self.application(application, openFile: url.path)
        break
      }
    }
  }

  /// Find Flutter view controller from any window (more reliable than mainWindow)
  private func findFlutterViewController() -> FlutterViewController? {
    // First try mainWindow
    if let window = NSApplication.shared.mainWindow,
       let flutterVC = window.contentViewController as? FlutterViewController {
      return flutterVC
    }

    // Then try keyWindow
    if let window = NSApplication.shared.keyWindow,
       let flutterVC = window.contentViewController as? FlutterViewController {
      return flutterVC
    }

    // Finally search all windows
    for window in NSApplication.shared.windows {
      if let flutterVC = window.contentViewController as? FlutterViewController {
        return flutterVC
      }
    }

    return nil
  }
  
  private func isAppInApplicationsFolder() -> Bool {
    let bundlePath = Bundle.main.bundlePath
    return bundlePath.hasPrefix("/Applications/")
  }

  private var pendingFileToOpen: String?

  private func openPendingFile(_ filename: String) {
    print("DEBUG AppDelegate: Opening pending file: \(filename)")
    if let flutterVC = findFlutterViewController() {
      let channel = FlutterMethodChannel(
        name: "open_file_channel",
        binaryMessenger: flutterVC.engine.binaryMessenger
      )
      channel.invokeMethod("openFile", arguments: filename)
      print("DEBUG AppDelegate: Sent openFile to Flutter")
    } else {
      print("DEBUG AppDelegate: Could not find Flutter view controller")
    }
  }
  
  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let dockMenu = NSMenu()
    
    let newWindowItem = NSMenuItem(
      title: "New Window",
      action: #selector(createNewWindow),
      keyEquivalent: ""
    )
    newWindowItem.target = self
    dockMenu.addItem(newWindowItem)
    
    return dockMenu
  }
  
  @objc private func createNewWindow() {
    // Create a new Flutter window
    let newWindow = MainFlutterWindow()
    
    // Set up window properties
    newWindow.center()
    newWindow.title = "MDTool"
    newWindow.makeKeyAndOrderFront(self)
    
    // Set up window delegate for cleanup
    newWindow.delegate = self
    
    // Ensure the window is retained
    windows.append(newWindow)
    
    // If there's a pending file to open, handle it now
    if let pendingFile = pendingFileToOpen {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let flutterViewController = newWindow.contentViewController as? FlutterViewController {
          let channel = FlutterMethodChannel(
            name: "open_file_channel",
            binaryMessenger: flutterViewController.engine.binaryMessenger
          )
          channel.invokeMethod("openFile", arguments: pendingFile)
        }
      }
      pendingFileToOpen = nil
    }
  }
  
  // Keep track of windows to prevent deallocation
  private var windows: [MainFlutterWindow] = []
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    if let window = notification.object as? MainFlutterWindow {
      // Remove the window from our tracking array
      windows.removeAll { $0 === window }
    }
  }
}