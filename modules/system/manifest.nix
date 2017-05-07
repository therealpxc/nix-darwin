{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

  importManifest = manifest: if pathExists manifest then import manifest else [];

  pprNix = expr: ({ list = pprList; set = pprSet; string = pprString; }."${builtins.typeOf expr}" or toString) expr;

  pprList = expr: ''[ ${concatMapStringsSep " " pprValue expr} ]'';
  pprSet = expr: ''{ ${concatStringsSep " " (mapAttrsToList pprAttr expr)} }'';
  pprString = expr: ''"${expr}"'';

  pprAttr = name: expr: ''${name} = ${pprValue expr};'';
  pprValue = value: if isDerivation value then pprString value else pprNix value;

in

{
  options = {

    system.manifest = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "List of activation modules.";
    };

    system.currentConfiguration.manifest = mkOption {
      internal = true;
      type = types.listOf types.package;
      description = "Manifest imported from the current configuration.";
    };

  };

  config = {

    system.currentConfiguration.manifest = importManifest /run/current-system/manifest.nix;

    system.build.manifest = pkgs.writeText "manifest.nix"
      ''[ ${concatMapStringsSep " " pprSet cfg.manifest} ]'';

  };
}
