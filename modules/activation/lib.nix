{ lib }:

with lib;

rec {

  attrsToDrvList = mapAttrsToList (_: drv: drv);
  listToDrvAttrs = mapListToAttrs (drv: { name = "${drv}"; value = drv; });

  diffAttrs = joinAttrs markDeleted;

  isDelete = drv: drv.type == "delete";
  isDrvModule = module: drv: drv.module == module;

  joinAttrs = fn: lhs: rhs: mergeAttrs (mapAttrs fn lhs) rhs;

  mapListToAttrs = fn: xs: listToAttrs (map fn xs);

  manifestDiff = lhs: rhs: attrsToDrvList (diffAttrs (listToDrvAttrs lhs) (listToDrvAttrs rhs));

  markDeleted = name: drv: drv // { type = "delete"; };

  mkModuleDerivation = module: name: outPath: rec {
    inherit name module outPath;
    type = "derivation";
    out = { inherit outPath; };
  };

}
