# pVPN-Nix

Nix flake and NixOS module for [pVPN](https://github.com/YourDoritos/pVPN) (unofficial Proton VPN client for Linux).

Builds `pvpn` (TUI client), `pvpnctl` (CLI controller), and `pvpnd` (daemon with `nftables` runtime wrapper).

---

## Features

- **Flake outputs**:
  - `packages.<system>.pvpn` & `packages.<system>.default`
  - `apps.<system>.pvpn`, `apps.<system>.pvpnctl`, `apps.<system>.pvpnd`, and `apps.<system>.default`
  - `nixosModules.pvpn` & `nixosModules.default`
  - `overlays.pvpn` & `overlays.default`
- **Non-flake compatibility**:
  - `default.nix` (for `nix-build`)
  - `overlay.nix` (for standalone nixpkgs overlay)

---

## Usage

### Quick Run

Run the TUI without installing:

```bash
nix run github:fumoctl/pVPN-Nix
```

Run `pvpnctl`:

```bash
nix run github:fumoctl/pVPN-Nix#pvpnctl -- status
```

---

### NixOS Configuration

Add `pVPN-Nix` to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pvpn-nix.url = "github:fumoctl/pVPN-Nix";
  };

  outputs = { self, nixpkgs, pvpn-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        pvpn-nix.nixosModules.default
        {
          programs.pvpn = {
            enable = true;
            # Users who can communicate with the pVPN daemon
            users = [ "fumoctl" ];
          };
        }
      ];
    };
  };
}
```

The NixOS module:
- Installs `pvpn` packages system-wide
- Creates the `pvpn` user group and adds specified users to it
- Sets up and enables the `pvpnd.service` systemd daemon

---

### Using as an Overlay

```nix
{
  nixpkgs.overlays = [
    pvpn-nix.overlays.default
  ];
}
```

Then `pkgs.pvpn` will be available in your package set.

---

### Building Locally

```bash
# Build the package
nix build .#pvpn

# Check the flake
nix flake check
```

---

## Maintenance & Auto-Updates

### Checking for Upstream Updates

```bash
./scripts/check-version.sh
```

Flags:
- `--json`: Outputs JSON data `{ "current_version": "...", "latest_version": "...", "needs_update": bool }`
- `--exit-code`: Exits with code `2` if an update is available (useful for scripts)
- `--quiet` / `-q`: Suppresses human-readable output

### Updating to a New Version

To automatically detect and update to the latest upstream release:

```bash
./scripts/update-version.sh
```

Or specify a version manually:

```bash
./scripts/update-version.sh 0.2.7
```

This script:
1. Updates `version`, source `hash`, and Go `vendorHash` in `pkgs/pvpn.nix` using `nix-update`
2. Verifies the flake with `nix flake check`
3. Builds the package with `nix build .#pvpn` and validates binary version output

### GitHub Actions Automation

- **Auto-Update** ([`.github/workflows/update.yml`](file:///.github/workflows/update.yml)): Runs daily at 06:00 UTC and on manual dispatch to check for new `pVPN` releases and commit updates.
- **CI** ([`.github/workflows/ci.yml`](file:///.github/workflows/ci.yml)): Runs on pushes and pull requests to validate the flake and build all binaries.