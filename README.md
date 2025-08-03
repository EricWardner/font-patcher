# 🎨 Universal Font Patcher

A Nix flake that lets you add any SVG glyph to any font. Perfect for custom terminal prompts, branding, or adding missing symbols to your favorite fonts.

## ✨ Features

- **Universal**: Works with any font format (TTF, OTF, WOFF, WOFF2)
- **Flexible**: Use any SVG glyph at any Unicode point
- **Reproducible**: Nix-based builds ensure consistent results
- **Cacheable**: Built fonts can be cached and shared
- **Metadata**: Includes patch information for tracking

## 🚀 Quick Start

### Basic Usage

```nix
{
  inputs.font-patcher.url = "github:yourusername/font-patcher";
  
  outputs = { font-patcher, nixpkgs, ... }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    
    myPatchedFont = font-patcher.lib.x86_64-linux.patchFont {
      baseFont = pkgs.cascadia-code;
      svgGlyph = ./my-custom-glyph.svg;
      unicodePoint = "0x2AF8";
      fontName = "cascadia-code-custom";  # optional
    };
  in {
    packages.x86_64-linux.my-font = myPatchedFont;
  };
}
```

### Home Manager Integration

```nix
{ pkgs, inputs, ... }:
let
  customFont = inputs.font-patcher.lib.${pkgs.system}.patchFont {
    baseFont = pkgs.jetbrains-mono;
    svgGlyph = ./company-logo.svg;
    unicodePoint = "0xE0B0";
    fontName = "jetbrains-mono-branded";
  };
in
{
  home.packages = [ customFont ];
  
  programs.kitty.font = {
    name = "JetBrains Mono Branded";
    package = customFont;
  };
}
```

## 📖 API Reference

### `patchFont` Function

```nix
patchFont {
  # Required
  baseFont      # Font package to patch (from nixpkgs or custom)
  svgGlyph      # Path to SVG file (e.g., ./my-glyph.svg)
  unicodePoint  # Unicode point as string (e.g., "0x2AF8", "0xE0A0")
  
  # Optional
  fontName      # Custom output name (default: auto-generated)
  glyphName     # Glyph name in font (default: based on unicode point)
}
```

### `patchFontSimple` Function

Shorthand for basic patching:

```nix
patchFontSimple pkgs.fira-code ./glyph.svg "0x2AF8"
```

## 🎯 Use Cases

### Terminal Prompts
```nix
# Add custom prompt symbol
myPromptFont = font-patcher.lib.${system}.patchFont {
  baseFont = pkgs.cascadia-code;
  svgGlyph = ./prompt-arrow.svg;
  unicodePoint = "0x2AF8";
};
```

### Corporate Branding
```nix
# Add company logo to font
brandedFont = font-patcher.lib.${system}.patchFont {
  baseFont = pkgs.source-code-pro;
  svgGlyph = ./company-logo.svg;
  unicodePoint = "0xE000";  # Private Use Area
  fontName = "source-code-pro-corporate";
};
```

### Missing Symbols
```nix
# Add missing mathematical symbol
mathFont = font-patcher.lib.${system}.patchFont {
  baseFont = pkgs.libertine;
  svgGlyph = ./integral-symbol.svg;
  unicodePoint = "0x222B";
};
```

## 📁 Project Structure

```
font-patcher/
├── flake.nix              # Main flake definition
├── README.md              # This file
├── examples/
│   └── sample-glyph.svg   # Example SVG glyph
├── templates/
│   ├── basic/             # Basic usage template
│   └── advanced/          # Advanced usage template
└── docs/
    ├── svg-guidelines.md  # SVG creation guidelines
    └── unicode-ranges.md  # Unicode point recommendations
```

## 🎨 SVG Guidelines

### Best Practices
- Use vector paths, not rasterized images
- Design on a 1000x1000 unit canvas
- Keep stroke widths consistent with font weight
- Test at multiple sizes (12pt, 16pt, 24pt)
- Ensure good contrast at small sizes

### Technical Requirements
- SVG must be valid XML
- Avoid external dependencies (fonts, images)
- Use black fills (#000000) for normal weight
- Consider font metrics (ascender, descender, x-height)

## 🔢 Unicode Point Recommendations

### Safe Ranges
- **Private Use Area**: `0xE000-0xF8FF` (safe, won't conflict)
- **Supplemental Private Use Area-
