{ config, lib, pkgs, ... }:

with lib;
with (import ./lib.nix { inherit lib; });

let

  cfg = config.activation;

  sourceManifest = filterLink config.system.currentConfiguration.manifest;
  targetManifest = filterLink config.system.manifest;

  moduleLabel = "link-files";

  filterLink = filter (isDrvModule moduleLabel);

  mkLink = name: sourcePath: mkModuleDerivation moduleLabel (builtins.baseNameOf name) name
    // { inherit sourcePath; };

  activateLink = drv: ''
    if [ ! -e "${drv}" -o -L "${drv}" ]; then
      ${optionalString (isDerivation drv) ''
        if [ "$(readlink "${drv}")" != "${drv.sourcePath}" ]; then
          ln -sfn "${drv.sourcePath}" "${drv}"
        fi
      ''}
      ${optionalString (isDelete drv) ''
        if [ -L "${drv}" ]; then
          rm -f "${drv}"
        fi
      ''}
    else
      echo "warning: ${drv} is not a symlink, skipping..." >&2
    fi
  '';

in

{
  options = {

    activation.linkFiles = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Files to symlink during activation.";
    };

  };

  config = {

    system.manifest = mapAttrsToList mkLink cfg.linkFiles;

    system.activationScripts.linkFiles.text = ''
      echo "setting up symlinks..." >&2
      ${concatMapStringsSep "\n" activateLink (manifestDiff sourceManifest targetManifest)}
    '';

  };
}
