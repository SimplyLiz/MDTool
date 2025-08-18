import 'dart:io';

class PlatformInstall {
  /// Get the appropriate Homebrew install command for macOS
  static String? brewCommand() {
    return Platform.isMacOS ? 'brew install ollama && ollama serve' : null;
  }

  /// Get the Linux curl install command
  static String? linuxCommand() {
    return Platform.isLinux ? 'curl -fsSL https://ollama.com/install.sh | sh' : null;
  }

  /// Get the Windows winget install command
  static String? wingetCommand() {
    return Platform.isWindows ? 'winget install Ollama.Ollama' : null;
  }

  /// Get the official Ollama download URL
  static String downloadUrl() => 'https://ollama.com';

  /// Get platform-specific installation instructions
  static String getInstallInstructions() {
    if (Platform.isMacOS) {
      return '''
macOS Installation Options:

1. Download from website:
   • Visit https://ollama.com
   • Download the macOS installer
   • Double-click to install

2. Using Homebrew:
   • Run: brew install ollama
   • Start with: ollama serve

3. After installation:
   • Open Terminal
   • Run: ollama serve
   • Keep Terminal open while using Ollama
      ''';
    } else if (Platform.isWindows) {
      return '''
Windows Installation Options:

1. Download from website:
   • Visit https://ollama.com
   • Download the Windows installer
   • Run the installer as Administrator

2. Using winget:
   • Open PowerShell as Administrator
   • Run: winget install Ollama.Ollama

3. After installation:
   • Ollama should start automatically
   • Check system tray for Ollama icon
      ''';
    } else if (Platform.isLinux) {
      return '''
Linux Installation:

1. Using curl (recommended):
   • Open terminal
   • Run: curl -fsSL https://ollama.com/install.sh | sh

2. After installation:
   • Start with: ollama serve
   • Keep terminal open while using Ollama

3. To run as service (optional):
   • Create systemd service for automatic startup
      ''';
    } else {
      return '''
Installation:

Please visit https://ollama.com to download the appropriate installer for your platform.

After installation:
1. Start the Ollama service
2. Return to this screen and test the connection
      ''';
    }
  }

  /// Get quick start instructions after installation
  static String getQuickStartInstructions() {
    return '''
After Installing Ollama:

1. Start the Ollama service:
   • macOS/Linux: Run 'ollama serve' in Terminal
   • Windows: Should start automatically

2. Download a model:
   • Run: ollama pull llama2
   • Or: ollama pull codellama
   • Or: ollama pull mistral

3. Test it works:
   • Run: ollama run llama2
   • Type a test message
   • Press Ctrl+D to exit

4. Return to this screen and test the connection
    ''';
  }

  /// Get list of popular models with descriptions
  static List<ModelInfo> getPopularModels() {
    return [
      ModelInfo(
        name: 'llama2',
        description: 'Meta\'s Llama 2 model, good for general conversation',
        size: '3.8GB',
        pullCommand: 'ollama pull llama2',
      ),
      ModelInfo(
        name: 'codellama',
        description: 'Specialized for code generation and assistance',
        size: '3.8GB',
        pullCommand: 'ollama pull codellama',
      ),
      ModelInfo(
        name: 'mistral',
        description: 'Fast and efficient model for various tasks',
        size: '4.1GB',
        pullCommand: 'ollama pull mistral',
      ),
      ModelInfo(
        name: 'llama2:13b',
        description: 'Larger version of Llama 2 with better quality',
        size: '7.3GB',
        pullCommand: 'ollama pull llama2:13b',
      ),
      ModelInfo(
        name: 'neural-chat',
        description: 'Optimized for chat and conversation',
        size: '4.1GB',
        pullCommand: 'ollama pull neural-chat',
      ),
    ];
  }

  /// Check if we're running on a platform where Ollama can be installed locally
  static bool canInstallLocally() {
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  /// Get platform name for display
  static String getPlatformName() {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

class ModelInfo {
  final String name;
  final String description;
  final String size;
  final String pullCommand;

  const ModelInfo({
    required this.name,
    required this.description,
    required this.size,
    required this.pullCommand,
  });
}