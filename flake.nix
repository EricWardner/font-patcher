{
  description = "Font patcher library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
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
                (pkgs.python3.withPackages (ps: [ ps.fontforge ps.argcomplete ]))
              ];

              dontUnpack = true;

              buildPhase = ''
                runHook preBuild
                
                mkdir -p fonts
                
                # Find all font files in the base package and patch them
                find $src/share/fonts -name "*.ttf" -o -name "*.otf" | while read font; do
                  fontname=$(basename "$font")
                  python3 ${./patch-font.py} "$font" "${unicodePoint}" "${svgGlyph}" "fonts/$fontname"
                done
                
                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall
                
                mkdir -p $out/share/fonts/truetype
                cp fonts/* $out/share/fonts/truetype/
                
                runHook postInstall
              '';

              meta = baseFont.meta // {
                description = "${baseFont.meta.description or baseFont.name} with custom glyph patch";
              };
            };
        });
    };
}