def run(*cmd, timeout_sec=None):
    from subprocess import Popen, PIPE
    proc = Popen(cmd, stdout=PIPE, stderr=PIPE)
    stdout, stderr = proc.communicate()
    return stdout.decode('utf-8')[0:-1], stderr.decode('utf-8')[0:-1]

print(
    run(
        "nix",
        "eval",
        "-I", f'nixpkgs=https://github.com/NixOS/nixpkgs/archive/aa0e8072a57e879073cee969a780e586dbe57997.tar.gz',
        '--impure',
        '--expr', '(builtins.attrNames (import <nixpkgs> {}))'
    )
)