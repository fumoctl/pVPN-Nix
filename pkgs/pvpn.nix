{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  nftables,
}:

buildGoModule (finalAttrs: {
  pname = "pvpn";
  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "YourDoritos";
    repo = "pVPN";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KMTUPilF5MezqnayqgOfkyzYLI+Ks73KV0h8+5OO+f4=";
  };

  vendorHash = "sha256-eVFKW4plsUwpwPqMmvdIEtJC/B0pk7eQL1Hlrgq8zrA=";

  ldflags = [
    "-s"
    "-w"
    "-X 'main.version=${finalAttrs.version}'"
    "-X 'main.Version=${finalAttrs.version}'"
  ];

  subPackages = [
    "cmd/pvpnd"
    "cmd/pvpn"
    "cmd/pvpnctl"
  ];

  env.CGO_ENABLED = 0;

  postPatch = ''
    substituteInPlace internal/api/client.go \
      --replace-fail 'AppVersion     = "linux-vpn@4.13.1"' 'AppVersion     = "linux-vpn@4.18.1"' \
      --replace-fail 'UserAgent      = "ProtonVPN/4.13.1 (Linux; go-pvpn)"' 'UserAgent      = "ProtonVPN/4.18.1 (Linux; go-pvpn)"'
  '';

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/pvpnd \
      --prefix PATH : ${lib.makeBinPath [ nftables ]}
  '';

  meta = {
    description = "Unofficial Proton VPN client for Linux";
    homepage = "https://github.com/YourDoritos/pVPN";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "pvpn";
  };
})
