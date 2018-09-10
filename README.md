# nix-config

## Rebuild system

```
nixos-rebuild -I nixos-config=/etc/nixos/configuration.nix -I nixpkgs=https://github.com/matthannah/nixpkgs/archive/18.03-nvidia-optimus-prime.tar.gz switch
```

## Rebuild home

```
home-manager switch
```
