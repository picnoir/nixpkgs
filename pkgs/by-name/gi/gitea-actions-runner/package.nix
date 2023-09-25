{
  lib,
  fetchFromGitea,
  buildGo123Module,
  testers,
  gitea-actions-runner,
}:

buildGo123Module rec {
  pname = "gitea-actions-runner";
  version = "0.2.11";

  src = fetchFromGitea {
    domain = "gitea.com";
    owner = "NinjaTrappeur";
    repo = "act_runner";
    rev = "c7f39de3a87c5f2940e13d5f837320ee3791af6e";
    hash = "sha256-q4WzFsCkfCHk369DWaZksBNC0v31gUahwhcLUHWqzTI=";
  };

  vendorHash = "sha256-NoaLq5pCwTuPd9ne5LYcvJsgUXAqcfkcW3Ck2K350JE=";

  ldflags = [
    "-s"
    "-w"
    "-X gitea.com/gitea/act_runner/internal/pkg/ver.version=v${version}"
  ];

  passthru.tests.version = testers.testVersion {
    package = gitea-actions-runner;
    version = "v${version}";
  };

  meta = with lib; {
    mainProgram = "act_runner";
    maintainers = with maintainers; [ techknowlogick ];
    license = licenses.mit;
    changelog = "https://gitea.com/gitea/act_runner/releases/tag/v${version}";
    homepage = "https://gitea.com/gitea/act_runner";
    description = "Runner for Gitea based on act";
  };
}
