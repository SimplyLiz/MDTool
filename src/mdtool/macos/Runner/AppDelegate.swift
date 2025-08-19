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
  
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      // If no windows are visible, create a new one
      createNewWindow()
    }
    return true
  }
  
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    // Only handle file opening if app is in /Applications
    guard isAppInApplicationsFolder() else {
      let alert = NSAlert()
      alert.messageText = "MDTool Location Required"
      alert.informativeText = "To use \"Open with MDTool\", please move MDTool to your Applications folder."
      alert.addButton(withTitle: "OK")
      alert.runModal()
      return false
    }
    
    // Handle file opening from Finder
    if let window = NSApplication.shared.mainWindow,
       let flutterViewController = window.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "open_file_channel",
        binaryMessenger: flutterViewController.engine.binaryMessenger
      )
      channel.invokeMethod("openFile", arguments: filename)
      return true
    } else {
      // Store the file path to open after the app fully launches
      pendingFileToOpen = filename
      return true
    }
  }
  
  private func isAppInApplicationsFolder() -> Bool {
    let bundlePath = Bundle.main.bundlePath
    return bundlePath.hasPrefix("/Applications/")
  }
  
  private var pendingFileToOpen: String?
  
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