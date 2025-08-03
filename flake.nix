{
  description = "Nix flake for patching fonts with custom SVG glyphs";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      lib = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          patchFont = { baseFont, svgGlyph, unicodePoint, name ? baseFont.name }:
            pkgs.stdenv.mkDerivation {
              pname = "${baseFont.pname}-patched";
              version = baseFont.version;
              
              src = baseFont;
              
              nativeBuildInputs = [
                (pkgs.python3.withPackages (ps: [
                  ps.fontforge
                  ps.argcomplete
                ]))
              ];
              
              dontUnpack = true;
              
              buildPhase = ''
                runHook preBuild
                
                # Process each font, maintaining directory structure
                cd $src/share/fonts
                find . -name "*.ttf" -o -name "*.otf" | while read font; do
                  mkdir -p "$out/share/fonts/$(dirname "$font")"
                  python3 ${./patch-font.py} "$font" "${unicodePoint}" "${svgGlyph}" \
                    "$out/share/fonts/$font"
                done
                
                runHook postBuild
              '';
              
              # No install phase needed - we're writing directly to $out
              dontInstall = true;
              
              meta = baseFont.meta // {
                description = "${baseFont.meta.description or baseFont.name} with custom glyph patch";
              };
            };
        });
    };
}