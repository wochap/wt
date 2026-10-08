# Home-manager module: programs.wt.
{ self }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.wt;
  inherit (lib) mkEnableOption mkOption mkIf types;
  system = pkgs.stdenv.hostPlatform.system;
  package = cfg.package.override { withZshCompletion = cfg.enableZshCompletion; };
in
{
  options.programs.wt = {
    enable = mkEnableOption "wt, git worktree manager";
    package = mkOption {
      type = types.package;
      default = self.packages.${system}.wt;
      description = "wt package; must accept `withZshCompletion` via `.override`.";
    };
    enableZshCompletion = mkOption {
      type = types.bool;
      default = true;
      description = "Install zsh completions (_wt on fpath).";
    };
    enableZshIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Load the wt() shell function (cd after switch/clone/rename/rm) in zsh.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];
    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${package}/bin/wt init zsh)"
    '';
  };
}
