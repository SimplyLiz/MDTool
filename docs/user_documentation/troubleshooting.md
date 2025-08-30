# Troubleshooting Guide

This comprehensive troubleshooting guide helps you resolve common issues with MDTool. Issues are organized by category with step-by-step solutions and preventive measures.

## Installation and Startup Issues

### MDTool Won't Start

#### macOS Issues
**"MDTool.app is damaged and can't be opened"**
1. Remove quarantine flag:
   ```bash
   xattr -dr com.apple.quarantine /Applications/MDTool.app
   ```
2. If issue persists, redownload from official source
3. Verify download integrity with provided checksums

**Permission denied errors:**
1. Check app permissions: System Preferences → Security & Privacy → Full Disk Access
2. Add MDTool to allowed applications
3. Grant necessary file access permissions
4. Restart MDTool after granting permissions

**Crashes on startup:**
1. Check Console.app for crash logs
2. Look for MDTool-related errors
3. Try starting with a fresh preferences file:
   ```bash
   mv ~/Library/Preferences/com.mdtool.plist ~/Desktop/
   ```
4. If crash persists, reinstall MDTool

#### Windows Issues
**"Missing MSVCP140.dll" or similar DLL errors:**
1. Install Microsoft Visual C++ Redistributable:
   - Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
   - Run installer as Administrator
   - Restart computer after installation

**"App can't run on this PC" error:**
1. Verify you have 64-bit Windows 10 or 11
2. Check Windows is up to date
3. Try running as Administrator (right-click → Run as Administrator)

**Antivirus blocking MDTool:**
1. Add MDTool folder to antivirus exclusions
2. Temporary disable real-time scanning during installation
3. Submit false positive report to antivirus vendor
4. Use Windows Defender if other antivirus causes persistent issues

### File Association Problems

#### "Open with MDTool" Missing from Context Menu
**macOS:**
1. Right-click any .md file → Get Info
2. Open with → MDTool → Change All
3. If MDTool not in list:
   ```bash
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
   ```

**Windows:**
1. Run installer as Administrator to restore associations
2. Manual registry fix:
   ```cmd
   cd /path/to/MDTool/windows
   install_file_association.bat
   ```
3. Alternative: Settings → Apps → Default Apps → Choose defaults by file type

#### Wrong Application Opens Markdown Files
1. Reset file associations to system defaults
2. Reinstall MDTool with Administrator privileges  
3. Manually configure default applications in system settings
4. Check for conflicting applications in "Open With" menu

## Performance Issues

### Slow Performance and Lag

#### General Performance Problems
**Symptoms:** Slow typing, delayed preview updates, interface lag
1. **Check system resources:**
   - Activity Monitor (macOS) or Task Manager (Windows)
   - Look for high CPU or memory usage by MDTool
   - Close other resource-intensive applications

2. **Optimize MDTool settings:**
   - Preferences → Performance
   - Reduce cache sizes
   - Disable syntax highlighting for large files
   - Turn off unnecessary visual effects

3. **File-specific optimizations:**
   - Break extremely large documents into smaller files
   - Remove or optimize large embedded images
   - Simplify complex Mermaid diagrams

#### Slow Preview Rendering
**Large documents with many images:**
1. Enable lazy loading for images (Preferences → Preview)
2. Optimize image sizes before embedding
3. Use image compression tools
4. Consider using external image links instead of embedding

**Complex Mermaid diagrams:**
1. Simplify diagram complexity
2. Break complex diagrams into multiple smaller ones
3. Enable diagram caching (Preferences → Performance)
4. Consider using external diagram tools for very complex visualizations

#### Memory Usage Issues
**High memory consumption:**
1. **Reduce memory usage:**
   - Close unused documents and windows
   - Clear cache: Preferences → Performance → Clear Cache
   - Reduce undo history size
   - Limit number of recent files

2. **Monitor memory leaks:**
   - Restart MDTool periodically for long editing sessions
   - Check for memory leaks in Activity Monitor/Task Manager
   - Report persistent memory leaks with system information

### Slow File Operations

#### Slow File Loading
1. **Check file permissions:** Ensure MDTool has read access to files
2. **Antivirus scanning:** Add MDTool folder to antivirus exclusions
3. **Network drives:** Files on network drives load slower - consider local copies
4. **File corruption:** Try opening file in another text editor to verify integrity

#### Slow Auto-Save
1. **Adjust auto-save frequency:** Preferences → Files → Auto-save interval
2. **Disable during intensive editing:** Temporarily disable auto-save for large documents
3. **Check disk space:** Ensure adequate free disk space
4. **SSD vs HDD:** Consider moving working files to SSD if using traditional hard drive

## AI Integration Issues

### OpenAI API Problems

#### API Key Issues
**"Invalid API key" errors:**
1. Verify API key is correct (no extra spaces or characters)
2. Check API key permissions at https://platform.openai.com/api-keys
3. Ensure API key has sufficient quota/credits
4. Try regenerating API key if issues persist

**Rate limiting errors:**
1. Reduce requests per minute in Preferences → AI Settings
2. Consider upgrading OpenAI plan for higher rate limits
3. Use Ollama for local processing to avoid rate limits
4. Spread out AI requests over time

#### Connection Problems
**Network connectivity issues:**
1. Check internet connection
2. Verify firewall isn't blocking MDTool
3. Try different network (mobile hotspot test)
4. Check OpenAI service status at https://status.openai.com/

**Timeout errors:**
1. Increase timeout settings in AI preferences
2. Try with simpler/shorter prompts
3. Check for local network issues
4. Consider using different OpenAI model (GPT-3.5 vs GPT-4)

### Ollama Integration Issues

#### Ollama Connection Problems
**"Cannot connect to Ollama server":**
1. Verify Ollama is running:
   ```bash
   curl http://localhost:11434/api/tags
   ```
2. Check Ollama server address in preferences
3. Restart Ollama service:
   ```bash
   ollama serve
   ```
4. Verify port 11434 isn't blocked by firewall

#### Model Loading Issues
**Models not appearing or loading:**
1. List available models: `ollama list`
2. Pull required models: `ollama pull llama2`
3. Check disk space (models require several GB)
4. Verify model compatibility with your system

**Slow model responses:**
1. **Hardware optimization:**
   - Enable GPU acceleration if available
   - Increase system RAM for larger models
   - Use smaller models for better performance (7B vs 13B parameters)

2. **Configuration tweaks:**
   - Adjust context window size
   - Modify keep-alive settings
   - Optimize thread count for your CPU

## File and Document Issues

### File Access Problems

#### Permission Denied Errors
**macOS:**
1. Grant Full Disk Access:
   - System Preferences → Security & Privacy → Privacy
   - Full Disk Access → Add MDTool
2. Reset file permissions:
   ```bash
   chmod -R 755 /path/to/your/documents
   ```

**Windows:**
1. Run MDTool as Administrator
2. Check folder permissions: Right-click → Properties → Security
3. Take ownership of folder if needed
4. Disable any file synchronization software temporarily

#### Files Not Appearing in Sidebar
1. **Refresh folder view:** Right-click in sidebar → Refresh
2. **Check file extensions:** Ensure files have .md extension
3. **Hidden files:** Enable showing hidden files if files start with dot (.)
4. **File filtering:** Check if any filters are applied in preferences

#### Auto-Save Issues
**Auto-save not working:**
1. Check auto-save is enabled: Preferences → Files → Auto-save
2. Verify write permissions on file location
3. Ensure adequate disk space
4. Check if file is read-only

**Backup files accumulating:**
1. Adjust backup retention settings
2. Manually clean backup folder periodically
3. Check backup location in preferences
4. Consider automated cleanup scripts

### Content and Rendering Issues

#### Markdown Not Rendering Correctly
**Preview not updating:**
1. Toggle preview mode off and on
2. Check for markdown syntax errors
3. Restart MDTool to clear cache
4. Verify preview settings in preferences

**Syntax highlighting issues:**
1. **Check language specification in code blocks:**
   ````
   ```javascript
   // Code here
   ```
   ````
2. **Update syntax highlighting themes**
3. **Disable and re-enable syntax highlighting**

#### Mermaid Diagrams Not Displaying
**Diagrams show as code instead of rendering:**
1. Verify Mermaid is enabled: Preferences → Preview → Diagrams
2. Check diagram syntax at https://mermaid.js.org/
3. Common syntax issues:
   ```mermaid
   graph TD
       A[Start] --> B[End]  # Correct syntax
   ```
4. Clear diagram cache and refresh

**Diagram rendering errors:**
1. Simplify complex diagrams
2. Check for unsupported Mermaid features
3. Use online Mermaid editor to validate syntax
4. Update MDTool to latest version for Mermaid updates

## User Interface Issues

### Display and Layout Problems

#### Interface Elements Missing or Mispositioned
**Toolbar or sidebar disappeared:**
1. View menu → Show/Hide elements
2. Reset window layout: Window → Reset Layout
3. Check if window is too small (resize window)
4. Restart MDTool to reset interface state

**Text too small or large:**
1. Adjust zoom: View → Zoom In/Out
2. Change font sizes: Preferences → Editor/Preview → Font Size
3. Check system display scaling settings
4. Use View → Actual Size to reset zoom

#### Multi-Monitor Issues
**Windows opening on wrong monitor:**
1. Drag window to preferred monitor before closing
2. Reset window positions: Preferences → General → Reset window positions
3. Check system display arrangement in settings
4. Use Window menu to manage multi-window setups

### Keyboard and Mouse Issues

#### Keyboard Shortcuts Not Working
1. **Check for conflicts:** Preferences → Keyboard → Shortcuts
2. **Reset to defaults:** Preferences → Keyboard → Reset Shortcuts
3. **System conflicts:** Check system-wide keyboard shortcuts
4. **Accessibility features:** Disable sticky keys or similar features

#### Context Menus Not Appearing
1. Try different right-click methods (control+click on Mac)
2. Check if mouse/trackpad settings affect right-click
3. Use keyboard shortcuts as alternatives
4. Restart MDTool if context menus completely broken

## Network and Sync Issues

### Cloud Storage Sync Problems

#### Files Not Syncing Properly
**Dropbox, OneDrive, iCloud Issues:**
1. Check cloud service sync status
2. Verify MDTool isn't holding files open (preventing sync)
3. Close MDTool before major sync operations
4. Use "Save As" to force file writes

**Conflict resolution:**
1. Cloud services may create conflict copies
2. Use diff viewer to compare conflicted versions
3. Manually merge conflicts and delete conflict files
4. Consider using Git for better version control

#### Network Drive Access
**Slow performance on network drives:**
1. Copy files locally for editing
2. Increase network timeouts in preferences
3. Use wired connection instead of WiFi when possible
4. Check network drive mounting options

## Recovery and Data Protection

### Document Recovery

#### Recovering Lost Work
**Auto-save recovery:**
1. Check auto-save backup location (shown in preferences)
2. Look for .backup files in document folder
3. Recovery files may have timestamps in names
4. Use most recent backup that contains your work

**System crash recovery:**
1. Restart MDTool - it should offer to recover unsaved documents
2. Check system temp folder for recovery files:
   - macOS: `~/Library/Caches/MDTool/`
   - Windows: `%LOCALAPPDATA%/MDTool/Cache/`
3. Look for files with recent timestamps

#### Version History
**Comparing document versions:**
1. Use built-in diff viewer: Tools → Compare Documents
2. Compare with backup files
3. Use external diff tools if needed
4. Consider implementing Git version control

### Preventing Data Loss

#### Best Practices
1. **Enable auto-save** with reasonable intervals
2. **Use version control** (Git) for important documents
3. **Regular backups** to multiple locations
4. **Cloud synchronization** for redundancy
5. **Export important documents** to PDF regularly

## Getting Additional Help

### Diagnostic Information

#### Collecting System Information
When reporting issues, include:
1. **MDTool version:** Help → About MDTool
2. **Operating system:** Version and build number
3. **System specs:** RAM, CPU, available disk space
4. **Error messages:** Exact text of any error messages
5. **Reproduction steps:** How to reproduce the issue

#### Log Files
**Accessing log files:**
- **macOS:** `~/Library/Logs/MDTool/`
- **Windows:** `%LOCALAPPDATA%/MDTool/Logs/`

**Enable debug logging:**
1. Preferences → Advanced → Debug Mode
2. Reproduce the issue
3. Include relevant log entries when reporting issues

### Reporting Issues

#### Before Reporting
1. **Search existing issues** in documentation or support forums
2. **Try basic troubleshooting** steps listed above
3. **Update to latest version** - issue may already be fixed
4. **Test with minimal configuration** - disable extensions/customizations

#### When Reporting Issues
Include the following information:
- **Clear problem description**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **System information**
- **Log files or error messages**
- **Screenshots or recordings** if relevant

### Community Resources

#### Documentation and Support
- **User documentation:** Complete guides for all features
- **FAQ section:** Common questions and answers
- **Video tutorials:** Visual guides for complex features
- **Community forums:** User discussions and tips

#### Alternative Solutions
If MDTool doesn't meet your needs:
1. **Export your work** to standard Markdown format
2. **Backup preferences and settings**
3. **Consider other Markdown editors** with similar features
4. **Use MDTool alongside other tools** for specific needs

## Prevention and Maintenance

### Regular Maintenance
1. **Update regularly:** Keep MDTool updated to latest version
2. **Clean up periodically:** Clear caches, organize files, remove unused documents
3. **Monitor performance:** Check system resources and optimize settings
4. **Backup preferences:** Export settings before major changes

### System Optimization
1. **Keep OS updated:** Latest system updates often fix compatibility issues
2. **Manage disk space:** Ensure adequate free space for optimal performance
3. **Regular restarts:** Restart computer and MDTool periodically
4. **Monitor other applications:** Identify conflicts with other software

By following this troubleshooting guide, you should be able to resolve most common issues with MDTool. For problems not covered here, consider reaching out to the community or support channels with detailed information about your specific issue.