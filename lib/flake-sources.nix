# Store paths of the flake itself and of every node in flake.lock (inputs of
# inputs too). The installed system keeps them as GC roots, so a rebuild of
# the current lock never has to re-fetch an input after garbage collection.
{ lib, inputs }:
let
  sources = i: [ i.outPath ] ++ lib.concatMap sources (lib.attrValues (i.inputs or { }));
in
lib.unique (
  [ inputs.self.outPath ] ++ lib.concatMap sources (lib.attrValues (removeAttrs inputs [ "self" ]))
)
