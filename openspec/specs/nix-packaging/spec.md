# Nix Packaging

## Purpose

Package wt as a Nix flake with a package, overlay, and home-manager module.

## Requirements

### Requirement: Flake Outputs
The repository SHALL provide a `flake.nix` exporting `packages.<system>.wt`, `packages.<system>.default`, `overlays.default`, `homeManagerModules.wt`, `homeManagerModules.default` and `checks.<system>` for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin` and `aarch64-darwin`.

#### Scenario: Install via systemPackages
- **WHEN** a NixOS user adds `inputs.wt.packages.${system}.default` to `environment.systemPackages`
- **THEN** `wt` is on PATH
- **THEN** `_wt` is installed under `share/zsh/site-functions`

#### Scenario: Overlay
- **WHEN** a user applies `overlays.default`
- **THEN** `pkgs.wt` is available

### Requirement: Package Contents
The package SHALL install `bin/wt` with `git` and `jq` on its PATH, and SHALL always install `share/wt/wt.plugin.sh` and `share/wt/wt.completions.zsh`.

#### Scenario: Runtime deps
- **WHEN** `wt` from the package runs on a system without jq installed
- **THEN** commands needing jq work

### Requirement: Zsh Completion Override
The package SHALL accept a `withZshCompletion` argument (default `true`) controlling installation of `share/zsh/site-functions/_wt`, overridable with `.override`.

#### Scenario: Disable completions
- **WHEN** a user builds `packages.<system>.default.override { withZshCompletion = false; }`
- **THEN** the output has no `share/zsh` directory
- **THEN** `bin/wt` and `share/wt` are still present

### Requirement: Home-Manager Module
The flake SHALL provide a home-manager module with options `programs.wt.enable`, `programs.wt.package`, `programs.wt.zshCompletion.enable` (default true) and `programs.wt.enableZshIntegration` (default true).

#### Scenario: Enable module
- **WHEN** a user sets `programs.wt.enable = true`
- **THEN** the package is added to `home.packages`
- **THEN** `.zshrc` evaluates `wt init zsh`

#### Scenario: Disable completion in module
- **WHEN** `programs.wt.zshCompletion.enable = false`
- **THEN** the installed package is built with `withZshCompletion = false`

#### Scenario: Disable integration
- **WHEN** `programs.wt.enableZshIntegration = false`
- **THEN** `.zshrc` does not reference `wt init zsh`
