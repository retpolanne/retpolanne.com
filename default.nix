with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "jekyll_env";
  buildInputs = [
    jekyll
  ];
  shellHook = ''
    exec jekyll serve --watch
  '';
}
