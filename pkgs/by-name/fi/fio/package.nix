{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  libaio,
  python3,
  zlib,
  withGnuplot ? false,
  gnuplot ? null,
}:

stdenv.mkDerivation rec {
  pname = "fio";
  version = "3.40";

  src = fetchFromGitHub {
    owner = "axboe";
    repo = "fio";
    rev = "fio-${version}";
    sha256 = "sha256-rfO4JEZ+B15NvR2AiTnlbQq++UchPYiXz3vVsFaG6r4=";
  };

  buildInputs = [
    python3
    zlib
  ]
  ++ lib.optional (!stdenv.hostPlatform.isDarwin) libaio;

  # ./configure does not support autoconf-style --build=/--host=.
  # We use $CC instead.
  configurePlatforms = [ ];

  dontAddStaticConfigureFlags = true;

  nativeBuildInputs = [
    makeWrapper
    python3.pkgs.wrapPython
  ];

  strictDeps = true;

  enableParallelBuilding = true;

  postPatch = ''
    substituteInPlace Makefile \
      --replace "mandir = /usr/share/man" "mandir = \$(prefix)/man" \
      --replace "sharedir = /usr/share/fio" "sharedir = \$(prefix)/share/fio"
    substituteInPlace tools/plot/fio2gnuplot --replace /usr/share/fio $out/share/fio
  '';

  pythonPath = [ python3.pkgs.six ];

  makeWrapperArgs = lib.optionals withGnuplot [
    "--prefix PATH : ${lib.makeBinPath [ gnuplot ]}"
  ];

  postInstall = ''
    wrapPythonProgramsIn "$out/bin" "$out $pythonPath"
  '';

  meta = with lib; {
    description = "Flexible IO Tester - an IO benchmark tool";
    homepage = "https://git.kernel.dk/cgit/fio/";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
