{ stdenv, fetchurl, erlang, elixir, python, libxml2, libxslt, xmlto
, docbook_xml_dtd_45, docbook_xsl, zip, unzip, rsync, getconf, socat
, procps, coreutils, gnused, systemd, glibcLocales
, AppKit, Carbon, Cocoa
}:

stdenv.mkDerivation rec {
  name = "rabbitmq-server-${version}";

  version = "3.7.8";

  src = fetchurl {
    url = "https://github.com/rabbitmq/rabbitmq-server/releases/download/v${version}/${name}.tar.xz";
    sha256 = "00jsix333g44y20psrp12c96b7d161yvrysnygjjz4wc5gbrzlxy";
  };

  buildInputs =
    [ erlang elixir python libxml2 libxslt xmlto docbook_xml_dtd_45 docbook_xsl zip unzip rsync glibcLocales ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ AppKit Carbon Cocoa ];

  outputs = [ "out" "man" "doc" ];

  installFlags = "PREFIX=$(out) RMQ_ERLAPP_DIR=$(out)";
  installTargets = "install install-man";

  preBuild = ''
    export LANG=en_US.UTF-8 # fix elixir locale warning
  '';

  runtimePath = stdenv.lib.makeBinPath [
    erlang
    getconf # for getting memory limits
    socat systemd procps # for systemd unit activation check
    gnused coreutils # used by helper scripts
  ];
  postInstall = ''
    # rabbitmq-env calls to sed/coreutils, so provide everything early
    sed -i $out/sbin/rabbitmq-env -e '2s|^|PATH=${runtimePath}\''${PATH:+:}\$PATH/\n|'

    # rabbitmq-server script uses `dirname` to get hold of a
    # rabbitmq-env, so let's provide this file directly. After that
    # point everything is OK - the PATH above will kick in
    substituteInPlace $out/sbin/rabbitmq-server \
      --replace '`dirname $0`/rabbitmq-env' \
                "$out/sbin/rabbitmq-env"

    # We know exactly where rabbitmq is gonna be, so we patch that into the env-script.
    # By doing it early we make sure that auto-detection for this will
    # never be executed (somewhere below in the script).
    sed -i $out/sbin/rabbitmq-env -e "2s|^|RABBITMQ_SCRIPTS_DIR=$out/sbin\n|"

    # there’s a few stray files that belong into share
    mkdir -p $doc/share/doc/rabbitmq-server
    mv $out/LICENSE* $doc/share/doc/rabbitmq-server

    # and an unecessarily copied INSTALL file
    rm $out/INSTALL
  '';

  meta = {
    homepage = http://www.rabbitmq.com/;
    description = "An implementation of the AMQP messaging protocol";
    license = stdenv.lib.licenses.mpl11;
    platforms = stdenv.lib.platforms.unix;
    maintainers = with stdenv.lib.maintainers; [ Profpatsch ];
  };
}
