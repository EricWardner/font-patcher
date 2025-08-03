{
  description = "Example font patching with font-patcher";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    font-patcher.url = "github:yourusername/font-patcher";
  };

  outputs = { self, nixpkgs, font-patcher }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        # Example 1: Simple terminal prompt font
        my-terminal-font = font-patcher.lib.${system}.patchFont {
          baseFont = pkgs.cascadia-code;
          svgGlyph = ./my-prompt-glyph.svg;
          unicodePoint = "0x2AF8";
          fontName = "cascadia-code-prompt";
        };

        # Example 2: Corporate branded font
        branded-font = font-patcher.lib.${system}.patchFont {
          baseFont = pkgs.source-code-pro;
          svgGlyph = ./company-logo.svg;
          unicodePoint = "0xE000";  # Private Use Area
          fontName = "source-code-pro-corporate";
        };

        # Example 3: Multiple glyphs (build separate packages)
        font-with-arrows = font-patcher.lib.${system}.patchFont {
          baseFont = pkgs.jetbrains-mono;
          svgGlyph = ./arrow-right.svg;
          unicodePoint = "0xE0B0";
          fontName = "jetbrains-mono-arrows";
        };

        # Default package
        default = self.packages.${system}.my-terminal-font;
      };

      # Home Manager module example
      homeManagerModules.default = { config, lib, pkgs, ... }: {
        options.myFonts.enable = lib.mkEnableOption "custom patched fonts";
        
        config = lib.mkIf config.myFonts.enable {
          home.packages = [
            self.packages.${pkgs.system}.my-terminal-font
          ];
          
          programs.kitty.font = {
            name = "Cascadia Code Prompt";
            package = self.packages.${pkgs.system}.my-terminal-font;
          };
        };
      };
    };
}
