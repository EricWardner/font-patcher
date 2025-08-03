# Font Patcher

A simple Nix flake for patching fonts with custom glyphs using FontForge.

## Usage

### As a Flake Input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    font-patcher.url = "github:youruser/font-patcher"; # or path:./font-patcher
  };

  outputs = { nixpkgs, font-patcher, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Create a patched font
      my-patched-font = font-patcher.lib.${system}.patchFont {
        baseFont = pkgs.cascadia-code;
        svgGlyph = ./my-custom-glyph.svg;
        unicodePoint = "0x2AF8";
      };
    in {
      # Use in home-manager, etc.
    };
}
```

### In Home Manager

```nix
{
  stylix = {
    fonts = {
      monospace = {
        package = inputs.my-patched-font;
        name = "Cascadia Code NF";
      };
    };
  };
}
```

## Parameters

- `baseFont`: The base font package from nixpkgs (e.g., `pkgs.cascadia-code`)
- `svgGlyph`: Path to your custom SVG glyph file
- `unicodePoint`: Unicode codepoint as a string (e.g., `"0x2AF8"` or `"11000"`)
- `name` (optional): Override the font name

## Examples

```nix
# Patch JetBrains Mono with a custom prompt glyph
jetbrains-patched = font-patcher.lib.${system}.patchFont {
  baseFont = pkgs.jetbrains-mono;
  svgGlyph = ./prompt-glyph.svg;
  unicodePoint = "0x2AF8";
};

# Patch Fira Code with a custom icon
fira-patched = font-patcher.lib.${system}.patchFont {
  baseFont = pkgs.fira-code;
  svgGlyph = ./custom-icon.svg;
  unicodePoint = "0xE000"; # Private Use Area
};
```

## Requirements

- Nix with flakes enabled
- SVG file for your custom glyph
- Base font package from nixpkgs

The flake automatically handles FontForge and Python dependencies.