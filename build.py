#!/usr/bin/env python3
"""
MDTool Build Manager - Enhanced TUI for Flutter project management
"""

import os
import sys
import subprocess
import time
import json
import threading
import select
import re
import queue
from pathlib import Path
from typing import Optional, Dict, List, Tuple, Any
from datetime import datetime
from collections import deque
from time import monotonic as _mono

# readchar handles cross-platform keyboard input

try:
    import readchar
except ImportError:
    print("Error: readchar library not found. Install with: pip install readchar")
    sys.exit(1)

try:
    from rich.console import Console, Group
    from rich.panel import Panel
    from rich.text import Text
    from rich.live import Live
    from rich.layout import Layout
    from rich.table import Table
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn, TimeRemainingColumn
    from rich.align import Align
    from rich.columns import Columns
    from rich.syntax import Syntax
    from rich.rule import Rule
    from rich.tree import Tree
    from rich.style import Style
    from rich.box import ROUNDED, DOUBLE, MINIMAL, SIMPLE
except ImportError:
    print("Error: rich library not found. Install with: pip install rich")
    sys.exit(1)

class BuildHistory:
    """Manages build history and statistics"""
    def __init__(self, history_file: Path):
        self.history_file = history_file
        self.history: List[Dict] = []
        self.load_history()
    
    def load_history(self):
        """Load history from file"""
        if self.history_file.exists():
            try:
                with open(self.history_file, 'r') as f:
                    self.history = json.load(f)
            except:
                self.history = []
    
    def save_history(self):
        """Save history to file"""
        try:
            with open(self.history_file, 'w') as f:
                json.dump(self.history[-50:], f, indent=2)  # Keep last 50 entries
        except:
            pass
    
    def add_entry(self, action: str, success: bool, duration: float, details: str = ""):
        """Add a new history entry"""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "action": action,
            "success": success,
            "duration": duration,
            "details": details
        }
        self.history.append(entry)
        self.save_history()
    
    def get_stats(self) -> Dict:
        """Get statistics from history"""
        if not self.history:
            return {
                "total_builds": 0,
                "successful_builds": 0,
                "failed_builds": 0,
                "avg_duration": 0,
                "success_rate": 0
            }
        
        builds = [h for h in self.history if h['action'] == 'build']
        successful = [b for b in builds if b['success']]
        
        return {
            "total_builds": len(builds),
            "successful_builds": len(successful),
            "failed_builds": len(builds) - len(successful),
            "avg_duration": sum(b['duration'] for b in builds) / len(builds) if builds else 0,
            "success_rate": (len(successful) / len(builds) * 100) if builds else 0
        }

class LiveLogViewer:
    """Manages live log viewing with scrolling"""
    def __init__(self, max_lines: int = 100):
        self.logs = deque(maxlen=max_lines)
        self.lock = threading.Lock()
    
    def add_log(self, text: str, style: str = ""):
        """Add a log entry"""
        with self.lock:
            timestamp = datetime.now().strftime("%H:%M:%S")
            self.logs.append((timestamp, text, style))
    
    def get_logs(self, last_n: int = 20) -> List[Tuple[str, str, str]]:
        """Get the last n log entries"""
        with self.lock:
            return list(self.logs)[-last_n:]

class Settings:
    """Manages application settings"""
    def __init__(self, settings_file: Path):
        self.settings_file = settings_file
        self.settings = self.load_settings()
    
    def load_settings(self) -> Dict:
        """Load settings from file"""
        defaults = {
            "theme": "default",
            "auto_clean_before_build": False,
            "show_notifications": True,
            "parallel_builds": False,
            "verbose_output": False,
            "auto_deploy": False,
            "max_log_lines": 100,
            "animation_speed": "normal",
            "use_emoji": True
        }
        
        if self.settings_file.exists():
            try:
                with open(self.settings_file, 'r') as f:
                    loaded = json.load(f)
                    defaults.update(loaded)
            except:
                pass
        
        return defaults
    
    def save_settings(self):
        """Save settings to file"""
        try:
            with open(self.settings_file, 'w') as f:
                json.dump(self.settings, f, indent=2)
        except:
            pass
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get a setting value"""
        return self.settings.get(key, default)
    
    def set(self, key: str, value: Any):
        """Set a setting value"""
        self.settings[key] = value
        self.save_settings()

class FlutterBuildManager:
    def __init__(self):
        self.console = Console()
        self.project_root = Path(__file__).parent
        self.flutter_project = self.project_root / "src" / "mdtool"
        self.build_dir = self.project_root / "build"
        self.data_dir = self.project_root / ".build_manager"
        
        # Create directories
        self.build_dir.mkdir(exist_ok=True)
        self.data_dir.mkdir(exist_ok=True)
        
        # Initialize components
        self.settings = Settings(self.data_dir / "settings.json")
        self.history = BuildHistory(self.data_dir / "history.json")
        self.log_viewer = LiveLogViewer(self.settings.get("max_log_lines", 100))
        
        # System cache to avoid heavy calls every frame
        self._sys_cache = {"flutter_ok": (False, 0.0)}  # (value, timestamp)
        
        # UI state
        self.selected_option = 0
        self.current_view = "main"  # main, dashboard, logs, settings, help
        self.animation_frame = 0
        self.animation_running = True
        
        # Menu structure
        self.menu_options = [
            ("1", "🔨 Build macOS (Release)", self.build_macos_release, "build"),
            ("2", "🚀 Run (Debug)", self.run_debug, "run"),
            ("3", "🧪 Run Tests", self.run_tests, "test"),
            ("4", "📋 View Test Results", self.view_test_results, "view"),
            ("5", "🚚 Deploy to /Applications", self.deploy_to_applications, "deploy"),
            ("6", "🧹 Clean", self.clean_project, "clean"),
            ("7", "📦 Pub Get (Dependencies)", self.pub_get, "deps"),
            ("8", "🔍 Analyze", self.analyze_code, "analyze"),
            ("9", "📊 Dashboard", self.show_dashboard, "dashboard"),
            ("0", "⚙️  Settings", self.show_settings, "settings"),
            ("l", "📜 View Logs", self.show_logs, "logs"),
            ("h", "❓ Help", self.show_help, "help"),
            ("q", "❌ Quit", None, "quit")
        ]
        
        # Quick actions (keyboard shortcuts)
        self.shortcuts = {
            'b': ('build', self.build_macos_release),
            'r': ('run', self.run_debug),
            't': ('test', self.run_tests),
            'c': ('clean', self.clean_project),
            'd': ('dashboard', self.show_dashboard),
            's': ('settings', self.show_settings),
            '?': ('help', self.show_help),
            '/': ('search', self.search_commands)
        }
        
        # Start animation thread
        self.start_animation_thread()
        
        # Start key reader thread
        self._keyq = queue.Queue()
        threading.Thread(target=self._key_reader, daemon=True).start()
    
    def _layout_mode(self) -> str:
        """Determine layout mode based on terminal width"""
        w = self.console.size.width
        # tune thresholds to your taste
        if w >= 120: return "triple"
        if w >= 90:  return "double"
        return "single"

    def _log_lines_for_height(self) -> int:
        """Calculate log lines based on terminal height"""
        h = self.console.size.height
        # leave headroom for header/footer; allocate ~1/4 to logs
        return max(5, min(20, h // 4))
    
    def create_layout(self) -> Layout:
        """Create adaptive layout based on terminal size"""
        mode = self._layout_mode()
        width, height = self.console.size

        # Header / Body / Footer
        layout = Layout(name="root")
        header_size = 5 if mode != "single" else 4
        footer_size = 2
        layout.split_column(
            Layout(self.create_header(), name="header", size=header_size),
            Layout(name="body", ratio=1),
            Layout(self._controls_line(), name="footer", size=footer_size)
        )

        # Body: top content + logs
        logs_lines = self._log_lines_for_height()
        layout["body"].split_column(
            Layout(name="top", ratio=3),
            Layout(self.create_log_viewer(max_lines=logs_lines), name="logs", ratio=1),
        )

        # Panels
        status_panel = self.create_status_panel()
        menu_panel   = self.create_menu()
        task_panel   = self.create_task_info_panel()

        top = layout["body"]["top"]
        if mode == "triple":
            top.split_row(
                Layout(status_panel, name="status", ratio=30, minimum_size=28),
                Layout(menu_panel,   name="menu",   ratio=36, minimum_size=30),
                Layout(task_panel,   name="task",   ratio=34, minimum_size=30),
            )
        elif mode == "double":
            # Menu gets space; status+details stack in the right column
            right = Layout(name="right")
            right.split_column(
                Layout(status_panel, name="status", size=9),
                Layout(task_panel,   name="task")
            )
            top.split_row(
                Layout(menu_panel, name="menu", ratio=55, minimum_size=38),
                right
            )
        else:  # single
            top.split_column(
                Layout(menu_panel,   name="menu"),
                Layout(status_panel, name="status", size=9),
                Layout(task_panel,   name="task"),
            )

        return layout
    
    def start_animation_thread(self):
        """Start background animation thread"""
        def animate():
            while self.animation_running:
                self.animation_frame = (self.animation_frame + 1) % 4
                time.sleep(0.5)
        
        thread = threading.Thread(target=animate, daemon=True)
        thread.start()
    
    def get_spinner_char(self) -> str:
        """Get current spinner character"""
        chars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        return chars[self.animation_frame % len(chars)]
    
    def create_task_info_panel(self) -> Panel:
        """Create a panel showing info about the currently selected task"""
        selected = self.menu_options[self.selected_option]
        key, description, _, _ = selected
        
        info_content = ""
        
        if key == "1":  # Build macOS Release
            info_content = """[bold white]Build macOS (Release)[/bold white]

Creates an optimized production build of your Flutter app for macOS.

[bright_yellow]What it does:[/bright_yellow]
• Cleans previous builds
• Updates dependencies
• Compiles with tree-shaking
• Generates optimized binary
• Copies to build/ directory

[bright_green]Output:[/bright_green] Ready-to-distribute .app bundle"""
            
        elif key == "2":  # Run Debug
            info_content = """[bold white]Run (Debug)[/bold white]

Launches your Flutter app in development mode with hot reload capabilities.

[bright_yellow]What it does:[/bright_yellow]
• Compiles in debug mode
• Enables hot reload
• Shows debug info
• Connects to Flutter tools

[bright_green]Best for:[/bright_green] Development and testing"""
            
        elif key == "3":  # Run Tests
            info_content = """[bold white]Run Tests[/bold white]

Executes your test suite with live output and detailed reporting.

[bright_yellow]What it does:[/bright_yellow]
• Runs unit tests
• Runs widget tests
• Generates coverage reports
• Shows real-time results
• Saves detailed logs

[bright_green]Output:[/bright_green] Test results in build/test_results.txt"""
            
        elif key == "4":  # View Test Results
            info_content = """[bold white]View Test Results[/bold white]

Displays the results from your last test run with color-coded output.

[bright_yellow]What it shows:[/bright_yellow]
• Pass/fail status
• Test execution details
• Error messages
• Coverage information

[bright_green]Source:[/bright_green] build/test_results.txt"""
            
        elif key == "5":  # Deploy
            info_content = """[bold white]Deploy to /Applications[/bold white]

Installs your built app to the system Applications folder for easy access.

[bright_yellow]What it does:[/bright_yellow]
• Copies app to /Applications
• Sets proper permissions
• Removes old versions
• Optional launch after install

[bright_green]Result:[/bright_green] App available in Spotlight & Launchpad"""
            
        elif key == "6":  # Clean
            info_content = """[bold white]Clean[/bold white]

Removes all build artifacts and temporary files to ensure a fresh start.

[bright_yellow]What it clears:[/bright_yellow]
• Flutter build cache
• Compiled binaries
• Generated files
• Local build directory

[bright_green]Use when:[/bright_green] Build issues or switching branches"""
            
        elif key == "7":  # Pub Get
            info_content = """[bold white]Pub Get (Dependencies)[/bold white]

Downloads and updates all project dependencies listed in pubspec.yaml.

[bright_yellow]What it does:[/bright_yellow]
• Downloads packages
• Resolves version conflicts
• Updates lock file
• Refreshes imports

[bright_green]Run after:[/bright_green] Adding new dependencies"""
            
        elif key == "8":  # Analyze
            info_content = """[bold white]Analyze[/bold white]

Performs static analysis to find potential issues, style violations, and code improvements.

[bright_yellow]What it checks:[/bright_yellow]
• Syntax errors
• Style violations
• Unused imports
• Type mismatches
• Best practices

[bright_green]Helps with:[/bright_green] Code quality and consistency"""
            
        elif key == "9":  # Dashboard
            info_content = """[bold white]Dashboard[/bold white]

Shows comprehensive project statistics and build history.

[bright_yellow]What it displays:[/bright_yellow]
• Build success rates
• Average build times
• Recent activity log
• Project health metrics
• Historical trends

[bright_green]Useful for:[/bright_green] Tracking project progress"""
            
        elif key == "0":  # Settings
            info_content = """[bold white]Settings[/bold white]

Configure build manager preferences and behavior.

[bright_yellow]Options include:[/bright_yellow]
• Theme selection
• Auto-clean before build
• Notification preferences
• Verbose output mode
• Animation speed

[bright_green]Changes:[/bright_green] Saved automatically"""
            
        elif key == "l":  # Logs
            info_content = """[bold white]View Logs[/bold white]

Real-time system log viewer with filtering.

[bright_yellow]Shows:[/bright_yellow]
• Command execution logs
• Build output
• Error messages
• Timestamps
• Status updates

[bright_green]Features:[/bright_green] Scrollable, clearable, color-coded"""
            
        elif key == "h":  # Help
            info_content = """[bold white]Help[/bold white]

Comprehensive keyboard shortcuts and usage guide.

[bright_yellow]Learn about:[/bright_yellow]
• Keyboard shortcuts
• Quick actions
• Navigation tips
• Advanced features
• Best practices

[bright_green]Press:[/bright_green] '?' or 'h' anytime for help"""
            
        elif key == "q":  # Quit
            info_content = """[bold white]Quit[/bold white]

Exits the build manager safely.

[bright_yellow]What it does:[/bright_yellow]
• Saves current state
• Cleans up resources
• Returns to terminal

[bright_green]Tip:[/bright_green] Press 'q' from anywhere to quit"""
        
        return Panel(info_content, title="Task Details", style="bright_cyan", padding=(1, 2))
        
    

    def _key_reader(self):
        """Background thread: read keys and push to queue (single source of truth)."""
        while True:
            k = readchar.readkey()
            self._keyq.put(k)

    def get_key(self, timeout: float = 0.08):
        """Return a normalized key or None (blocks up to timeout)."""
        try:
            k = self._keyq.get(timeout=timeout)
            return self._normalize_key(k)
        except queue.Empty:
            return None

    def _normalize_key(self, k: str) -> str:
        """Map readchar's symbolic keys to normalized tokens"""
        if k == readchar.key.UP:    return "UP"
        if k == readchar.key.DOWN:  return "DOWN"
        if k == readchar.key.LEFT:  return "LEFT"
        if k == readchar.key.RIGHT: return "RIGHT"
        if k in (readchar.key.ENTER, '\r', '\n'): return '\n'
        if k in (readchar.key.BACKSPACE, '\x08', '\x7f'): return 'BACKSPACE'
        if k == readchar.key.ESC:   return 'ESC'
        if k == readchar.key.CTRL_C: return 'CTRL_C'
        return k  # printable char

    def wait_any_key(self, msg="Press any key to return…"):
        """Wait for any key press and return"""
        self.console.print(f"\n[dim]{msg}[/dim]")
        while True:
            k = self.get_key(timeout=1.0)
            if k is not None:
                break

    def confirm(self, prompt: str, default: bool = True) -> bool:
        """Simple confirmation using the queue (no Rich conflicts)"""
        hint = "[Y/n]" if default else "[y/N]"
        self.console.print(f"{prompt} {hint}")
        while True:
            k = self.get_key(timeout=None)
            if k == '\n': return default
            if isinstance(k, str) and len(k) == 1:
                if k.lower() == 'y': return True
                if k.lower() == 'n': return False
            if k == 'ESC': return False

    def read_line(self, prompt: str) -> str:
        """Simple line input using the same key queue (supports basic backspace)"""
        self.console.print(prompt, end="", style="bright_cyan")
        buf = []
        while True:
            k = self.get_key(timeout=None)
            if k == '\n':
                self.console.print("")  # newline
                return "".join(buf)
            elif k == 'BACKSPACE':
                if buf:
                    buf.pop()
                    # visually erase one char (works in most terminals)
                    self.console.print("\b \b", end="")
            elif isinstance(k, str) and len(k) == 1 and k.isprintable():
                buf.append(k)
                self.console.print(k, end="")
            # ignore arrows/esc here
        
    def run_command(self, cmd: list, cwd: Optional[Path] = None, capture_output: bool = False) -> subprocess.CompletedProcess:
        """Run a shell command with optional working directory"""
        if cwd is None:
            cwd = self.flutter_project
        
        self.log_viewer.add_log(f"Running: {' '.join(cmd)}", "bright_cyan")
        
        try:
            if capture_output:
                result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=False)
            else:
                result = subprocess.run(cmd, cwd=cwd, check=False)
            
            if result.returncode == 0:
                self.log_viewer.add_log(f"Success: {cmd[0]}", "bright_green")
            else:
                self.log_viewer.add_log(f"Failed: {cmd[0]} (exit {result.returncode})", "bright_red")
            
            return result
        except Exception as e:
            self.log_viewer.add_log(f"Error: {str(e)}", "bright_red")
            self.console.print(f"[bright_red]Error running command: {e}[/bright_red]")
            return subprocess.CompletedProcess(cmd, 1, "", str(e))

    def run_command_with_live_output(self, cmd: list, cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
        """Run a command and show live output with test result highlighting"""
        if cwd is None:
            cwd = self.flutter_project
            
        try:
            process = subprocess.Popen(
                cmd, 
                cwd=cwd, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.STDOUT, 
                text=True, 
                bufsize=1, 
                universal_newlines=True
            )
            
            output_lines = []
            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break
                if output:
                    line = output.strip()
                    output_lines.append(line)
                    
                    # Highlight test results in real-time
                    if "✓" in line or "PASS" in line or line.endswith("PASSED"):
                        self.console.print(f"[bright_green]{line}[/bright_green]")
                    elif "✗" in line or "FAIL" in line or line.endswith("FAILED") or "ERROR" in line:
                        self.console.print(f"[bright_red]{line}[/bright_red]")
                    elif line.startswith("00:") and "+" in line:  # Test timing info
                        self.console.print(f"[dim]{line}[/dim]")
                    elif "loading" in line.lower() or "running" in line.lower():
                        self.console.print(f"[bright_yellow]{line}[/bright_yellow]")
                    elif line.startswith("Test run finished:"):
                        self.console.print(f"[bold bright_cyan]{line}[/bold bright_cyan]")
                    else:
                        self.console.print(line)
            
            process.wait()
            
            return subprocess.CompletedProcess(
                cmd, 
                process.returncode, 
                stdout="\n".join(output_lines), 
                stderr=""
            )
            
        except Exception as e:
            self.console.print(f"[bright_red]Error running command: {e}[/bright_red]")
            return subprocess.CompletedProcess(cmd, 1, "", str(e))

    def _i(self, text: str, fallback: str) -> str:
        """Return emoji or fallback based on settings"""
        return text if self.settings.get("use_emoji", True) else fallback
    
    def _fmt_path(self, p: Path) -> str:
        """Format path with ellipsis for display"""
        s = str(p)
        # give roughly a third of terminal to this column, minus padding
        maxw = max(18, self.console.size.width // 3 - 8)
        if len(s) <= maxw:
            return s
        # middle-ellipsis
        left = maxw // 2 - 1
        right = maxw - left - 1
        return f"{s[:left]}…{s[-right:]}"
    
    def create_header(self) -> Panel:
        """Create adaptive animated header with status indicators"""
        title = Text("MDTool Build Manager", style="bold bright_cyan")
        subtitle = Text("Enhanced Flutter Build System", style="italic bright_white")
        
        status = "[bright_green]● Flutter OK[/bright_green]" if self.check_flutter() else "[bright_red]● Flutter Missing[/bright_red]"
        if self.animation_running:
            status += f"  [dim]{self.get_spinner_char()}[/dim]"
        
        header_content = Group(
            Align.center(title),
            Align.center(subtitle),
            Align.center(Text.from_markup(status))
        )
        
        # Adaptive box style based on terminal width
        w = self.console.size.width
        box = DOUBLE if w >= 120 else (ROUNDED if w >= 90 else MINIMAL)
        
        return Panel(
            header_content, 
            style="bright_cyan", 
            box=box,
            padding=(1, 2)
        )

    def create_status_panel(self) -> Panel:
        """Create status information panel"""
        flutter_check = self.check_flutter()
        project_check = self.flutter_project.exists()
        
        status_table = Table.grid(padding=1)
        status_table.add_column(style="bright_cyan", no_wrap=True)
        status_table.add_column(ratio=1, overflow="ellipsis")  # important
        
        status_table.add_row("Flutter:", "✅ Available" if flutter_check else "❌ Not found")
        status_table.add_row("Project:", "✅ Found" if project_check else "❌ Missing")
        status_table.add_row("Build Dir:", f"{self._i('📁','Dir:')} {self._fmt_path(self.build_dir)}")
        status_table.add_row("Project Dir:", f"{self._i('📁','Dir:')} {self._fmt_path(self.flutter_project)}")
        
        # Add stats from history
        stats = self.history.get_stats()
        if stats['total_builds'] > 0:
            status_table.add_row("", "")  # Empty row
            status_table.add_row("Builds:", f"{stats['total_builds']} total")
            status_table.add_row("Success Rate:", f"{stats['success_rate']:.1f}%")
        
        return Panel(status_table, title="System Status", style="bright_green")

    def check_flutter(self, ttl: float = 5.0) -> bool:
        """Check if Flutter is available (cached to avoid layout jank)."""
        ok, ts = self._sys_cache.get("flutter_ok", (False, 0.0))
        now = _mono()
        if now - ts < ttl:
            return ok
        try:
            subprocess.run(["flutter", "--version"], capture_output=True, check=True)
            ok = True
        except Exception:
            ok = False
        self._sys_cache["flutter_ok"] = (ok, now)
        return ok

    def create_menu(self) -> Panel:
        """Create adaptive main menu with highlighted selection"""
        menu_table = Table.grid(padding=1)
        menu_table.add_column(style="bold bright_yellow", width=3, no_wrap=True)
        menu_table.add_column(style="white", ratio=1, overflow="fold")  # ← ensure fold
        
        for i, (key, description, _, _) in enumerate(self.menu_options):
            if i == self.selected_option:
                menu_table.add_row(f"[reverse]{key}.[/reverse]", f"[reverse]{description}[/reverse]")
            else:
                menu_table.add_row(f"{key}.", description)
        
        # adaptive, shorter title prevents wrapping in small terminals
        w = self.console.size.width
        title = "Options (↑↓, Enter)" if w < 100 else "Options (↑↓ to navigate, Enter to select)"
        # minimal box on very narrow screens
        box = MINIMAL if w < 90 else ROUNDED
        
        return Panel(menu_table, title=title, style="bright_yellow", box=box)
    
    def _controls_line(self):
        """Create adaptive controls footer"""
        w = self.console.size.width
        long = "↑↓ Navigate • Enter Select • Quick: b r t c d s l ? / • q Quit"
        short = "↑↓ • Enter • b r t c d s l ? / • q"
        text = long if w >= 80 else short
        return Align.center(Text.from_markup(f"[dim white]{text}[/dim white]"))
    
    def create_log_viewer(self, max_lines: int = 10) -> Panel:
        """Create a height-aware log viewer panel"""
        logs = self.log_viewer.get_logs(max_lines)
        log_table = Table.grid(padding=0, expand=True)
        log_table.add_column(width=8, style="dim", no_wrap=True)
        log_table.add_column(ratio=1, overflow="fold")
        for timestamp, text, style in logs:
            if style:
                log_table.add_row(timestamp, f"[{style}]{text}[/{style}]")
            else:
                log_table.add_row(timestamp, text)
        return Panel(log_table, title=f"{self._i('📜','Logs ')}Live Logs", style="bright_magenta", box=ROUNDED)
    
    def create_dashboard(self) -> Panel:
        """Create a dashboard view with stats and graphs"""
        stats = self.history.get_stats()
        
        # Create stats table
        stats_table = Table.grid(padding=1)
        stats_table.add_column(style="bright_cyan")
        stats_table.add_column(style="white")
        
        stats_table.add_row("📊 Total Builds:", str(stats['total_builds']))
        stats_table.add_row("✅ Successful:", str(stats['successful_builds']))
        stats_table.add_row("❌ Failed:", str(stats['failed_builds']))
        stats_table.add_row("📈 Success Rate:", f"{stats['success_rate']:.1f}%")
        stats_table.add_row("⏱️  Avg Duration:", f"{stats['avg_duration']:.1f}s")
        
        # Create recent activity list
        recent = Tree("📜 Recent Activity")
        for entry in self.history.history[-5:]:
            timestamp = datetime.fromisoformat(entry['timestamp']).strftime("%H:%M")
            icon = "✅" if entry['success'] else "❌"
            recent.add(f"{timestamp} {icon} {entry['action']}")
        
        # Combine into columns
        content = Columns([stats_table, recent], equal=True)
        
        return Panel(
            content,
            title="📊 Dashboard",
            style="bright_cyan",
            box=ROUNDED
        )
    
    def show_dashboard(self):
        """Show the dashboard view"""
        self.current_view = "dashboard"
        self.console.clear()
        self.console.print(self.create_header())
        self.console.print(self.create_dashboard())
        
        self.wait_any_key("Press any key to return to main menu")
        self.current_view = "main"
    
    def show_settings(self):
        """Show settings interface"""
        self.current_view = "settings"
        self.console.clear()
        self.console.print(self.create_header())
        
        # Create settings table
        settings_table = Table(title="⚙️ Settings", show_header=True, header_style="bold bright_cyan")
        settings_table.add_column("Setting", style="bright_yellow")
        settings_table.add_column("Current Value", style="white")
        settings_table.add_column("Key", style="dim white")
        
        settings_options = [
            ("Auto Clean Before Build", str(self.settings.get("auto_clean_before_build")), "1"),
            ("Show Notifications", str(self.settings.get("show_notifications")), "2"),
            ("Verbose Output", str(self.settings.get("verbose_output")), "3"),
            ("Auto Deploy After Build", str(self.settings.get("auto_deploy")), "4"),
        ]
        
        for name, value, key in settings_options:
            settings_table.add_row(name, value, f"Press {key}")
        
        self.console.print(settings_table)
        self.console.print(f"\n[dim white]Press number to toggle setting, ESC or any other key to return[/dim white]")
        
        # Handle input
        key = self.get_key(timeout=None)
        
        if key == '1':
            self.settings.set("auto_clean_before_build", not self.settings.get("auto_clean_before_build"))
            self.show_settings()
        elif key == '2':
            self.settings.set("show_notifications", not self.settings.get("show_notifications"))
            self.show_settings()
        elif key == '3':
            self.settings.set("verbose_output", not self.settings.get("verbose_output"))
            self.show_settings()
        elif key == '4':
            self.settings.set("auto_deploy", not self.settings.get("auto_deploy"))
            self.show_settings()
        else:
            self.current_view = "main"
    
    def show_logs(self):
        """Show full log viewer"""
        self.current_view = "logs"
        self.console.clear()
        self.console.print(self.create_header())
        
        # Show extended logs
        logs = self.log_viewer.get_logs(30)
        
        log_content = "\n".join([f"[dim white]{ts}[/dim white] {text}" for ts, text, _ in logs])
        if not log_content:
            log_content = "[dim white]No logs yet. Perform some actions to see logs here.[/dim white]"
        
        log_panel = Panel(
            log_content,
            title="📜 System Logs",
            style="bright_magenta"
        )
        
        self.console.print(log_panel)
        self.console.print(f"\n[dim white]Press 'c' to clear logs, any other key to return[/dim white]")
        
        k = self.get_key(timeout=None)
        if isinstance(k, str) and k.lower() == 'c':
            self.log_viewer.logs.clear()
            self.log_viewer.add_log("Logs cleared", "bright_cyan")
            return self.show_logs()
    
    def show_help(self):
        """Show help and keyboard shortcuts"""
        self.current_view = "help"
        self.console.clear()
        self.console.print(self.create_header())
        
        help_content = """
[bright_cyan]Keyboard Shortcuts:[/bright_cyan]

[bright_yellow]Navigation:[/bright_yellow]
  ↑/↓      Navigate menu
  Enter    Select option
  ESC      Back/Cancel
  q        Quit application

[bright_yellow]Quick Actions:[/bright_yellow]
  b        Build release
  r        Run debug
  t        Run tests
  c        Clean project
  d        Show dashboard
  s        Settings
  l        View logs
  ?/h      This help
  /        Search commands

[bright_yellow]Direct Selection:[/bright_yellow]
  1-9,0    Select menu item directly

[dim white]Tips:[/dim white]
  • Dashboard tracks your build statistics
  • Settings are saved automatically
  • Logs show detailed operation history
  • Use quick keys for faster workflow
"""
        
        self.console.print(Panel(help_content, title="❓ Help", style="bright_cyan", box=ROUNDED))
        
        self.wait_any_key()
        self.current_view = "main"
    
    def search_commands(self):
        """Search for commands"""
        self.console.clear()
        self.console.print(self.create_header())
        
        search_term = self.read_line("[bright_cyan]Search for command[/bright_cyan]: ")
        
        if search_term:
            results = []
            for key, desc, func, _ in self.menu_options:
                if search_term.lower() in desc.lower():
                    results.append((key, desc, func))
            
            if results:
                self.console.print(f"\n[bright_green]Found {len(results)} results:[/bright_green]")
                for key, desc, _ in results:
                    self.console.print(f"  [bright_yellow]{key}[/bright_yellow] - {desc}")
                
                self.console.print(f"\n[dim white]Press key to execute, ESC to cancel[/dim white]")
                
                choice = self.get_key(timeout=None)
                for key, desc, func in results:
                    if choice == key and func:
                        func()
                        break
            else:
                self.console.print(f"[bright_yellow]No commands found matching '{search_term}'[/bright_yellow]")
                time.sleep(1)

    def build_macos_release(self):
        """Build the Flutter app for macOS release"""
        start_time = time.time()
        self.console.print(f"\n[bold bright_yellow]Building macOS Release...[/bold bright_yellow]")
        
        # Check for auto-clean setting
        if self.settings.get("auto_clean_before_build"):
            self.console.print(f"[bright_cyan]Auto-cleaning before build...[/bright_cyan]")
            self.clean_project()
        
        with Progress(
            SpinnerColumn(style="bright_cyan"),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(style="bright_cyan"),
            TaskProgressColumn(),
            TimeRemainingColumn(),
            console=self.console,
        ) as progress:
            
            total_steps = 3
            main_task = progress.add_task("Building...", total=total_steps)
            
            # Step 1: Clean
            clean_task = progress.add_task("Cleaning previous builds...", total=None)
            clean_result = self.run_command(["flutter", "clean"])
            progress.remove_task(clean_task)
            progress.update(main_task, advance=1)
            
            # Step 2: Get dependencies
            deps_task = progress.add_task("Getting dependencies...", total=None)
            deps_result = self.run_command(["flutter", "pub", "get"])
            progress.remove_task(deps_task)
            progress.update(main_task, advance=1)
            
            # Step 3: Build for macOS
            build_task = progress.add_task("Building macOS release...", total=None)
            cmd = ["flutter", "build", "macos", "--release", "--tree-shake-icons"]
            result = self.run_command(cmd)
            progress.remove_task(build_task)
            progress.update(main_task, advance=1)
            
            duration = time.time() - start_time
            success = result.returncode == 0
            
            # Add to history
            self.history.add_entry("build", success, duration)
            
            if success:
                self.console.print(f"[bright_green]✅ Build completed in {duration:.1f}s![/bright_green]")
                
                # Copy to build directory
                source_app = self.flutter_project / "build" / "macos" / "Build" / "Products" / "Release" / "MDTool.app"
                dest_app = self.build_dir / "MDTool.app"
                
                if source_app.exists():
                    import shutil
                    if dest_app.exists():
                        shutil.rmtree(dest_app)
                    shutil.copytree(source_app, dest_app)
                    self.console.print(f"[bright_green]📦 App copied to: {dest_app}[/bright_green]")
                    
                    # Show app size
                    app_size = self.get_app_size(dest_app)
                    self.console.print(f"[bright_cyan]📏 App size: {app_size}[/bright_cyan]")
                    
                    # Show notification if enabled
                    if self.settings.get("show_notifications"):
                        try:
                            subprocess.run(["osascript", "-e", f'display notification "Build completed successfully!" with title "MDTool Build Manager"'])
                        except:
                            pass
                    
                    # Auto-deploy if enabled
                    if self.settings.get("auto_deploy"):
                        self.console.print(f"[bright_cyan]Auto-deploying to /Applications...[/bright_cyan]")
                        self.deploy_to_applications()
                else:
                    self.console.print("[bright_red]❌ Built app not found![/bright_red]")
            else:
                self.console.print("[bright_red]❌ Build failed![/bright_red]")

    def get_app_size(self, app_path: Path) -> str:
        """Get human-readable app bundle size"""
        try:
            result = self.run_command(["du", "-sh", str(app_path)], capture_output=True)
            if result.returncode == 0:
                return result.stdout.split()[0]
        except:
            pass
        return "Unknown"

    def run_debug(self):
        """Run the Flutter app in debug mode"""
        self.console.print(f"\n[bold bright_yellow]Starting Debug Run...[/bold bright_yellow]")
        self.console.print("[dim white]Press Ctrl+C to stop the app[/dim white]\n")
        
        start_time = time.time()
        cmd = ["flutter", "run", "-d", "macos"]
        
        if self.settings.get("verbose_output"):
            cmd.append("-v")
        
        try:
            result = self.run_command(cmd)
            duration = time.time() - start_time
            self.history.add_entry("run", result.returncode == 0, duration)
        except KeyboardInterrupt:
            self.console.print(f"\n[bright_yellow]App stopped by user[/bright_yellow]")

    def clean_project(self):
        """Clean the Flutter project and build artifacts"""
        if not hasattr(self, '_cleaning_confirmed'):
            if self.confirm("Clean all build artifacts?"):
                self._cleaning_confirmed = True
            else:
                self.console.print("[bright_cyan]Clean cancelled.[/bright_cyan]")
                return
        
        self.console.print(f"\n[bold bright_yellow]Cleaning Project...[/bold bright_yellow]")
        
        with Progress(
            SpinnerColumn(style="bright_cyan"),
            TextColumn("[progress.description]{task.description}"),
            console=self.console,
        ) as progress:
            task1 = progress.add_task("Running flutter clean...", total=None)
            
            result = self.run_command(["flutter", "clean"])
            
            progress.update(task1, description="Cleaning build artifacts...")
            
            # Clean our build directory
            import shutil
            for item in self.build_dir.iterdir():
                if item.name != ".build_manager":  # Don't delete our data
                    if item.is_dir():
                        shutil.rmtree(item)
                    else:
                        item.unlink()
                    
            if result.returncode == 0:
                self.console.print("[bright_green]✅ Project cleaned successfully![/bright_green]")
            else:
                self.console.print("[bright_red]❌ Clean failed![/bright_red]")
        
        self._cleaning_confirmed = False

    def pub_get(self):
        """Get Flutter dependencies"""
        self.console.print(f"\n[bold bright_yellow]Getting Dependencies...[/bold bright_yellow]")
        
        with Progress(
            SpinnerColumn(style="bright_cyan"),
            TextColumn("[progress.description]{task.description}"),
            console=self.console,
        ) as progress:
            task = progress.add_task("Running pub get...", total=None)
            
            result = self.run_command(["flutter", "pub", "get"])
            
            if result.returncode == 0:
                self.console.print("[bright_green]✅ Dependencies updated successfully![/bright_green]")
            else:
                self.console.print("[bright_red]❌ Pub get failed![/bright_red]")

    def analyze_code(self):
        """Run Flutter code analysis"""
        self.console.print(f"\n[bold bright_yellow]Analyzing Code...[/bold bright_yellow]")
        
        result = self.run_command(["flutter", "analyze"], capture_output=True)
        
        if result.returncode == 0:
            self.console.print("[bright_green]✅ No analysis issues found![/bright_green]")
        else:
            self.console.print("[bright_yellow]⚠️  Analysis completed with issues:[/bright_yellow]")
            if result.stdout:
                # Parse and categorize issues
                lines = result.stdout.split('\n')
                errors = [l for l in lines if 'error' in l.lower()]
                warnings = [l for l in lines if 'warning' in l.lower()]
                info = [l for l in lines if 'info' in l.lower()]
                
                if errors:
                    self.console.print(f"[bright_red]Errors: {len(errors)}[/bright_red]")
                if warnings:
                    self.console.print(f"[bright_yellow]Warnings: {len(warnings)}[/bright_yellow]")
                if info:
                    self.console.print(f"[bright_cyan]Info: {len(info)}[/bright_cyan]")
                
                # Show first few issues
                self.console.print(f"\n[dim white]First issues:[/dim white]")
                for line in lines[:5]:
                    if line.strip():
                        self.console.print(f"  {line}")

    def run_tests(self):
        """Run Flutter tests with enhanced output"""
        start_time = time.time()
        self.console.print(f"\n[bold bright_yellow]Running Tests...[/bold bright_yellow]")
        
        # Store test results
        test_results = {}
        
        # Run unit tests with live output
        self.console.print(f"\n[bright_cyan]📋 Running Tests:[/bright_cyan]")
        result = self.run_command_with_live_output(["flutter", "test", "--reporter=expanded"])
        test_results['unit'] = result
        
        duration = time.time() - start_time
        
        # Parse results for summary
        if result.stdout:
            lines = result.stdout.split('\n')
            passed = sum(1 for line in lines if '✓' in line or 'PASS' in line)
            failed = sum(1 for line in lines if '✗' in line or 'FAIL' in line)
            
            # Save to history
            self.history.add_entry("test", failed == 0, duration, f"Passed: {passed}, Failed: {failed}")
            
            # Display summary
            if failed == 0:
                self.console.print(f"[bright_green]✅ All tests passed! ({passed} tests in {duration:.1f}s)[/bright_green]")
            else:
                self.console.print(f"[bright_red]❌ Tests failed! Passed: {passed}, Failed: {failed} (in {duration:.1f}s)[/bright_red]")
        
        # Save results to file
        results_file = self.build_dir / "test_results.txt"
        with open(results_file, 'w') as f:
            f.write(f"Test Results - {datetime.now()}\n")
            f.write("=" * 50 + "\n\n")
            f.write(result.stdout if result.stdout else "No output")
        
        self.console.print(f"[bright_cyan]📄 Full results saved to: {results_file}[/bright_cyan]")
        
        # Check for coverage
        coverage_file = self.flutter_project / "coverage" / "lcov.info"
        if coverage_file.exists():
            self.console.print(f"[bright_cyan]📊 Coverage report available: {coverage_file}[/bright_cyan]")

    def view_test_results(self):
        """View the last test results"""
        results_file = self.build_dir / "test_results.txt"
        
        if not results_file.exists():
            self.console.print("[bright_red]❌ No test results found. Run tests first![/bright_red]")
            self.wait_any_key("Press any key to return to menu…")
            return
        
        self.console.print(f"\n[bold bright_yellow]Test Results[/bold bright_yellow]\n")
        
        try:
            with open(results_file, 'r') as f:
                content = f.read()
                
            # Display with syntax highlighting
            lines = content.split('\n')
            max_lines = 30
            
            for i, line in enumerate(lines[:max_lines]):
                if "Exit Code: 0" in line:
                    self.console.print(f"[bright_green]{line}[/bright_green]")
                elif "Exit Code:" in line and not line.endswith("0"):
                    self.console.print(f"[bright_red]{line}[/bright_red]")
                elif "PASSED" in line or "✓" in line:
                    self.console.print(f"[bright_green]{line}[/bright_green]")
                elif "FAILED" in line or "✗" in line:
                    self.console.print(f"[bright_red]{line}[/bright_red]")
                elif line.startswith("Test Results"):
                    self.console.print(f"[bold bright_cyan]{line}[/bold bright_cyan]")
                else:
                    self.console.print(line)
            
            if len(lines) > max_lines:
                self.console.print(f"\n[dim white]... ({len(lines) - max_lines} more lines)[/dim white]")
                self.console.print(f"[dim white]Full results in: {results_file}[/dim white]")
                
        except Exception as e:
            self.console.print(f"[bright_red]❌ Error reading test results: {e}[/bright_red]")
        
        self.wait_any_key("Press any key to return to menu…")

    def deploy_to_applications(self):
        """Deploy the app to /Applications folder"""
        self.console.print(f"\n[bold bright_yellow]Deploying to /Applications...[/bold bright_yellow]")
        
        source_app = self.build_dir / "MDTool.app"
        if not source_app.exists():
            self.console.print("[bright_red]❌ App not found in build directory. Build first![/bright_red]")
            return
            
        dest_app = Path("/Applications") / "MDTool.app"
        
        try:
            import shutil
            
            with Progress(
                SpinnerColumn(style="bright_cyan"),
                TextColumn("[progress.description]{task.description}"),
                console=self.console,
            ) as progress:
                
                if dest_app.exists():
                    task = progress.add_task("Removing old version...", total=None)
                    shutil.rmtree(dest_app)
                    progress.remove_task(task)
                
                task = progress.add_task("Copying app to /Applications...", total=None)
                shutil.copytree(source_app, dest_app)
                progress.remove_task(task)
                
                task = progress.add_task("Setting permissions...", total=None)
                os.chmod(dest_app, 0o755)
                executable_path = dest_app / "Contents" / "MacOS" / "MDTool"
                if executable_path.exists():
                    os.chmod(executable_path, 0o755)
                progress.remove_task(task)
            
            self.console.print(f"[bright_green]✅ App successfully deployed to: {dest_app}[/bright_green]")
            self.console.print("[bright_cyan]💡 You can now launch it from Spotlight or Applications folder[/bright_cyan]")
            
            # Offer to launch
            if self.confirm("Launch the app now?", default=True):
                try:
                    subprocess.run(["open", str(dest_app)], check=True)
                    self.console.print("[bright_green]🚀 App launched![/bright_green]")
                except subprocess.CalledProcessError:
                    self.console.print("[bright_red]❌ Failed to launch app[/bright_red]")
                    
        except PermissionError:
            self.console.print("[bright_red]❌ Permission denied! Try running with sudo or check folder permissions.[/bright_red]")
        except Exception as e:
            self.console.print(f"[bright_red]❌ Deployment failed: {e}[/bright_red]")

    def show_build_info(self):
        """Show build and project information"""
        self.console.print(f"\n[bold bright_yellow]Build Information[/bold bright_yellow]\n")
        
        info_table = Table(show_header=True, header_style="bold bright_magenta")
        info_table.add_column("Property", style="bright_cyan")
        info_table.add_column("Value", style="white")
        
        # Get Flutter version
        flutter_result = self.run_command(["flutter", "--version"], capture_output=True)
        flutter_version = "Unknown"
        if flutter_result.returncode == 0 and flutter_result.stdout:
            flutter_version = flutter_result.stdout.split('\n')[0]
        
        # Check if built app exists
        built_app = self.build_dir / "MDTool.app"
        app_status = "✅ Available" if built_app.exists() else "❌ Not built"
        
        # Get app size if it exists
        app_size = "N/A"
        if built_app.exists():
            app_size = self.get_app_size(built_app)
        
        # Get build stats
        stats = self.history.get_stats()
        
        info_table.add_row("Flutter Version", flutter_version)
        info_table.add_row("Project Name", "MDTool")
        info_table.add_row("Built App", app_status)
        info_table.add_row("App Size", app_size)
        info_table.add_row("Total Builds", str(stats['total_builds']))
        info_table.add_row("Success Rate", f"{stats['success_rate']:.1f}%")
        info_table.add_row("Project Path", str(self.flutter_project))
        info_table.add_row("Build Output", str(self.build_dir))
        
        self.console.print(info_table)
        
        self.wait_any_key("Press any key to return to menu…")

    def display_interface(self):
        """Display the main interface - kept for compatibility"""
        return self.create_layout()

    def main_loop(self):
        """Main application loop with Live rendering and smooth animations"""
        self.animation_running = True
        try:
            with Live(self.create_layout(), console=self.console, refresh_per_second=10, screen=True) as live:
                while True:
                    live.update(self.create_layout(), refresh=True)

                    key = self.get_key(0.08)   # normalized or None
                    if key is None:
                        continue

                    if key == 'CTRL_C':
                        break
                    if key == "UP":
                        self.selected_option = (self.selected_option - 1) % len(self.menu_options)
                        continue
                    if key == "DOWN":
                        self.selected_option = (self.selected_option + 1) % len(self.menu_options)
                        continue
                    if key in ('\n',):
                        selected = self.menu_options[self.selected_option]
                        if selected[0] == 'q': break
                        if selected[2]:
                            live.stop(); selected[2](); live.start()
                        continue

                    if isinstance(key, str) and len(key) == 1 and key.isprintable():
                        k = key.lower()
                        if k == 'q': break
                        elif k.isdigit():
                            for opt_key, _, func, _ in self.menu_options:
                                if k == opt_key and func:
                                    live.stop(); func(); live.start(); break
                        elif k in self.shortcuts:
                            _, func = self.shortcuts[k]
                            if func:
                                live.stop(); func(); live.start()
                        continue
        finally:
            self.animation_running = False
            self.console.print("\n[bold bright_green]Goodbye! 👋[/bold bright_green]")

def main():
    """Entry point"""
    try:
        manager = FlutterBuildManager()
        manager.main_loop()
    except KeyboardInterrupt:
        print("\n\nGoodbye! 👋")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()