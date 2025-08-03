{
  description = "Universal font patcher - Add any SVG glyph to any font";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        lib = {
          # Main font patcher function
          patchFont = {
            # Required parameters
            baseFont,           # The font package to patch
            svgGlyph,          # Path to SVG file
            unicodePoint,      # Unicode point as string (e.g., "0x2AF8")
            
            # Optional parameters
            fontName ? null,   # Output font name (auto-generated if null)
            glyphName ? null,  # Glyph name in font (defaults to unicode point)
          }:
          let
            derivedName = if fontName != null then fontName 
                         else "${baseFont.pname or baseFont.name}-patched-${builtins.replaceStrings ["0x"] [""] unicodePoint}";
            derivedGlyphName = if glyphName != null then glyphName 
                              else "uni${builtins.replaceStrings ["0x"] [""] (pkgs.lib.toUpper unicodePoint)}";
          in
          pkgs.stdenv.mkDerivation {
            pname = derivedName;
            version = "${baseFont.version or "1.0.0"}-patched";

            src = baseFont;

            nativeBuildInputs = [ pkgs.fontforge ];

            buildPhase = ''
              # Find and copy all font files from the base font package
              echo "Searching for font files in ${baseFont}..."
              find ${baseFont} -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.woff" -o -name "*.woff2" \) | while read font; do
                echo "Found font file: $font"
                cp "$font" .
              done
              
              # Copy the SVG glyph
              cp ${svgGlyph} glyph.svg
              
              # Validate SVG exists
              if [[ ! -f "glyph.svg" ]]; then
                echo "Error: SVG glyph file not found!"
                exit 1
              fi
              
              # Create FontForge script
              cat > patch_font.pe << 'EOF'
              #!/usr/bin/fontforge
              
              if ($argc < 3)
                Print("Usage: patch_font.pe <font_file> <unicode_point> <glyph_name>")
                Quit(1)
              endif
              
              font_file = $1
              unicode_point = $2  
              glyph_name = $3
              
              Print("Opening font: " + font_file)
              Open(font_file)
              
              Print("Adding glyph at unicode point: " + unicode_point + " with name: " + glyph_name)
              
              # Select the unicode point (convert hex string to number)
              Select(unicode_point)
              
              # Clear existing glyph if present
              Clear()
              
              # Import the SVG
              Import("glyph.svg")
              
              # Set glyph name
              SetGlyphName(glyph_name)
              
              # Auto-hint the glyph
              AutoHint()
              
              # Generate the patched font
              Print("Generating patched font...")
              Generate(font_file)
              
              Print("Successfully patched: " + font_file)
              Close()
              EOF
              
              # Patch all found font files
              patched_count=0
              for font in *.ttf *.otf *.woff *.woff2; do
                if [[ -f "$font" ]]; then
                  echo "Patching $font with glyph at ${unicodePoint}..."
                  if fontforge -script patch_font.pe "$font" "${unicodePoint}" "${derivedGlyphName}"; then
                    echo "✓ Successfully patched: $font"
                    patched_count=$((patched_count + 1))
                  else
                    echo "✗ Warning: Failed to patch $font"
                  fi
                fi
              done
              
              if [[ $patched_count -eq 0 ]]; then
                echo "Error: No fonts were successfully patched!"
                exit 1
              fi
              
              echo "Successfully patched $patched_count font files"
            '';

            installPhase = ''
              mkdir -p $out/share/fonts/{truetype,opentype,woff,woff2}
              
              # Install fonts to appropriate directories
              [[ -n "$(ls *.ttf 2>/dev/null)" ]] && cp *.ttf $out/share/fonts/truetype/
              [[ -n "$(ls *.otf 2>/dev/null)" ]] && cp *.otf $out/share/fonts/opentype/
              [[ -n "$(ls *.woff 2>/dev/null)" ]] && cp *.woff $out/share/fonts/woff/
              [[ -n "$(ls *.woff2 2>/dev/null)" ]] && cp *.woff2 $out/share/fonts/woff2/
              
              # Create a metadata file
              cat > $out/font-patch-info.json << EOF
              {
                "base_font": "${baseFont.pname or baseFont.name}",
                "base_version": "${baseFont.version or "unknown"}",
                "patched_name": "${derivedName}",
                "unicode_point": "${unicodePoint}",
                "glyph_name": "${derivedGlyphName}",
                "patch_date": "$(date -Iseconds)"
              }
              EOF
            '';

            meta = with pkgs.lib; {
              description = "Font patched with custom SVG glyph at ${unicodePoint}";
              longDescription = ''
                This package contains ${baseFont.pname or baseFont.name} font family
                patched with a custom SVG glyph at Unicode point ${unicodePoint}.
              '';
              platforms = platforms.all;
              maintainers = [ ];
            };
          };

          # Convenience function for common use cases
          patchFontSimple = baseFont: svgGlyph: unicodePoint:
            self.lib.${system}.patchFont {
              inherit baseFont svgGlyph unicodePoint;
            };
        };

        # Example packages (remove or customize these)
        packages = {
          # Example: Patch Cascadia Code with a sample glyph
          # (You'd replace this with your actual use case)
          example-cascadia-patched = self.lib.${system}.patchFont {
            baseFont = pkgs.cascadia-code;
            svgGlyph = ./examples/sample-glyph.svg;
            unicodePoint = "0xE0A0";
            fontName = "cascadia-code-example-patched";
          };
        };

        # Development shell for testing
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            fontforge
            # Add other tools for font development
          ];
          
          shellHook = ''
            echo "Font Patcher Development Environment"
            echo "FontForge version: $(fontforge --version 2>/dev/null || echo 'not found')"
            echo ""
            echo "Usage example:"
            echo "  nix build .#example-cascadia-patched"
            echo ""
          '';
        };

        # Apps for CLI usage
        apps = {
          # CLI tool to patch fonts interactively
          patch-font = {
            type = "app";
            program = "${pkgs.writeShellScript "patch-font-cli" ''
              set -euo pipefail
              
              if [[ $# -lt 3 ]]; then
                echo "Usage: nix run github:yourusername/font-patcher#patch-font -- <font-path> <svg-path> <unicode-point> [output-name]"
                echo ""
                echo "Examples:"
                echo "  nix run .#patch-font -- ./MyFont.ttf ./my-glyph.svg 0x2AF8"
                echo "  nix run .#patch-font -- ./MyFont.ttf ./my-glyph.svg 0xE0A0 my-custom-font"
                exit 1
              fi
              
              FONT_PATH="$1"
              SVG_PATH="$2" 
              UNICODE_POINT="$3"
              OUTPUT_NAME="''${4:-patched-font}"
              
              echo "Patching font with Nix..."
              echo "Font: $FONT_PATH"
              echo "SVG: $SVG_PATH"
              echo "Unicode: $UNICODE_POINT"
              echo "Output: $OUTPUT_NAME"
              
              # This would need more implementation for a real CLI tool
              echo "This is a placeholder - implement actual CLI logic here"
            ''}";
          };
        };
      }) // {
        # Documentation and templates
        templates = {
          basic = {
            path = ./templates/basic;
            description = "Basic font patching example";
          };
          
          advanced = {
            path = ./templates/advanced;
            description = "Advanced font patching with multiple glyphs";
          };
        };
      };
}
