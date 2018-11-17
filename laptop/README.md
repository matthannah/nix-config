# nix-config

## Rebuild system

```
/etc/nixos/rebuild switch
```

If nixpkgs changed (repo updated), make sure to update the
`/etc/nixos/nixpkgs.nix` file with the new hash, which can be generated via:

```
nix-prefetch-url --type sha256 --unpack <url>
``` 

## Rebuild home

```
home-manager switch
```
