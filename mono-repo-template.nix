let 
    pkgs = import ../flake.nix;
    value = builtins.fetchFromGitHub {
        url = "";
    };
in
    {
        inputs = value.inputs // {
            pkgs = pkgs // {
                # if they need python3 put expect it to be pkgs.python,
                # then put python = pkgs.python3 below this comment
            };
            custom = value.inputs.custom // {
                # if they expect to be given something like withCuda=true;
            };
        };
        outputs = value.outputs;
    }