# Font Patcher

Nix flake for patching fonts with custom SVG glyphs using FontForge.

## Usage

### As a Flake Input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    font-patcher.url = "github:ericwardner/font-patcher";
    # ... other inputs
  };

  outputs = { nixpkgs, font-patcher, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        "username" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home.nix ];
        };
      };
    };
}
```

### In Home Manager Configuration

Use the font-patcher directly in your home.nix:

```nix
{ pkgs, inputs, ... }:
let
  cascadia-code-patched = inputs.font-patcher.lib.${pkgs.system}.patchFont {
    baseFont = pkgs.cascadia-code;
    svgGlyph = ./themes/custom-glyph.svg;
    unicodePoint = "0x276F";  # Your chosen Unicode point
  };
in
{
  stylix = {
    fonts = {
      monospace = {
        package = cascadia-code-patched;
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
- `name` (optional): Custom name for the derivation (defaults to base font name)

## Examples

```nix
# Patch Cascadia Code with a custom prompt glyph (as shown in real usage)
cascadia-code-gw = inputs.font-patcher.lib.${pkgs.system}.patchFont {
  baseFont = pkgs.cascadia-code;
  svgGlyph = ./themes/uni2AF8_GW.svg;
  unicodePoint = "0x276F";  # HEAVY RIGHT-POINTING ANGLE QUOTATION MARK ORNAMENT
};

# Patch JetBrains Mono with a custom icon
jetbrains-patched = inputs.font-patcher.lib.${pkgs.system}.patchFont {
  baseFont = pkgs.jetbrains-mono;
  svgGlyph = ./custom-icon.svg;
  unicodePoint = "0xE000";  # Private Use Area
};

# Use with multiple font packages
stylix = {
  fonts = {
    monospace = {
      package = cascadia-code-gw;
      name = "Cascadia Code NF";
    };
    
    # You can use other fonts alongside patched ones
    serif = {
      package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
      name = "SFProText Nerd Font";
    };
  };
};
```

## Notes

- The patcher preserves the original font directory structure (truetype, opentype, etc.)
- All font variants in the package (regular, bold, italic, etc.) will be patched, if the glyph exists
- The glyph is added to the specified Unicode codepoint in each font file
- The patched font retains all original metadata

## Requirements

- Nix with flakes enabled
- SVG file for your custom glyph
- Base font package from nixpkgs

The flake automatically handles FontForge and Python dependencies.
