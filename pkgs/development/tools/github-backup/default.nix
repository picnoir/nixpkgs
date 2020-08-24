{ haskellPackages, haskell }:
let
  haskellPackagesFixed = haskellPackages.override {
    overrides = super: self: {
      github = haskell.lib.overrideCabal self.github (drv: {
        version = "0.23";
        sha256 = "1d08m0kajl6zaralz1rbm4miv2a5zrbm6asjyrl75n915l56m9mb";
      });
    };
  };
  github-backup = haskellPackagesFixed.github-backup;
in haskell.lib.overrideCabal github-backup (drv: {
  broken = false;
})
