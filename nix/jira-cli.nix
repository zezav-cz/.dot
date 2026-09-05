{
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:

buildGoModule rec {
  pname = "jira-cli";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "ankitpokhrel";
    repo = "jira-cli";
    rev = "v${version}";
    hash = "sha256-NJXLB2N8Kc8Ow6kb2EtPSG+iZ7O4yrhAMi3NFrUuocA=";
  };

  vendorHash = "sha256-cl+Sfi9WSPy8qOtB13rRiKtQdDC+HC0+FMKpsWbtU2w=";

  subPackages = [ "cmd/jira" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/ankitpokhrel/jira-cli/internal/version.Version=v${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd jira \
      --bash <($out/bin/jira completion bash) \
      --zsh <($out/bin/jira completion zsh) \
      --fish <($out/bin/jira completion fish)
  '';

  meta = {
    description = "Feature-rich interactive Jira command line tool";
    homepage = "https://github.com/ankitpokhrel/jira-cli";
    license = { spdxId = "MIT"; };
    mainProgram = "jira";
  };
}
