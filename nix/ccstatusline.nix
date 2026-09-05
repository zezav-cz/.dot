{
  stdenv,
  fetchurl,
  nodejs,
}:

# ccstatusline publishes a single pre-bundled esbuild output with no runtime
# deps (checked its tarball: dist/ccstatusline.js is the whole package), so
# there's no package-lock.json to resolve — no need for buildNpmPackage.
stdenv.mkDerivation rec {
  pname = "ccstatusline";
  version = "2.2.29";

  src = fetchurl {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
    hash = "sha256-3FgL4V0EN4cR8uFfDXZ4zhSqDct7IOVXqJsNlCoGeeU=";
  };

  dontUnpack = false;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 dist/ccstatusline.js $out/bin/ccstatusline
    substituteInPlace $out/bin/ccstatusline \
      --replace-fail "#!/usr/bin/env node" "#!${nodejs}/bin/node"
    runHook postInstall
  '';

  meta = {
    description = "Customizable status line formatter for Claude Code CLI";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = { spdxId = "MIT"; };
    mainProgram = "ccstatusline";
  };
}
