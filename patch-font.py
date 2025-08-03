#!/usr/bin/env python3

import fontforge
import sys

if len(sys.argv) != 5:
    print("Usage: patch-font.py <input-font> <unicode-codepoint> <svg-file> <output-font>")
    print("Example: patch-font.py input.ttf 0x2AF8 uni2AF8_GW.svg output.ttf")
    sys.exit(1)

input_font = sys.argv[1]
codepoint = int(sys.argv[2], 16) if sys.argv[2].startswith('0x') else int(sys.argv[2])
svg_file = sys.argv[3]
output_font = sys.argv[4]

font = fontforge.open(input_font)
glyph = font[codepoint]
glyph.clear()
glyph.importOutlines(svg_file)
font.generate(output_font)
font.close()