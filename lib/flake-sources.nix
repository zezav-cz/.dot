# Store paths of the flake itself and of every node in flake.lock (inputs of
# inputs too). The installer ISO ships them so evaluation needs no GitHub, and
# the installed system keeps them as GC roots so `nixos-rebuild` never has to
# re-fetch the private `vn` input (root has no SSH key for it).
{ lib, inputs }:
let
  sources = i: [ i.outPath ] ++ lib.concatMap sources (lib.attrValues (i.inputs or { }));
in
lib.unique (
  [ inputs.self.outPath ] ++ lib.concatMap sources (lib.attrValues (removeAttrs inputs [ "self" ]))
)
