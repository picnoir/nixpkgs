{ stdenv
, fetchFromGitHub
, automake
, autoconf
, bison
, flex
, perl
, zlib
, bash
, ghc
, haskellPackages
, gmp
, gperf
, libpoly
, pkgconfig
, libX11
, fontconfig
, xorg
, glibc
}:

let
  gmp-static = gmp.override { withStatic = true; };
  ghcWithPackages = ghc.withPackages (g: (with g; [old-time regex-compat syb]));
in stdenv.mkDerivation rec {
  pname = "bsc";
  version = "unstable-2020.02.05";

  src = fetchFromGitHub {
    owner  = "B-Lang-org";
    repo   = "bsc";
    rev    = "11f9a729fe5bb301f0899d3497e79e004a047e37";
    sha256 = "1ywfnzpc4da6jlbhx521lgz778npsbwimdjlfh7d2lbs7yjjg37p";
    fetchSubmodules = true;
  };

  enableParallelBuilding = true;

  buildInputs = [
    zlib
    gmp-static gperf libpoly # yices
    libX11 # tcltk
    xorg.libXft
    fontconfig
  ];

  nativeBuildInputs = [
    automake autoconf
    perl
    pkgconfig
    flex
    bison
    ghcWithPackages
    glibc.bin
  ];

  patches = [
    ./0001-yices-Makefile-set-LDCONFIG-to-ldconfig.patch
    (builtins.fetchurl {
      url = "https://patch-diff.githubusercontent.com/raw/B-Lang-org/bsc/pull/18.patch";
      sha256 = "0s1b1y4m2nnr4q0hcayjxaavfsfg87281n54fmf5wcyj1bk9k190";
      name = "0002-patch_ooom_TOREMOVE_BEFORE_PR";
    })
  ];

  preBuild = ''
    chmod +x src/comp/wrapper.sh
    patchShebangs src/stp/src/AST/genkinds.pl src/comp/update-build-version.sh src/comp/wrapper.sh
  '';

  makeFlags = [
    "NOGIT=1" # https://github.com/B-Lang-org/bsc/issues/12
  ];

  doCheck = false;

  # this is untested
  checkPhase = ''
    cd examples/smoke_test/
    make smoke_test
  '';

  meta = {
    description = "Bluespec Compiler (BSC)";
    longDescription = ''
      Compiler, simulator, and associated tools for Bluespec High Level
      Hardware Design Language (HL-HDL), supporting the two optional
      syntaxes, BSV and BH.
      '';
    homepage    = "https://github.com/B-Lang-org/bsc";
    license     = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [ flokli ];
  };
}
