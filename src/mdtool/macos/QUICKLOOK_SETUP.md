# Quick Look Preview Extension Setup

I've created the necessary files for the Quick Look Preview Extension. To complete the integration, follow these steps in Xcode:

## Files Created:
- `MarkdownQLPreview/Info.plist` - Extension configuration
- `MarkdownQLPreview/PreviewProvider.swift` - Swift implementation
- `MarkdownQLPreview/Podfile` - Dependencies (optional)

## Manual Xcode Integration Steps:

### 1. Open Xcode Project
```bash
cd macos
open Runner.xcworkspace
```

### 2. Add New Target in Xcode
1. Select the Runner project in the navigator
2. Click the "+" button at the bottom of the target list
3. Choose "macOS" → "Quick Look Preview Extension"
4. Set the target name to: `MarkdownQLPreview`
5. Set the Bundle Identifier to: `com.example.mdtool.MarkdownQLPreview`
6. Click "Finish"

### 3. Replace Generated Files
1. Delete the auto-generated `PreviewProvider.swift` in the new target
2. Drag the `MarkdownQLPreview/PreviewProvider.swift` file into the target
3. Replace the auto-generated `Info.plist` with `MarkdownQLPreview/Info.plist`

### 4. Configure Target Settings
1. Select the `MarkdownQLPreview` target
2. In "Build Settings":
   - Set "Deployment Target" to macOS 10.15 or later
   - Ensure "Swift Language Version" is set to Swift 5.0

### 5. Add Extension to Main App
1. Select the main "Runner" target
2. Go to "Build Phases" → "Embed App Extensions"
3. Click "+" and add `MarkdownQLPreview.appex`
4. Ensure it's set to "Embed & Sign"

### 6. Build and Test
1. Build the project (Cmd+B)
2. Run the app (Cmd+R) to install it
3. Create a test .md file
4. In Finder, select the .md file and press Space to preview

## Alternative: Manual Target Configuration

If you prefer to configure manually without using Xcode's target template:

1. Add the following to your `project.pbxproj` file (or use Xcode GUI):
   - New target of type `com.apple.product-type.app-extension`
   - Product name: `MarkdownQLPreview`
   - Bundle identifier: `com.example.mdtool.MarkdownQLPreview`

2. Set the extension's Info.plist with the configuration I've provided

3. Add the Swift source file to the target

## Troubleshooting

Here are the most common reasons a Quick Look preview extension won't kick in — and how to verify/fix each one:

### 1. You built an "App Extension" (.appex), not a Quick Look generator (.qlgenerator)
- A Quick Look Preview Extension target in Xcode produces an .appex inside your app bundle (at YourApp.app/Contents/PlugIns/MarkdownQLPreview.appex), not a standalone .qlgenerator.
- If you copy that .appex into ~/Library/QuickLook, Finder won't recognize it. Either:
  - Embed it in your main app (Embed App Extensions build phase) and install the .app to /Applications, or
  - Change your target type to "Quick Look Generator" so Xcode outputs a .qlgenerator, then copy that into ~/Library/QuickLook.

### 2. You haven't (re)registered the extension with the system
After installing (either by dropping your .app in /Applications or copying the .qlgenerator), run in Terminal:

```bash
qlmanage -r
qlmanage -r cache
```

This forces Quick Look to reload all plugins.

### 3. The extension isn't activated in System Settings
Go to System Settings → Extensions → Quick Look and make sure "MarkdownQLPreview" is checked.

### 4. Your Info.plist UTI or keys are off
Under your extension target's Info.plist → NSExtension → NSExtensionAttributes:

```xml
<key>QLSupportedContentTypes</key>
<array>
  <string>public.markdown</string>
  <string>net.daringfireball.markdown</string>
</array>
<key>QLIsDataBasedPreview</key>
<true/>
```

If you misspell QLSupportedContentTypes or omit QLIsDataBasedPreview, Quick Look will skip your plugin.

### 5. Your Swift implementation is using the wrong API signature
- On macOS 12+ you should implement the async API:

```swift
func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply
```

- If you mix that with the old callback-based initializer (QLPreviewReply(html:baseURL:)), the runtime won't tie your class to the extension point.
Double-check that your PreviewProvider.swift matches Apple's docs exactly.

### 6. Debugging with qlmanage
Run:

```bash
qlmanage -d 4 -p /path/to/file.md
```

The -d 4 flag prints verbose debug info about why your extension was (or wasn't) loaded.

### Quick Fix Steps:
1. Verify you actually have a .appex vs. .qlgenerator and install it in the correct place.
2. Reload Quick Look: `qlmanage -r && qlmanage -r cache`
3. Check in System Settings → Extensions that your plugin is enabled.
4. If it still won't appear, use the `qlmanage -d 4 -p` command to see loader errors.

### Legacy Troubleshooting:
- **Extension not appearing**: Make sure the bundle identifier is unique and properly configured
- **Preview not working**: Check the `QLSupportedContentTypes` in Info.plist includes `public.markdown`
- **Build errors**: Ensure the deployment target is macOS 10.15 or later

## Testing

After setup, you should be able to:
1. Build and run the project in Xcode
2. Install the app to /Applications (or run from Xcode)
3. Register the extension: `qlmanage -r && qlmanage -r cache`
4. Check System Settings → Extensions → Quick Look to ensure "MarkdownQLPreview" is enabled
5. Select any .md file in Finder
6. Press Space bar for Quick Look preview
7. See the markdown rendered as HTML with proper styling

### Build and Test Steps:

1. **Open the project:**
   ```bash
   cd src/md_tool/macos
   open Runner.xcworkspace
   ```

2. **Build the project:**
   - Select the Runner scheme
   - Build (⌘+B) to ensure everything compiles
   - Run (⌘+R) to install the app

3. **Register the extension:**
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```

4. **Enable in System Settings:**
   - Go to System Settings → Extensions → Quick Look
   - Ensure "MarkdownQLPreview" is checked

5. **Test with sample file:**
   ```bash
   # Test the provided sample file
   open -R test_quicklook_preview.md
   # Then press Space while the file is selected in Finder
   ```

6. **Debug if needed:**
   ```bash
   qlmanage -d 4 -p test_quicklook_preview.md
   ```

The extension now supports:
- Headers (H1-H6)
- Bold and italic text
- Inline code and code blocks
- Links
- Unordered and ordered lists
- Tables with headers
- Blockquotes
- Proper paragraph formatting