{ lib, stdenv, fetchurl, ncurses, pkgconfig

# This package is somehow too deeply integrated into bootstrap(?)
# process, and unconditionally enabling this makes both VM tests and
# github CI fail. The problem is that `systemd` we are getting here is
# for some reason evaluated in an environment where `fetchurl` is
# really `fetchurlBoot` - and it fails because some dependecies will
# try to call it with a lot of fancy options supported only by a full
# version. So for now I'm going to make this available only by explicit request,
# just to provide a proper version of `ps` required by RabbitMQ.
, withSystemd ? false, systemd
}:

stdenv.mkDerivation rec {
  name = "procps-${version}";
  version = "3.3.15";

  # The project's releases are on SF, but git repo on gitlab.
  src = fetchurl {
    url = "mirror://sourceforge/procps-ng/procps-ng-${version}.tar.xz";
    sha256 = "0r84kwa5fl0sjdashcn4vh7hgfm7ahdcysig3mcjvpmkzi7p9g8h";
  };

  buildInputs = [ ncurses ];
  nativeBuildInputs = [ pkgconfig ]
    ++ lib.optional withSystemd systemd;

  makeFlags = "usrbin_execdir=$(out)/bin";

  enableParallelBuilding = true;

  # Too red
  configureFlags = [ "--disable-modern-top" ]
    ++ lib.optional withSystemd "--with-systemd"
    ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform)
    [ "ac_cv_func_malloc_0_nonnull=yes"
      "ac_cv_func_realloc_0_nonnull=yes" ];

  meta = {
    homepage = https://gitlab.com/procps-ng/procps;
    description = "Utilities that give information about processes using the /proc filesystem";
    priority = 10; # less than coreutils, which also provides "kill" and "uptime"
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux ++ lib.platforms.cygwin;
    maintainers = [ lib.maintainers.typetetris ];
  };
}
