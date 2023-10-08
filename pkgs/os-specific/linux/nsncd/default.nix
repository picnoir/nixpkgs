{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, nix-gitignore
}:

rustPlatform.buildRustPackage rec {
  pname = "nsncd";
  version = "unstable-2022-11-14";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nsncd";
    rev = "f999b1c4250353420101ea2679fefac88b48b025";
    hash = "sha256-OZwX4kBEQjPirBuerhBIY+iLtTUsvd20IFgOs6KdJZE=";
  };

  cargoSha256 = "sha256-3bEec9IMN7CAaQsRwVbz7NxWHTqdK/LX0Jz0cxgBEio=";

  meta = with lib; {
    description = "the name service non-caching daemon";
    longDescription = ''
      nsncd is a nscd-compatible daemon that proxies lookups, without caching.
    '';
    homepage = "https://github.com/twosigma/nsncd";
    license = licenses.asl20;
    maintainers = with maintainers; [ flokli ninjatrappeur ];
    # never built on aarch64-darwin, x86_64-darwin since first introduction in nixpkgs
    broken = stdenv.isDarwin;
  };
}
