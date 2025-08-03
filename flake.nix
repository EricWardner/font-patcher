{
  description = "Font patcher library";
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
                
                mkdir -p fonts
                
                # Find all font files in the base package and patch them
                find $src/share/fonts -name "*.ttf" -o -name "*.otf" | while read font; do
                  # Get the relative path from share/fonts
                  relpath=$(realpath --relative-to=$src/share/fonts "$font")
                  # Create the directory structure
                  mkdir -p "fonts/$(dirname "$relpath")"
                  # Patch the font maintaining the relative path
                  python3 ${./patch-font.py} "$font" "${unicodePoint}" "${svgGlyph}" "fonts/$relpath"
                done
                
                runHook postBuild
              '';
              
              installPhase = ''
                runHook preInstall
                
                mkdir -p $out/share/fonts
                # Copy maintaining the directory structure
                cp -r fonts/* $out/share/fonts/
                
                runHook postInstall
              '';
              
              meta = baseFont.meta // {
                description = "${baseFont.meta.description or baseFont.name} with custom glyph patch";
              };
            };
        });
    };
}