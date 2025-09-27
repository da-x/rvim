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


def find_container_file(start_path):
    """Find .container file in parent directories"""
    current = Path(start_path).resolve()
    while current != current.parent:
        container_file = current / '.container'
        if container_file.exists():
            debug_print(f"Found .container file: {container_file}")
            return container_file
        current = current.parent
    debug_print("No .container file found")
    return None


def infer_kernel_working_dir(cmd_parts):
    """Infer kernel working directory from kconfig.h include path"""
    for i, part in enumerate(cmd_parts):
        if part == '-include' and i + 1 < len(cmd_parts):
            include_path = cmd_parts[i + 1]
            if include_path.endswith('/include/linux/kconfig.h'):
                kernel_root = include_path[:-len('/include/linux/kconfig.h')]
                debug_print(f"Inferred kernel working directory: {kernel_root}")
                return kernel_root
        elif part.startswith('-include') and '/include/linux/kconfig.h' in part:
            # Handle -include/path/to/kconfig.h format
            include_path = part[8:]  # Remove '-include' prefix
            if include_path.endswith('/include/linux/kconfig.h'):
                kernel_root = include_path[:-len('/include/linux/kconfig.h')]
                debug_print(f"Inferred kernel working directory: {kernel_root}")
                return kernel_root

    debug_print("Could not infer kernel working directory from kconfig.h")
    return None


def parse_kernel_cmd_file(filepath):
    """Parse .{filename}.o.cmd file for kernel module compilation flags"""
    cmd_file = Path(filepath).parent / f".{Path(filepath).stem}.o.cmd"
    debug_print(f"Looking for kernel cmd file: {cmd_file}")

    if not cmd_file.exists():
        debug_print(f"Kernel cmd file not found: {cmd_file}")
        return None

    debug_print(f"Found kernel cmd file: {cmd_file}")
    try:
        with open(cmd_file, 'r') as f:
            content = f.read()

        # Look for line matching: cmd_.* := .* gcc .*
        pattern = r'^(saved)?cmd_.*:=\s*(.*?\s+gcc\s+.*)$'
        for line in content.splitlines():
            match = re.match(pattern, line)
            if match:
                cmd_line = match.group(2).strip()
                debug_print(f"Found kernel build command: {cmd_line}")
                return cmd_line

        debug_print("No gcc command found in kernel cmd file")
        return None
    except Exception as e:
        debug_print(f"Error reading kernel cmd file: {e}")
        return None


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
    # Check for kernel module compilation first
    kernel_cmd = parse_kernel_cmd_file(filepath)

    if kernel_cmd:
        # Use kernel build command, but modify for syntax checking
        debug_print("Using kernel module compilation mode")

        # Parse the kernel command to extract flags
        cmd_parts = kernel_cmd.split()

        # Find gcc in the command and build our syntax-only version
        gcc_idx = -1
        for i, part in enumerate(cmd_parts):
            if 'gcc' in part and not part.startswith('-'):
                gcc_idx = i
                break

        if gcc_idx == -1:
            debug_print("Could not find gcc in kernel command")
            return [{
                'line': 1,
                'column': 1,
                'severity': 'error',
                'message': 'Could not find gcc in kernel build command'
            }]

        # Infer kernel working directory
        kernel_workdir = infer_kernel_working_dir(cmd_parts)

        # Use the kernel command as-is, but replace -c with -fsyntax-only
        cmd = []
        skip_next = False
        for i, flag in enumerate(cmd_parts):
            if skip_next:
                skip_next = False
                continue

            # Replace -c with -fsyntax-only
            if flag == '-c':
                cmd.append('-fsyntax-only')
                continue

            # Skip -o and its argument
            if flag == '-o':
                skip_next = True
                continue

            # Skip -o combined with argument
            if flag.startswith('-o') and flag != '-o':
                continue

            if flag.endswith("'"):
                debug_print("Adjusting flag: {}", repr(flag))
                flag = flag.replace("'", "")

            cmd.append(flag)

        # Add -fsyntax-only if we didn't find -c to replace
        if '-fsyntax-only' not in cmd:
            cmd.insert(gcc_idx + 1, '-fsyntax-only')

    else:
        # Standard compilation mode
        debug_print("Using standard compilation mode")
        compiler = detect_compiler(filepath)

        cmd = [
            compiler,
            '-fsyntax-only',  # Only check syntax, don't generate output
            '-Wall',          # Enable common warnings
            '-Wextra',        # Enable extra warnings
            '-std=c++17' if compiler == 'g++' else '-std=c11',  # Set C++ or C standard
            filepath
        ]

    # Check for Docker container execution
    container_file = find_container_file(filepath)
    if container_file:
        try:
            with open(container_file, 'r') as f:
                container_name = f.read().strip()
            debug_print(f"Using Docker container: {container_name}")

            # Build docker exec command with working directory if available
            docker_cmd = ['docker', 'exec']
            if kernel_cmd and 'kernel_workdir' in locals() and kernel_workdir:
                docker_cmd.extend(['-w', kernel_workdir])
                debug_print(f"Setting Docker working directory: {kernel_workdir}")
            docker_cmd.append(container_name)
            cmd = docker_cmd + cmd
        except Exception as e:
            debug_print(f"Error reading container file: {e}")

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
            'message': f'Failed to run compiler: {str(e)}'
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
