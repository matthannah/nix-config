{ stdenv, libxcb, gcc }:

stdenv.mkDerivation {
  name = "monitor-watcher";

  src = ./.;

  buildInputs = [ libxcb ];

  buildPhase = ''
    gcc main.c -o monitor-watcher -lxcb -lxcb-randr
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp monitor-watcher $out/bin
  '';
}
