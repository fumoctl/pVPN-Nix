{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  nftables,
}:

buildGoModule (finalAttrs: {
  pname = "pvpn";
  version = "0.2.8";

  src = fetchFromGitHub {
    owner = "YourDoritos";
    repo = "pVPN";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dHnf1sHR83foRJwfSClIlND3mzNxVjcHiXrBxs4KpxI=";
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
