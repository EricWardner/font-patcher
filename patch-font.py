#!/usr/bin/env python3

import fontforge
import argparse
import argcomplete
from argcomplete.completers import FilesCompleter
import os
import shutil
import sys


def patch_font(input_font, codepoint_str, svg_file, output_font):
    if not os.path.exists(input_font):
        print(f"Error: Input font '{input_font}' not found")
        sys.exit(1)

    if not os.path.exists(svg_file):
        print(f"Error: SVG file '{svg_file}' not found")
        sys.exit(1)

    try:
        codepoint = int(codepoint_str, 16) if codepoint_str.startswith("0x") else int(codepoint_str)
        print(f"Looking for glyph at codepoint: {codepoint} (0x{codepoint:X})")
    except ValueError:
        print(f"Error: Invalid codepoint '{codepoint_str}'")
        sys.exit(1)

    try:
        print(f"Opening font: {input_font}")
        font = fontforge.open(input_font)

        if codepoint not in font:
            print(f"Glyph at codepoint {codepoint} (0x{codepoint:X}) not found in font. Copying original font unchanged.")
            shutil.copy2(input_font, output_font)
            return

        print(f"Found existing glyph at codepoint {codepoint}, patching...")
        glyph = font[codepoint]
        glyph.clear()
        print(f"Importing SVG: {svg_file}")
        glyph.importOutlines(svg_file)

        print(f"Generating patched font: {output_font}")
        font.generate(output_font)
        print("Font patching completed successfully!")

    except Exception as e:
        print(f"Error during font patching: {e}")
        sys.exit(1)
    finally:
        try:
            font.close()
        except Exception:
            pass


def main():
    parser = argparse.ArgumentParser(description="Patch a font by replacing a glyph with an SVG outline.")
    parser.add_argument("input_font", help="Path to input font (TTF or OTF)").completer = FilesCompleter([".ttf", ".otf"])
    parser.add_argument("codepoint", help="Unicode codepoint (e.g. 0x2AF8 or 10936)")
    parser.add_argument("svg_file", help="Path to SVG file").completer = FilesCompleter([".svg"])
    parser.add_argument("output_font", help="Path to output patched font (TTF)").completer = FilesCompleter([".ttf"])

    # Enable argcomplete
    argcomplete.autocomplete(parser)

    args = parser.parse_args()

    patch_font(
        input_font=args.input_font,
        codepoint_str=args.codepoint,
        svg_file=args.svg_file,
        output_font=args.output_font,
    )


if __name__ == "__main__":
    main()
