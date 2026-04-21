{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  zlib,
  elfutils,
  dmidecode,
  jq,
  gcc-unwrapped,
}:
let
  sentinelOnePackage = "SentinelAgent-Linux-24-3-3-1-x86-64-release-24-3-3_linux_x86_64_v24_3_3_1.deb";
in
stdenv.mkDerivation {
  pname = "sentinelone";
  version = "24.3.3.1";

  src = fetchurl {
    url = "https://imugit.imubit.com/morgan.helton/sentinelone/-/raw/main/${sentinelOnePackage}";
    hash = "sha256-EgahRYXm3eceaDnR8wf6qQ6kirk1xC+epbHjj1KyLlc=";
  };

  unpackPhase = ''
    runHook preUnpack

    dpkg-deb -x $src .

    runHook postUnpack
  '';

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    zlib
    elfutils
    dmidecode
    jq
    gcc-unwrapped
  ];

  installPhase = ''
    mkdir -p $out/opt/

    cp -r opt/* $out/opt
  '';

  dontAutoPatchelf = true;
  dontPatchELF = true;

  preFixup = ''
    patchelf --replace-needed libelf.so.0 libelf.so $out/opt/sentinelone/lib/libbpf.so
  '';

  postFixup = ''
    shopt -s extglob
    addAutoPatchelfSearchPath $out/opt/sentinelone/lib
    autoPatchelf $out/opt/sentinelone/!(bin) $out/opt/sentinelone/bin/!(sentinelctl)
  '';
}
