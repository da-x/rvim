#!/usr/bin/env python3
"""
Custom GCC/G++ linter for Neovim
Wraps GCC/G++ compilation and outputs diagnostics in JSON format
"""

import sys
import json
import subprocess
import os
import re
from pathlib import Path

# Enable debug mode with environment variable
DEBUG = os.getenv('GCC_LINTER_DEBUG', '').lower() in ('1', 'true', 'yes')

def debug_print(*args, **kwargs):
    """Print debug messages to stderr if debug mode is enabled"""
    if DEBUG:
        print(*args, file=sys.stderr, **kwargs)


def detect_compiler(filepath):
    """Detect whether to use gcc or g++ based on file extension"""
    ext = Path(filepath).suffix.lower()
    if ext in ['.cpp', '.cxx', '.cc', '.c++']:
        compiler = 'g++'
    elif ext in ['.c']:
        compiler = 'gcc'
    else:
        compiler = 'gcc'  # fallback
    
    debug_print(f"Detected compiler: {compiler} for file: {filepath} (ext: {ext})")
    return compiler


def parse_gcc_output(output, filepath):
    """Parse GCC/G++ error output into structured diagnostics"""
    diagnostics = []
    debug_print(f"Parsing compiler output for {filepath}:")
    debug_print(f"Raw output:\n{output}")

    # GCC output pattern: filename:line:column: severity: message
    pattern = r'^([^:]+):(\d+):(\d+):\s*(fatal error|error|warning|note):\s*(.*)$'

    for line in output.split('\n'):
        line = line.strip()
        if not line:
            continue

        debug_print(f"Processing line: {line}")
        match = re.match(pattern, line)
        if match:
            file, line_num, col_num, severity, message = match.groups()
            debug_print(f"Matched: file={file}, line={line_num}, col={col_num}, severity={severity}, message={message}")

            # Only include diagnostics for the current file
            if os.path.samefile(file, filepath) if os.path.exists(file) else file == filepath:
                diagnostic = {
                    'line': int(line_num),
                    'column': int(col_num),
                    'severity': severity,
                    'message': message.strip()
                }
                diagnostics.append(diagnostic)
                debug_print(f"Added diagnostic: {diagnostic}")
            else:
                debug_print(f"Skipped diagnostic for different file: {file}")
        else:
            debug_print(f"Line didn't match pattern: {line}")

    debug_print(f"Total diagnostics found: {len(diagnostics)}")
    return diagnostics


def run_gcc_check(filepath):
    """Run GCC/G++ syntax check on the given file"""
    compiler = detect_compiler(filepath)

    # Basic compilation flags - customize as needed
    cmd = [
        compiler,
        '-fsyntax-only',  # Only check syntax, don't generate output
        '-Wall',          # Enable common warnings
        '-Wextra',        # Enable extra warnings
        '-std=c++17' if compiler == 'g++' else '-std=c11',  # Set C++ or C standard
        filepath
    ]

    debug_print(f"Running command: {' '.join(cmd)}")

    try:
        # Run the compiler
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
        )

        debug_print(f"Command exit code: {result.returncode}")
        debug_print(f"Command stdout: {result.stdout}")
        debug_print(f"Command stderr: {result.stderr}")

        # Parse both stdout and stderr (GCC usually outputs to stderr)
        output = result.stderr + result.stdout
        diagnostics = parse_gcc_output(output, filepath)

        return diagnostics

    except subprocess.SubprocessError as e:
        debug_print(f"SubprocessError: {e}")
        return [{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': f'Failed to run {compiler}: {str(e)}'
        }]
    except Exception as e:
        debug_print(f"Exception: {e}")
        return [{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': f'Linter error: {str(e)}'
        }]


def main():
    # nvim-lint passes the filename as the first argument after the script name
    debug_print(f"gcc_linter.py started with args: {sys.argv}")
    debug_print(f"Debug mode: {'enabled' if DEBUG else 'disabled'}")
    
    if len(sys.argv) != 2:
        error_msg = f'Usage: gcc_linter.py <filepath> (got {len(sys.argv)} args: {sys.argv})'
        debug_print(f"Error: {error_msg}")
        print(json.dumps([{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': error_msg
        }]))
        sys.exit(1)

    filepath = sys.argv[1]
    debug_print(f"Processing file: {filepath}")

    if not os.path.exists(filepath):
        debug_print(f"File not found: {filepath}")
        print(json.dumps([]))
        sys.exit(0)

    # Run the linting
    diagnostics = run_gcc_check(filepath)

    # Output JSON for nvim-lint to parse
    debug_print(f"Final output: {json.dumps(diagnostics, indent=2)}")
    print(json.dumps(diagnostics))


if __name__ == '__main__':
    main()
