# `nix flake check` gate: home-manager evaluation of the module, the
# no-completion override and the wrapped bin's init/completions output.
{ self, pkgs, home-manager }:
let
  system = pkgs.stdenv.hostPlatform.system;
  wt = self.packages.${system}.wt;

  hm = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      self.homeManagerModules.wt
      {
        home = { username = "test"; homeDirectory = "/home/test"; stateVersion = "25.05"; };
        programs.zsh.enable = true;
        programs.wt.enable = true;
      }
    ];
  };
in
{
  hm-module-eval = pkgs.runCommand "hm-module-eval" { } ''
    grep -q 'wt init zsh' ${hm.activationPackage}/home-files/.zshrc
    test -e ${hm.activationPackage}/home-path/share/zsh/site-functions/_wt
    touch $out
  '';

  wt-no-zsh-completion =
    let pkg = wt.override { withZshCompletion = false; };
    in pkgs.runCommand "wt-no-zsh-completion" { } ''
      test ! -e ${pkg}/share/zsh
      test -f ${pkg}/share/wt/wt.plugin.sh
      test -f ${pkg}/share/wt/wt.completions.zsh
      test -x ${pkg}/bin/wt
      touch $out
    '';

  wt-init-completions = pkgs.runCommand "wt-init-completions" { } ''
    WT_BIN=${wt}/bin/wt WT_DATA_DIR=${wt}/share/wt ${pkgs.bash}/bin/bash ${../tests/init_completions_test.sh}
    touch $out
  '';
}
