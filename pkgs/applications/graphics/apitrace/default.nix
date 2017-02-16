{ stdenv, fetchFromGitHub, cmake, libX11, procps, python2, python2Packages, libdwarf, qtbase, qtwebkit, libpng, zlib }:

stdenv.mkDerivation rec {
  name = "apitrace-${version}";
  version = "2017-01-30";

  src = fetchFromGitHub {
    sha256 = "1aj5dqww0vpxjr5b78dalphpyiydl4icda8lp87h5jppabalgi44";
    rev = "6a30de197ad8221e6481510155025a9f93dfd5c3";
    repo = "apitrace";
    owner = "apitrace";
  };

  # LD_PRELOAD wrappers need to be statically linked to work against all kinds
  # of games -- so it's fine to use e.g. bundled snappy.
  buildInputs = [ libX11 procps python2 python2Packages.pillow zlib libpng libdwarf qtbase qtwebkit ];

  nativeBuildInputs = [ cmake ];

  meta = with stdenv.lib; {
    homepage = https://apitrace.github.io;
    description = "Tools to trace OpenGL, OpenGL ES, Direct3D, and DirectDraw APIs";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ nckx ];
  };
}
