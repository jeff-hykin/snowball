self: super: with self; {
  numpy = callPackage ../development/python-modules/numpy { };
  numpy_Args = callPackage ../development/python-modules/numpy/args.nix { };
}