# Nix

Install [Nix](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#determinate-nix-installer):
```bash 
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

Then run:
```bash
nix run nix-darwin -- switch --flake ~/dotfiles/configs/nix-darwin
```

or use the alias:

```bash
nixswitch
```
