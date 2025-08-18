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
    newWindow.title = "MD Tool"
    newWindow.makeKeyAndOrderFront(self)
    
    // Set up window delegate for cleanup
    newWindow.delegate = self
    
    // Ensure the window is retained
    windows.append(newWindow)
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