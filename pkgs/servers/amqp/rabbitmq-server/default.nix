{ stdenv, fetchurl, runCommand
, erlang, elixir, python, libxml2, libxslt, xmlto
, docbook_xml_dtd_45, docbook_xsl, zip, unzip, rsync
, AppKit, Carbon, Cocoa
, getconf, socat, procps, ps
}:

let

  procpsWithSystemd = procps.override {withSystemd = true;};
  psWithSystemd = runCommand "ps-with-systemd" {} ''
    install -D "${procpsWithSystemd}/bin/ps" "$out/bin/ps"
  '';

  ps' = if stdenv.isLinux then psWithSystemd else ps;

in stdenv.mkDerivation rec {
  name = "rabbitmq-server-${version}";

  version = "3.7.7";
  src = fetchurl {
    url = "https://github.com/rabbitmq/rabbitmq-server/releases/download/v${version}/${name}.tar.xz";
    sha256 = "0cal4ss981i5af7knjkz3jqmz25nd4pfppay163q6xk2llxrcj9m";
  };

  buildInputs =
    [ erlang elixir python libxml2 libxslt xmlto docbook_xml_dtd_45 docbook_xsl zip unzip rsync ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ AppKit Carbon Cocoa ];

  outputs = [ "out" "man" "doc" ];

  preBuild = ''
    # Fix the "/usr/bin/env" in "calculate-relative".
    patchShebangs .
  '';

  installFlags = "PREFIX=$(out) RMQ_ERLAPP_DIR=$(out)";
  installTargets = "install install-man";

  runtimePath = stdenv.lib.makeBinPath [getconf erlang socat ps'];
  postInstall = ''
    echo 'PATH=${runtimePath}:''${PATH:+:}$PATH' >> $out/sbin/rabbitmq-env

    # we know exactly where rabbitmq is gonna be,
    # so we patch that into the env-script
    substituteInPlace $out/sbin/rabbitmq-env \
      --replace 'RABBITMQ_SCRIPTS_DIR=`dirname $SCRIPT_PATH`' \
                "RABBITMQ_SCRIPTS_DIR=$out/sbin"

    # there’s a few stray files that belong into share
    mkdir -p $doc/share/doc/rabbitmq-server
    mv $out/LICENSE* $doc/share/doc/rabbitmq-server

    # and an unecessarily copied INSTALL file
    rm $out/INSTALL

    # patched into a source file above;
    # needs to be explicitely passed to not be stripped by fixup
    mkdir -p $out/nix-support
    echo "${getconf}" > $out/nix-support/dont-strip-getconf
  '';

  meta = {
    homepage = http://www.rabbitmq.com/;
    description = "An implementation of the AMQP messaging protocol";
    license = stdenv.lib.licenses.mpl11;
    platforms = stdenv.lib.platforms.unix;
    maintainers = with stdenv.lib.maintainers; [ Profpatsch ];
  };
}
