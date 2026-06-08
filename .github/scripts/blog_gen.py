#!/usr/bin/env python3
"""
Blog Generator for Letter to Blog Pipeline
Converts .memory/*.md files into polished blog posts using Anthropic API

API Key Resolution Order:
1. Environment variable ANTHROPIC_API_KEY (for CI/CD)
2. Project config: ./.letter-config.json
3. Global config: ~/.config/letter-for-my-future-self/config.json
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Defer heavy imports until needed (allows --help, --status without dependencies)
anthropic = None
def _load_anthropic():
    global anthropic
    if anthropic is None:
        try:
            import anthropic as _anthropic
            anthropic = _anthropic
        except ImportError:
            print("❌ anthropic package not installed")
            print("   Run: pip install anthropic")
            sys.exit(1)
    return anthropic

# Load .env if available (optional)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # dotenv is optional

# Config file names
PROJECT_CONFIG = ".letter-config.json"
GLOBAL_CONFIG_DIR = Path.home() / ".config" / "letter-for-my-future-self"
GLOBAL_CONFIG = GLOBAL_CONFIG_DIR / "config.json"


def get_api_key() -> str | None:
    """
    Resolve API key with priority:
    1. Environment variable (CI/CD, explicit override)
    2. Project config (.letter-config.json in current dir)
    3. Global config (~/.config/letter-for-my-future-self/config.json)
    """
    # 1. Environment variable (highest priority)
    env_key = os.getenv('ANTHROPIC_API_KEY')
    if env_key:
        print("🔑 Using API key from environment variable")
        return env_key

    # 2. Project-level config
    project_config = Path(PROJECT_CONFIG)
    if project_config.exists():
        try:
            config = json.loads(project_config.read_text())
            if config.get('anthropic_api_key'):
                print("🔑 Using API key from project config (.letter-config.json)")
                return config['anthropic_api_key']
        except (json.JSONDecodeError, KeyError) as e:
            print(f"⚠️  Warning: Could not read project config: {e}")

    # 3. Global config
    if GLOBAL_CONFIG.exists():
        try:
            config = json.loads(GLOBAL_CONFIG.read_text())
            if config.get('anthropic_api_key'):
                print("🔑 Using API key from global config (~/.config/letter-for-my-future-self/)")
                return config['anthropic_api_key']
        except (json.JSONDecodeError, KeyError) as e:
            print(f"⚠️  Warning: Could not read global config: {e}")

    return None


def setup_api_key(scope: str = "global"):
    """Interactive setup for API key configuration"""
    print("\n🔧 Letter to My Future Self - API Key Setup\n")

    api_key = input("Enter your Anthropic API key: ").strip()

    if not api_key:
        print("❌ No API key provided")
        sys.exit(1)

    if scope == "project":
        config_path = Path(PROJECT_CONFIG)
        config = {}
        if config_path.exists():
            config = json.loads(config_path.read_text())
        config['anthropic_api_key'] = api_key
        config_path.write_text(json.dumps(config, indent=2))
        print(f"✅ API key saved to {PROJECT_CONFIG}")
        print(f"⚠️  Add '{PROJECT_CONFIG}' to your .gitignore!")
    else:
        GLOBAL_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        config = {}
        if GLOBAL_CONFIG.exists():
            config = json.loads(GLOBAL_CONFIG.read_text())
        config['anthropic_api_key'] = api_key
        GLOBAL_CONFIG.write_text(json.dumps(config, indent=2))
        os.chmod(GLOBAL_CONFIG, 0o600)  # Restrict permissions
        print(f"✅ API key saved to {GLOBAL_CONFIG}")

    print("\n🎉 Setup complete! You can now run the blog generator.")


def show_config_status():
    """Show current API key configuration status"""
    print("\n📋 API Key Configuration Status\n")

    # Check environment
    env_key = os.getenv('ANTHROPIC_API_KEY')
    if env_key:
        print(f"  ✅ Environment: ANTHROPIC_API_KEY is set (ends with ...{env_key[-4:]})")
    else:
        print("  ❌ Environment: ANTHROPIC_API_KEY not set")

    # Check project config
    project_config = Path(PROJECT_CONFIG)
    if project_config.exists():
        try:
            config = json.loads(project_config.read_text())
            if config.get('anthropic_api_key'):
                key = config['anthropic_api_key']
                print(f"  ✅ Project: {PROJECT_CONFIG} (ends with ...{key[-4:]})")
            else:
                print(f"  ⚠️  Project: {PROJECT_CONFIG} exists but no API key")
        except:
            print(f"  ❌ Project: {PROJECT_CONFIG} exists but is invalid")
    else:
        print(f"  ❌ Project: {PROJECT_CONFIG} not found")

    # Check global config
    if GLOBAL_CONFIG.exists():
        try:
            config = json.loads(GLOBAL_CONFIG.read_text())
            if config.get('anthropic_api_key'):
                key = config['anthropic_api_key']
                print(f"  ✅ Global: {GLOBAL_CONFIG} (ends with ...{key[-4:]})")
            else:
                print(f"  ⚠️  Global: {GLOBAL_CONFIG} exists but no API key")
        except:
            print(f"  ❌ Global: {GLOBAL_CONFIG} exists but is invalid")
    else:
        print(f"  ❌ Global: {GLOBAL_CONFIG} not found")

    print("\n  Priority: Environment > Project > Global\n")


def get_memory_file(file_path: str | None = None):
    """Find a memory file - either specified or the most recent"""
    import re
    memory_dir = Path(os.path.abspath('.memory'))

    if not memory_dir.exists():
        print("❌ .memory/ directory not found")
        sys.exit(1)

    # If a specific file is requested
    if file_path:
        # Check if it's just a filename or a full path
        if os.path.isabs(file_path):
            target = Path(file_path)
        else:
            target = memory_dir / file_path

        if not target.exists():
            print(f"❌ File not found: {target}")
            sys.exit(1)
        return target

    # Find all letter files matching either format:
    # - Old: letter_XXXX.md (e.g., letter_0001.md)
    # - New: letter_YYYYMMDD_XXXX.md (e.g., letter_20260130_0001.md)
    letter_files = []
    for f in memory_dir.glob('letter_*.md'):
        # New format: letter_YYYYMMDD_XXXX.md
        match = re.match(r'letter_(\d{8})_(\d{4})\.md$', f.name)
        if match:
            # Sort key: date + counter as a single sortable string
            sort_key = f"{match.group(1)}_{match.group(2)}"
            letter_files.append((sort_key, f))
            continue

        # Old format: letter_XXXX.md (zero-padded or not)
        match = re.match(r'letter_(\d+)\.md$', f.name)
        if match:
            # Prefix with zeros to sort after new format
            sort_key = f"00000000_{int(match.group(1)):04d}"
            letter_files.append((sort_key, f))

    if not letter_files:
        print("❌ No numbered letter files found in .memory/")
        sys.exit(1)

    # Sort by key descending, return highest (newest)
    letter_files.sort(key=lambda x: x[0], reverse=True)
    return letter_files[0][1]


def generate_blog_post(memory_content: str) -> str:
    """Use Anthropic API to convert memory file to blog post"""
    api_key = get_api_key()

    if not api_key:
        print("❌ No API key found!")
        print("\nTo set up your API key, run one of:")
        print("  python blog_gen.py --setup         # Global (all projects)")
        print("  python blog_gen.py --setup-project # This project only")
        print("\nOr set the ANTHROPIC_API_KEY environment variable.")
        sys.exit(1)

    _load_anthropic()
    client = anthropic.Anthropic(api_key=api_key)

    prompt = f"""You are a technical blog writer. Convert this development session memory into an engaging, public-ready blog post.

INPUT (Session Memory):
{memory_content}

REQUIREMENTS:
1. Transform technical decisions into narrative insights
2. Keep the "Pain Log" as "Lessons Learned" or "Challenges"
3. Make it readable for a general developer audience
4. Add markdown frontmatter with: title, date, tags, excerpt
5. Use proper markdown formatting with headers, code blocks, lists
6. Maintain technical accuracy but improve readability

OUTPUT FORMAT:
---
title: "[Engaging Title]"
date: {datetime.now().strftime('%Y-%m-%d')}
tags: [relevant, tags, here]
excerpt: "Brief summary of the post"
---

[Blog post content in markdown]

Generate the blog post now:"""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    return message.content[0].text


def save_blog_post(content: str, source_file: Path):
    """Save generated blog post to drafts/"""
    drafts_dir = Path(os.path.abspath('drafts'))
    drafts_dir.mkdir(exist_ok=True)

    # Generate filename based on source
    timestamp = datetime.now().strftime('%Y-%m-%d')
    output_file = drafts_dir / f"blog_{timestamp}_{source_file.stem}.md"

    output_file.write_text(content, encoding='utf-8')
    print(f"✅ Blog post generated: {output_file}")
    return output_file


def main():
    """Main execution flow with CLI argument handling"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Letter to Blog Blog Generator - Convert session memories to blog posts",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python blog_gen.py                  # Generate blog from latest memory
  python blog_gen.py --file letter_20260130_0001.md  # Generate from specific file
  python blog_gen.py --setup          # Set up global API key
  python blog_gen.py --setup-project  # Set up project-specific API key
  python blog_gen.py --status         # Show API key configuration
        """
    )
    parser.add_argument('--file', '-f', type=str,
                        help='Specific memory file to convert (filename or full path)')
    parser.add_argument('--setup', action='store_true',
                        help='Set up global API key (~/.config/letter-for-my-future-self/)')
    parser.add_argument('--setup-project', action='store_true',
                        help='Set up project-specific API key (.letter-config.json)')
    parser.add_argument('--status', action='store_true',
                        help='Show current API key configuration status')

    args = parser.parse_args()

    # Handle setup commands
    if args.setup:
        setup_api_key(scope="global")
        return
    if args.setup_project:
        setup_api_key(scope="project")
        return
    if args.status:
        show_config_status()
        return

    # Normal blog generation flow
    print("🎨 Letter to Blog: Generating blog post...")

    # Get memory file (specific or latest)
    memory_file = get_memory_file(args.file)
    print(f"📖 Reading: {memory_file}")

    # Read content
    memory_content = memory_file.read_text(encoding='utf-8')

    # Generate blog post
    print("🤖 Calling Anthropic API...")
    blog_content = generate_blog_post(memory_content)

    # Save to drafts
    output_file = save_blog_post(blog_content, memory_file)

    print(f"✅ Success! Blog post saved to: {output_file}")
    print("🚀 Ready for review and publishing!")


if __name__ == "__main__":
    main()
