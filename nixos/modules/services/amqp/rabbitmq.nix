{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rabbitmq;

  inherit (builtins) concatStringsSep;

  config_file_content = lib.generators.toKeyValue {} cfg.configItems;
  config_file = pkgs.writeText "rabbitmq.conf" config_file_content;

  advanced_config_file = pkgs.writeText "advanced.config" cfg.config;

in {
  ###### interface
  options = {
    services.rabbitmq = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable the RabbitMQ server, an Advanced Message
          Queuing Protocol (AMQP) broker.
        '';
      };

      package = mkOption {
        default = pkgs.rabbitmq-server;
        type = types.package;
        defaultText = "pkgs.rabbitmq-server";
        description = ''
          Which rabbitmq package to use.
        '';
      };

      listenAddress = mkOption {
        default = "127.0.0.1";
        example = "";
        description = ''
          IP address on which RabbitMQ will listen for AMQP
          connections.  Set to the empty string to listen on all
          interfaces.  Note that RabbitMQ creates a user named
          <literal>guest</literal> with password
          <literal>guest</literal> by default, so you should delete
          this user if you intend to allow external access.

          Together with 'port' setting it's mostly an alias for
          configItems."listeners.tcp.1" and it's left for backwards
          compatibility with previous version of this module.
        '';
        type = types.str;
      };

      port = mkOption {
        default = 5672;
        description = ''
          Port on which RabbitMQ will listen for AMQP connections.
        '';
        type = types.int;
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/rabbitmq";
        description = ''
          Data directory for rabbitmq.
        '';
      };

      cookie = mkOption {
        default = "";
        type = types.str;
        description = ''
          Erlang cookie is a string of arbitrary length which must
          be the same for several nodes to be allowed to communicate.
          Leave empty to generate automatically.
        '';
      };

      configItems = mkOption {
        default = {};
        type = types.attrsOf types.str;
        example = ''
          {
            "auth_backends.1.authn" = "rabbit_auth_backend_ldap";
            "auth_backends.1.authz" = "rabbit_auth_backend_internal";
          }
        '';
        description = ''
          New style config options.

          See http://www.rabbitmq.com/configure.html
        '';
      };

      config = mkOption {
        default = "";
        type = types.str;
        description = ''
          Verbatim advanced configuration file contents.
          Prefered way is to use configItems.

          See http://www.rabbitmq.com/configure.html
        '';
      };

      plugins = mkOption {
        default = [];
        type = types.listOf types.str;
        description = "The names of plugins to enable";
      };

      pluginDirs = mkOption {
        default = [];
        type = types.listOf types.path;
        description = "The list of directories containing external plugins";
      };
    };
  };


  ###### implementation
  config = mkIf cfg.enable {

    # This is needed so we will have 'rabbitmqctl' in our PATH
    environment.systemPackages = [ cfg.package ];

    services.epmd.enable = true;

    users.users.rabbitmq = {
      description = "RabbitMQ server user";
      home = "${cfg.dataDir}";
      createHome = true;
      group = "rabbitmq";
      uid = config.ids.uids.rabbitmq;
    };

    users.groups.rabbitmq.gid = config.ids.gids.rabbitmq;

    services.rabbitmq.configItems = {
      "listeners.tcp.1" = mkDefault "${cfg.listenAddress}:${toString cfg.port}";
    };

    systemd.services.rabbitmq = {
      description = "RabbitMQ Server";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "epmd.socket" ];
      wants = [ "network.target" "epmd.socket" ];

      path = [
        cfg.package
        pkgs.coreutils # mkdir/chown/chmod for preStart
      ];

      environment = {
        RABBITMQ_MNESIA_BASE = "${cfg.dataDir}/mnesia";
        RABBITMQ_LOGS = "-";
        SYS_PREFIX = "";
        RABBITMQ_CONFIG_FILE = config_file;
        RABBITMQ_PLUGINS_DIR = concatStringsSep ":" cfg.pluginDirs;
        RABBITMQ_ENABLED_PLUGINS_FILE = pkgs.writeText "enabled_plugins" ''
          [ ${concatStringsSep "," cfg.plugins} ].
        '';
      } //  optionalAttrs (cfg.config != "") { RABBITMQ_ADVANCED_CONFIG_FILE = advanced_config_file; };

      serviceConfig = {
        PermissionsStartOnly = true; # preStart must be run as root
        ExecStart = "${cfg.package}/sbin/rabbitmq-server";
        ExecStop = "${cfg.package}/sbin/rabbitmqctl shutdown";
        User = "rabbitmq";
        Group = "rabbitmq";
        WorkingDirectory = cfg.dataDir;
        Type = "notify";
        NotifyAccess = "all";
        UMask = "0027";
        LimitNOFILE = "100000";
        Restart = "on-failure";
        RestartSec = "10";
        TimeoutStartSec = "3600";
      };

      preStart = ''
        ${optionalString (cfg.cookie != "") ''
            echo -n ${cfg.cookie} > ${cfg.dataDir}/.erlang.cookie
            chown rabbitmq:rabbitmq ${cfg.dataDir}/.erlang.cookie
            chmod 600 ${cfg.dataDir}/.erlang.cookie
        ''}
        mkdir -p /var/log/rabbitmq
        chown rabbitmq:rabbitmq /var/log/rabbitmq
      '';
    };

  };

}
