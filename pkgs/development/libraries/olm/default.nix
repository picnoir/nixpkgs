{ lib, stdenv, fetchFromGitLab, cmake, emscripten, python3 }:

stdenv.mkDerivation rec {
  pname = "olm";
  version = "3.2.6";

  src = fetchFromGitLab {
    domain = "gitlab.matrix.org";
    owner = "matrix-org";
    repo = pname;
    rev = version;
    sha256 = "1srmw36nxi0z2y5d9adks09p950qm0fscbnrq1fl37fdypvjl1sk";
  };

  nativeBuildInputs = [ emscripten python3 ];

  postUnpack = ''
    patchShebangs $PWD
  '';

  makeFlags = [ "PREFIX='./dist'" "js" ];

  # Emscripten is trying to cache the system calls in the nix store by default.
  # Overriding that and forcing the cache to happen from within the builder.
  EM_CACHE = "./cache";

  postInstall = ''
    mkdir $out/lib
    cp -r javascript/* $out/lib
  '';

  doCheck = false;

  meta = with lib; {
    description = "Implements double cryptographic ratchet and Megolm ratchet";
    homepage = "https://gitlab.matrix.org/matrix-org/olm";
    license = licenses.asl20;
    maintainers = with maintainers; [ tilpner oxzi ];
  };
}
