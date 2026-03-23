#!/usr/bin/env python3
"""
Build Tool for MDTool - Flutter Cross-Platform Markdown Editor
Provides automated build, deploy, and version management capabilities.
"""

import os
import sys
import shutil
import subprocess
import platform
import json
import re
import time
from pathlib import Path
from datetime import datetime
from typing import Tuple, Optional, List

# Optional YAML support - graceful fallback
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


class Colors:
    """Console color constants"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


class BuildTool:
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.flutter_project = self.project_root / "src" / "mdtool"
        self.deploy_dir = self.project_root / "deploy"
        self.current_os = platform.system().lower()
        
        # Ensure deploy directory exists
        self.deploy_dir.mkdir(exist_ok=True)
    
    def print_colored(self, message, color=Colors.ENDC):
        """Print colored message to console"""
        print(f"{color}{message}{Colors.ENDC}")
    
    def run_command(self, command, cwd=None, shell=False, stream_output=True):
        """Run shell command with optional streaming output"""
        try:
            if cwd is None:
                cwd = self.flutter_project
            
            cmd_str = ' '.join(command) if isinstance(command, list) else command
            self.print_colored(f"Running: {cmd_str}", Colors.OKCYAN)
            
            if stream_output:
                return self._run_with_streaming(command, cwd, shell)
            else:
                return self._run_with_capture(command, cwd, shell)
        except Exception as e:
            self.print_colored(f"Command failed: {e}", Colors.FAIL)
            return False
    
    def _run_with_streaming(self, command, cwd, shell):
        """Run command with live output streaming"""
        try:
            process = subprocess.Popen(
                command,
                cwd=cwd,
                shell=shell,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Stream output in real-time
            for line in process.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()
            
            return_code = process.wait()
            
            if return_code != 0:
                self.print_colored(f"Command failed with exit code {return_code}", Colors.FAIL)
            
            return return_code == 0
        except Exception as e:
            self.print_colored(f"Streaming command failed: {e}", Colors.FAIL)
            return False
    
    def _run_with_capture(self, command, cwd, shell):
        """Run command with captured output (legacy behavior)"""
        try:
            result = subprocess.run(
                command,
                cwd=cwd,
                shell=shell,
                capture_output=True,
                text=True
            )
            
            if result.stdout:
                print(result.stdout)
            if result.stderr and result.returncode != 0:
                self.print_colored(f"Error: {result.stderr}", Colors.FAIL)
            
            return result.returncode == 0
        except Exception as e:
            self.print_colored(f"Command failed: {e}", Colors.FAIL)
            return False
    
    def get_version_info(self) -> Tuple[str, int]:
        """Get current version and build number from pubspec.yaml"""
        pubspec_path = self.flutter_project / "pubspec.yaml"
        semver_pattern = re.compile(r'^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(?:\+(?P<build>\d+))?$')
        
        if HAS_YAML:
            return self._read_version_yaml(pubspec_path, semver_pattern)
        else:
            return self._read_version_fallback(pubspec_path, semver_pattern)
    
    def _read_version_yaml(self, pubspec_path: Path, pattern) -> Tuple[str, int]:
        """Read version using YAML parser"""
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            
            raw_version = str(data.get('version', '1.0.0+1'))
            match = pattern.match(raw_version)
            
            if not match:
                self.print_colored(f"Warning: Invalid version format '{raw_version}', using fallback", Colors.WARNING)
                return "1.0.0", 1
            
            core_version = f"{match.group('major')}.{match.group('minor')}.{match.group('patch')}"
            build_number = int(match.group('build') or 1)
            
            return core_version, build_number
            
        except Exception as e:
            self.print_colored(f"Error reading version with YAML: {e}", Colors.WARNING)
            return self._read_version_fallback(pubspec_path, pattern)
    
    def _read_version_fallback(self, pubspec_path: Path, pattern) -> Tuple[str, int]:
        """Fallback version reading without YAML"""
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('version:'):
                        version_part = line.split(':', 1)[1].strip()
                        match = pattern.match(version_part)
                        if match:
                            core = f"{match.group('major')}.{match.group('minor')}.{match.group('patch')}"
                            build = int(match.group('build') or 1)
                            return core, build
            return "1.0.0", 1
        except Exception:
            return "1.0.0", 1
    
    def get_build_number(self) -> str:
        """Legacy method for compatibility"""
        _, build_number = self.get_version_info()
        return str(build_number)
    
    def bump_version(self, bump_type: str = "build", custom_version: Optional[str] = None) -> bool:
        """Enhanced version bumping with semver support"""
        pubspec_path = self.flutter_project / "pubspec.yaml"
        current_core, current_build = self.get_version_info()
        
        if custom_version:
            # Validate custom version format
            semver_pattern = re.compile(r'^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)$')
            if not semver_pattern.match(custom_version):
                self.print_colored(f"Invalid version format: {custom_version} (expected: x.y.z)", Colors.FAIL)
                return False
            new_core, new_build = custom_version, 1
        else:
            # Parse current version
            semver_pattern = re.compile(r'^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)$')
            match = semver_pattern.match(current_core)
            if not match:
                self.print_colored(f"Cannot parse current version: {current_core}", Colors.FAIL)
                return False
            
            major = int(match.group('major'))
            minor = int(match.group('minor'))
            patch = int(match.group('patch'))
            
            if bump_type == "major":
                new_core = f"{major + 1}.0.0"
                new_build = 1
            elif bump_type == "minor":
                new_core = f"{major}.{minor + 1}.0"
                new_build = 1
            elif bump_type == "patch":
                new_core = f"{major}.{minor}.{patch + 1}"
                new_build = 1
            else:  # build
                new_core = current_core
                new_build = current_build + 1
        
        if self._write_version(pubspec_path, new_core, new_build):
            self.print_colored(f"Version bumped: {current_core}+{current_build} → {new_core}+{new_build}", Colors.OKGREEN)
            return True
        return False
    
    def _write_version(self, pubspec_path: Path, core_version: str, build_number: int) -> bool:
        """Write version back to pubspec.yaml"""
        if HAS_YAML:
            return self._write_version_yaml(pubspec_path, core_version, build_number)
        else:
            return self._write_version_fallback(pubspec_path, core_version, build_number)
    
    def _write_version_yaml(self, pubspec_path: Path, core_version: str, build_number: int) -> bool:
        """Write version using YAML parser"""
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            
            data['version'] = f"{core_version}+{build_number}"
            
            with open(pubspec_path, 'w', encoding='utf-8') as f:
                yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)
            
            return True
        except Exception as e:
            self.print_colored(f"Error writing version with YAML: {e}", Colors.FAIL)
            return self._write_version_fallback(pubspec_path, core_version, build_number)
    
    def _write_version_fallback(self, pubspec_path: Path, core_version: str, build_number: int) -> bool:
        """Fallback version writing without YAML"""
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            for i, line in enumerate(lines):
                if line.strip().startswith('version:'):
                    lines[i] = f"version: {core_version}+{build_number}\n"
                    break
            
            with open(pubspec_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            
            return True
        except Exception as e:
            self.print_colored(f"Error writing version: {e}", Colors.FAIL)
            return False
    
    def check_build_directory(self, build_number):
        """Check if build directory exists and offer options"""
        build_dir = self.deploy_dir / build_number
        
        if build_dir.exists():
            self.print_colored(f"\nBuild directory already exists: {build_dir}", Colors.WARNING)
            print("1. Clean existing build (delete and rebuild)")
            print("2. Archive existing build (move to archived/)")
            print("3. Cancel build")
            
            choice = input("Choose option (1-3): ").strip()
            
            if choice == "1":
                try:
                    shutil.rmtree(build_dir)
                    self.print_colored(f"Cleaned existing build directory", Colors.OKGREEN)
                    return True
                except Exception as e:
                    self.print_colored(f"Failed to clean directory: {e}", Colors.FAIL)
                    return False
            
            elif choice == "2":
                archived_dir = self.deploy_dir / "archived" / build_number
                archived_dir.parent.mkdir(exist_ok=True)
                try:
                    shutil.move(str(build_dir), str(archived_dir))
                    self.print_colored(f"Archived build to: {archived_dir}", Colors.OKGREEN)
                    return True
                except Exception as e:
                    self.print_colored(f"Failed to archive directory: {e}", Colors.FAIL)
                    return False
            
            else:
                self.print_colored("Build cancelled", Colors.WARNING)
                return False
        
        return True
    
    def doctor(self) -> bool:
        """Comprehensive preflight checks"""
        self.print_colored("\n🏥 Running preflight checks...", Colors.HEADER)
        
        checks = [
            ("Project structure", self._check_project_structure),
            ("Flutter installation", self._check_flutter),
            ("Flutter doctor", self._check_flutter_doctor),
            ("YAML support", self._check_yaml_support)
        ]
        
        all_passed = True
        for check_name, check_func in checks:
            try:
                passed = check_func()
                status = f"{Colors.OKGREEN}✅ PASS" if passed else f"{Colors.FAIL}❌ FAIL"
                print(f"{status}: {check_name}{Colors.ENDC}")
                all_passed &= passed
            except Exception as e:
                print(f"{Colors.FAIL}❌ ERROR: {check_name} - {e}{Colors.ENDC}")
                all_passed = False
        
        if all_passed:
            self.print_colored("🎉 All preflight checks passed!", Colors.OKGREEN)
        else:
            self.print_colored("⚠️  Some preflight checks failed", Colors.WARNING)
        
        return all_passed
    
    def _check_project_structure(self) -> bool:
        """Check if project structure is valid"""
        required_paths = [
            self.flutter_project,
            self.flutter_project / "pubspec.yaml",
            self.flutter_project / "lib",
        ]
        
        for path in required_paths:
            if not path.exists():
                print(f"  Missing: {path}")
                return False
        
        return True
    
    def _check_flutter(self) -> bool:
        """Check Flutter installation"""
        return self.run_command(["flutter", "--version"], stream_output=False)
    
    def _check_flutter_doctor(self) -> bool:
        """Check Flutter doctor status"""
        return self.run_command(["flutter", "doctor"], stream_output=False)
    
    def _check_yaml_support(self) -> bool:
        """Check if YAML support is available"""
        if not HAS_YAML:
            print(f"  {Colors.WARNING}PyYAML not installed - using fallback version parsing{Colors.ENDC}")
        return True  # Not critical, we have fallback
    
    def run_flutter(self):
        """Run Flutter app in debug mode"""
        self.print_colored("🚀 Running Flutter app in debug mode...", Colors.HEADER)
        
        platform_suffix = "macos" if self.current_os == "darwin" else "windows" if self.current_os == "windows" else "linux"
        
        success = self.run_command(["flutter", "run", "-d", platform_suffix])
        
        if success:
            self.print_colored("✅ Flutter app started successfully", Colors.OKGREEN)
        else:
            self.print_colored("❌ Failed to start Flutter app", Colors.FAIL)
        
        return success
    
    def build_deploy_interactive(self):
        """Interactive build and deploy with options"""
        build_number = self.get_build_number()
        build_exists = (self.deploy_dir / build_number).exists()
        
        # Display current build info
        self.print_colored(f"\n🔨 Build and Deploy Configuration", Colors.HEADER)
        status = "(exists in deploy/ dir)" if build_exists else "(new build)"
        self.print_colored(f"BuildNumber: {build_number} {status}", Colors.OKBLUE)
        
        # Options configuration
        clean_flutter = False
        update_version = False
        copy_to_applications = False
        
        print(f"\n{Colors.BOLD}# Options{Colors.ENDC}")
        
        while True:
            clean_status = "ON" if clean_flutter else "OFF"
            version_status = "ON" if update_version else "OFF"
            apps_status = "ON" if copy_to_applications else "OFF"
            
            print(f"c. Run flutter clean before: {Colors.OKGREEN if clean_flutter else Colors.FAIL}{clean_status}{Colors.ENDC}")
            print(f"v. Update version number before building: {Colors.OKGREEN if update_version else Colors.FAIL}{version_status}{Colors.ENDC}")
            
            if self.current_os == "darwin":
                print(f"a. Copy to /Applications after build: {Colors.OKGREEN if copy_to_applications else Colors.FAIL}{apps_status}{Colors.ENDC}")
            
            print(f"\n{Colors.BOLD}# Tasks{Colors.ENDC}")
            print("1. Deploy Binaries to deploy/ folder (default)")
            print("q. Back to main menu")
            
            choice = input(f"\n{Colors.BOLD}Select option (c/v/a/1/q or press Enter for option 1): {Colors.ENDC}").strip().lower()
            
            if choice == "c":
                clean_flutter = not clean_flutter
            elif choice == "v":
                update_version = not update_version
            elif choice == "a" and self.current_os == "darwin":
                copy_to_applications = not copy_to_applications
            elif choice == "1" or choice == "":
                # Execute build with selected options
                return self._execute_build_deploy(build_number, clean_flutter, update_version, copy_to_applications)
            elif choice == "q":
                return False
            else:
                self.print_colored("❌ Invalid option. Try again.", Colors.FAIL)
    
    def _execute_build_deploy(self, build_number, clean_flutter, update_version, copy_to_applications):
        """Execute the build and deploy process with given options"""
        self.print_colored(f"\n🚀 Starting build process...", Colors.HEADER)
        
        # Update version if requested
        if update_version:
            if not self.bump_version():
                return False
            build_number = self.get_build_number()  # Get updated build number
        
        # Check/handle existing build directory
        if not self.check_build_directory(build_number):
            return False
        
        # Run flutter clean if requested
        if clean_flutter:
            self.print_colored("🧹 Running flutter clean...", Colors.OKCYAN)
            if not self.run_command(["flutter", "clean"]):
                self.print_colored("❌ Flutter clean failed", Colors.FAIL)
                return False
        
        # Create build directory structure
        platform_name = "macos" if self.current_os == "darwin" else "windows" if self.current_os == "windows" else "linux"
        build_dir = self.deploy_dir / build_number / platform_name / "bin"
        build_dir.mkdir(parents=True, exist_ok=True)
        
        # Build release
        build_command = ["flutter", "build"]
        if self.current_os == "darwin":
            build_command.append("macos")
        elif self.current_os == "windows":
            build_command.append("windows")
        else:
            build_command.append("linux")
        build_command.append("--release")
        
        if not self.run_command(build_command):
            self.print_colored("❌ Build failed", Colors.FAIL)
            return False
        
        # Copy build artifacts
        try:
            if self.current_os == "darwin":
                source_path = self.flutter_project / "build" / "macos" / "Build" / "Products" / "Release" / "mdtool.app"
                target_path = build_dir / "mdtool.app"
                shutil.copytree(source_path, target_path)
            elif self.current_os == "windows":
                source_dir = self.flutter_project / "build" / "windows" / "x64" / "runner" / "Release"
                for item in source_dir.iterdir():
                    if item.is_file():
                        shutil.copy2(item, build_dir)
                    else:
                        shutil.copytree(item, build_dir / item.name)
            else:  # linux
                source_dir = self.flutter_project / "build" / "linux" / "x64" / "release" / "bundle"
                for item in source_dir.iterdir():
                    if item.is_file():
                        shutil.copy2(item, build_dir)
                    else:
                        shutil.copytree(item, build_dir / item.name)
            
            # Create zip archive
            archive_name = f"MDTool_{platform_name}"
            archive_path = self.deploy_dir / build_number / f"{archive_name}.zip"
            
            shutil.make_archive(
                str(archive_path.with_suffix('')),
                'zip',
                str(build_dir.parent),
                'bin'
            )
            
            self.print_colored(f"✅ Build completed successfully!", Colors.OKGREEN)
            self.print_colored(f"📦 Binary deployed to: {build_dir}", Colors.OKBLUE)
            self.print_colored(f"🗜️  Archive created: {archive_path}", Colors.OKBLUE)
            
            # Copy to /Applications if requested (macOS only)
            if copy_to_applications and self.current_os == "darwin":
                try:
                    source_app = build_dir / "mdtool.app"
                    target_path = Path("/Applications/MDTool.app")
                    
                    # Remove existing app if present
                    if target_path.exists():
                        shutil.rmtree(target_path)
                    
                    shutil.copytree(source_app, target_path)
                    self.print_colored(f"📱 Successfully copied to {target_path}", Colors.OKGREEN)
                except Exception as e:
                    self.print_colored(f"❌ Failed to copy to Applications: {e}", Colors.FAIL)
            
            return True
            
        except Exception as e:
            self.print_colored(f"❌ Failed to deploy build: {e}", Colors.FAIL)
            return False
    
    
    def show_menu(self):
        """Display main menu and handle user input"""
        while True:
            self.print_colored("\n" + "="*60, Colors.HEADER)
            self.print_colored("🛠️  Enhanced MDTool Build System", Colors.HEADER)
            self.print_colored("="*60, Colors.HEADER)
            
            core_version, build_number = self.get_version_info()
            full_version = f"{core_version}+{build_number}"
            self.print_colored(f"Current Version: {full_version}", Colors.OKBLUE)
            self.print_colored(f"Platform: {platform.system()} ({platform.machine()})", Colors.OKBLUE)
            yaml_status = "✅ Full" if HAS_YAML else "⚠️  Fallback"
            self.print_colored(f"YAML Support: {yaml_status}", Colors.OKBLUE)
            
            print("\nAvailable Options:")
            print("1. Run (Debug Mode)")
            print("2. Build and Deploy (Interactive)")
            print("3. Version Management")
            print("4. Doctor (Preflight Checks)")
            print("5. Exit")
            
            choice = input(f"\n{Colors.BOLD}Select option (1-5): {Colors.ENDC}").strip()
            
            if choice == "1":
                self.run_flutter()
            elif choice == "2":
                self.build_deploy_interactive()
            elif choice == "3":
                self._version_management_menu()
            elif choice == "4":
                self.doctor()
                input(f"\n{Colors.OKBLUE}Press Enter to continue...{Colors.ENDC}")
            elif choice == "5":
                self.print_colored("👋 Goodbye!", Colors.OKGREEN)
                break
            else:
                self.print_colored("❌ Invalid option. Please try again.", Colors.FAIL)
    
    def _version_management_menu(self):
        """Version management submenu"""
        while True:
            core_version, build_number = self.get_version_info()
            full_version = f"{core_version}+{build_number}"
            
            self.print_colored(f"\n📝 Version Management", Colors.HEADER)
            self.print_colored(f"Current Version: {full_version}", Colors.OKBLUE)
            
            print("\nVersion Bump Options:")
            print("1. Bump Build Number (1.0.0+1 → 1.0.0+2)")
            print("2. Bump Patch Version (1.0.0 → 1.0.1)")
            print("3. Bump Minor Version (1.0.0 → 1.1.0)")
            print("4. Bump Major Version (1.0.0 → 2.0.0)")
            print("5. Set Custom Version")
            print("q. Back to main menu")
            
            choice = input(f"\n{Colors.BOLD}Select option: {Colors.ENDC}").strip().lower()
            
            if choice == "1":
                self.bump_version("build")
            elif choice == "2":
                self.bump_version("patch")
            elif choice == "3":
                self.bump_version("minor")
            elif choice == "4":
                self.bump_version("major")
            elif choice == "5":
                custom = input("Enter version (e.g., 2.1.0): ").strip()
                if custom:
                    self.bump_version(custom_version=custom)
            elif choice == "q":
                return
            else:
                self.print_colored("❌ Invalid option. Try again.", Colors.FAIL)


def create_cli_parser():
    """Create CLI argument parser"""
    import argparse
    
    parser = argparse.ArgumentParser(
        prog="buildtool",
        description="Enhanced Build Tool for MDTool Flutter App"
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Run command
    run_parser = subparsers.add_parser("run", help="Run Flutter app in debug mode")
    run_parser.add_argument("--platform", choices=["macos", "windows", "linux", "auto"], 
                           default="auto", help="Target platform")
    
    # Build command
    build_parser = subparsers.add_parser("build", help="Build and deploy")
    build_parser.add_argument("--clean", action="store_true", help="Run flutter clean first")
    build_parser.add_argument("--update-version", action="store_true", help="Bump version before build")
    build_parser.add_argument("--copy-to-apps", action="store_true", help="Copy to /Applications (macOS only)")
    build_parser.add_argument("--platform", choices=["macos", "windows", "linux", "auto"], 
                             default="auto", help="Target platform")
    
    # Version command
    version_parser = subparsers.add_parser("version", help="Version management")
    version_group = version_parser.add_mutually_exclusive_group()
    version_group.add_argument("--build", action="store_true", help="Bump build number")
    version_group.add_argument("--patch", action="store_true", help="Bump patch version")
    version_group.add_argument("--minor", action="store_true", help="Bump minor version")
    version_group.add_argument("--major", action="store_true", help="Bump major version")
    version_group.add_argument("--set", type=str, help="Set custom version (e.g., 2.1.0)")
    
    # Doctor command
    subparsers.add_parser("doctor", help="Run preflight checks")
    
    return parser


def main():
    """Main entry point with CLI and interactive support"""
    parser = create_cli_parser()
    
    # If no arguments provided, show interactive menu
    if len(sys.argv) == 1:
        try:
            if not HAS_YAML:
                print(f"{Colors.WARNING}⚠️  PyYAML not installed. Install with: pip install pyyaml{Colors.ENDC}")
                print(f"{Colors.WARNING}   (Fallback version parsing will be used){Colors.ENDC}")
            
            tool = BuildTool()
            tool.show_menu()
        except KeyboardInterrupt:
            print(f"\n{Colors.WARNING}Build cancelled by user{Colors.ENDC}")
            sys.exit(0)
        except Exception as e:
            print(f"{Colors.FAIL}Fatal error: {e}{Colors.ENDC}")
            sys.exit(1)
    else:
        # Handle CLI commands
        args = parser.parse_args()
        tool = BuildTool()
        
        try:
            if args.command == "run":
                platform = args.platform if args.platform != "auto" else tool.current_os
                success = tool.run_flutter()
                sys.exit(0 if success else 1)
            
            elif args.command == "build":
                # For CLI builds, execute directly with options
                success = tool._execute_build_deploy(
                    tool.get_build_number(),
                    clean_flutter=args.clean,
                    update_version=args.update_version,
                    copy_to_applications=args.copy_to_apps
                )
                sys.exit(0 if success else 1)
            
            elif args.command == "version":
                if args.set:
                    success = tool.bump_version(custom_version=args.set)
                elif args.major:
                    success = tool.bump_version("major")
                elif args.minor:
                    success = tool.bump_version("minor")
                elif args.patch:
                    success = tool.bump_version("patch")
                else:
                    success = tool.bump_version("build")  # Default
                
                sys.exit(0 if success else 1)
            
            elif args.command == "doctor":
                success = tool.doctor()
                sys.exit(0 if success else 1)
            
        except KeyboardInterrupt:
            print(f"\n{Colors.WARNING}Command cancelled by user{Colors.ENDC}")
            sys.exit(130)
        except Exception as e:
            print(f"{Colors.FAIL}Command failed: {e}{Colors.ENDC}")
            sys.exit(1)


if __name__ == "__main__":
    main()