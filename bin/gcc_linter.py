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


def detect_compiler(filepath):
    """Detect whether to use gcc or g++ based on file extension"""
    ext = Path(filepath).suffix.lower()
    if ext in ['.cpp', '.cxx', '.cc', '.c++']:
        return 'g++'
    elif ext in ['.c']:
        return 'gcc'
    else:
        return 'gcc'  # fallback


def parse_gcc_output(output, filepath):
    """Parse GCC/G++ error output into structured diagnostics"""
    diagnostics = []
    
    # GCC output pattern: filename:line:column: severity: message
    pattern = r'^([^:]+):(\d+):(\d+):\s*(error|warning|note):\s*(.*)$'
    
    for line in output.split('\n'):
        line = line.strip()
        if not line:
            continue
            
        match = re.match(pattern, line)
        if match:
            file, line_num, col_num, severity, message = match.groups()
            
            # Only include diagnostics for the current file
            if os.path.samefile(file, filepath) if os.path.exists(file) else file == filepath:
                diagnostics.append({
                    'line': int(line_num),
                    'column': int(col_num),
                    'severity': severity,
                    'message': message.strip()
                })
    
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
    
    try:
        # Run the compiler
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=os.path.dirname(filepath) or '.'
        )
        
        # Parse both stdout and stderr (GCC usually outputs to stderr)
        output = result.stderr + result.stdout
        diagnostics = parse_gcc_output(output, filepath)
        
        return diagnostics
        
    except subprocess.SubprocessError as e:
        return [{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': f'Failed to run {compiler}: {str(e)}'
        }]
    except Exception as e:
        return [{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': f'Linter error: {str(e)}'
        }]


def main():
    # nvim-lint passes the filename as the first argument after the script name
    if len(sys.argv) != 2:
        print(json.dumps([{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': f'Usage: gcc_linter.py <filepath> (got {len(sys.argv)} args: {sys.argv})'
        }]))
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    if not os.path.exists(filepath):
        print(json.dumps([{
            'line': 1,
            'column': 1,
            'severity': 'error',
            'message': f'File not found: {filepath}'
        }]))
        sys.exit(1)
    
    # Run the linting
    diagnostics = run_gcc_check(filepath)
    
    # Output JSON for nvim-lint to parse
    print(json.dumps(diagnostics))


if __name__ == '__main__':
    main()