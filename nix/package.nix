# wt bin plus runtime data for `wt init`/`wt completions`. Called with
# callPackage so `.override { withZshCompletion = false; }` works.
{ lib, stdenvNoCC, makeWrapper, installShellFiles, git, jq
, withZshCompletion ? true }:
stdenvNoCC.mkDerivation {
  pname = "wt";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./..;
    fileset = lib.fileset.unions [
      ../wt
      ../wt.plugin.sh
      ../wt.completions.zsh
    ];
  };

  nativeBuildInputs = [ makeWrapper installShellFiles ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 wt $out/bin/wt
    install -Dm644 wt.plugin.sh $out/share/wt/wt.plugin.sh
    install -Dm644 wt.completions.zsh $out/share/wt/wt.completions.zsh
    wrapProgram $out/bin/wt --prefix PATH : ${lib.makeBinPath [ git jq ]}
  '' + lib.optionalString withZshCompletion ''
    installShellCompletion --zsh --name _wt wt.completions.zsh
  '' + ''
    runHook postInstall
  '';

  meta = {
    description = "git worktree manager";
    license = lib.licenses.mit;
    mainProgram = "wt";
    platforms = lib.platforms.unix;
  };
}
