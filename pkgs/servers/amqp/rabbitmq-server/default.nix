{ stdenv, fetchurl, erlang, elixir, python, libxml2, libxslt, xmlto
, docbook_xml_dtd_45, docbook_xsl, zip, unzip, rsync, glibc, socat

, AppKit, Carbon, Cocoa
}:

stdenv.mkDerivation rec {
  name = "rabbitmq-server-${version}";

  version = "3.7.3";

  src = fetchurl {
    url = "https://github.com/rabbitmq/rabbitmq-server/releases/download/v${version}/${name}.tar.xz";
    sha256 = "0b1729v91cl0f9sxqzvfsnkvd04z0imb6sjd9x0c43phrzqsi9jx";
  };

  buildInputs =
    [ erlang elixir python libxml2 libxslt xmlto docbook_xml_dtd_45 docbook_xsl zip unzip rsync ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ AppKit Carbon Cocoa ];

  preBuild =
    ''
      # Fix the "/usr/bin/env" in "calculate-relative".
      patchShebangs .
    '';

  installFlags = "PREFIX=$(out) RMQ_ERLAPP_DIR=$(out)";
  installTargets = "install install-man";

  runtimePath = stdenv.lib.makeBinPath [glibc erlang socat];
  postInstall =
    ''
      echo 'PATH=${runtimePath}:''${PATH:+:}$PATH' >> $out/sbin/rabbitmq-env
    '';

  meta = {
    homepage = http://www.rabbitmq.com/;
    description = "An implementation of the AMQP messaging protocol";
    platforms = stdenv.lib.platforms.unix;
  };
}
