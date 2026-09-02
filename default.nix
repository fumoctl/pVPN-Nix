{ pkgs ? import <nixpkgs> { } }:

pkgs.callPackage ./pkgs/pvpn.nix { }
