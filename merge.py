#!/usr/bin/env python3

import os
import argparse
import sys

def merge_sv_files(input_dir, output_file):
    """
    Walks through a directory, finds all .sv and .svh files,
    and merges their content into a single output file.

    Args:
        input_dir (str): The path to the directory to scan.
        output_file (str): The path to the file where merged content will be saved.
    """
    if not os.path.isdir(input_dir):
        print(f"Error: Input directory '{input_dir}' not found or is not a directory.")
        sys.exit(1)

    print(f"Scanning directory: {input_dir}")
    print(f"Output file: {output_file}")

    merged_content = []
    file_count = 0

    try:
        with open(output_file, 'w', encoding='utf-8') as outfile:
            for root, _, files in os.walk(input_dir):
                # Sort files for consistent order (optional but good practice)
                files.sort()
                for filename in files:
                    if filename.endswith((".sv", ".svh", ".tcl")):
                        file_path = os.path.join(root, filename)
                        relative_path = os.path.relpath(file_path, input_dir)
                        print(f"  Adding: {relative_path}")

                        try:
                            # Write the file name comment
                            outfile.write(f"// ---- File: {relative_path} ----\n")

                            # Write the file content
                            with open(file_path, 'r', encoding='utf-8', errors='ignore') as infile:
                                content = infile.read()
                                outfile.write(content)

                            # Add a newline separator between files for clarity
                            outfile.write("\n\n")
                            file_count += 1

                        except IOError as e:
                            print(f"Warning: Could not read file {file_path}: {e}")
                        except Exception as e:
                            print(f"Warning: An unexpected error occurred processing file {file_path}: {e}")

        print(f"\nSuccessfully merged {file_count} files into {output_file}")

    except IOError as e:
        print(f"Error: Could not write to output file {output_file}: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during output file writing: {e}")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Merge all .sv and .svh files in a directory tree into a single file."
    )
    parser.add_argument(
        "-d",
        "--directory",
        required=True,
        help="The input directory to scan recursively.",
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="The path for the merged output file.",
    )

    args = parser.parse_args()
    merge_sv_files(args.directory, args.output)
