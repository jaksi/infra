# Minisforum UM790 Pro

{ config, lib, pkgs, ... }:

let
  allHosts = [ "ant" "sun" "dew" "jet" ];
  secrets = import ../secrets.nix;
in {
  imports = [ ../hardware/amd.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "sun";
  programs.tmux.extraConfig = ''
    set -g window-status-current-style fg=#eff1f5,bg=#1e66f5
  '';

  boot.initrd.availableKernelModules = [ "nvme" ];
  environment.persistence."/nix/persist/system".directories =
    [ "/var/lib/persist" ];
  services = {
    tailscale.extraUpFlags = [ "--advertise-routes=192.168.1.0/24" ];
    prometheus = {
      enable = true;
      stateDir = "persist/prometheus";
      exporters = {
        domain = {
          enable = true;
          listenAddress = "localhost";
        };
        snmp = {
          enable = true;
          listenAddress = "localhost";
          configurationPath = pkgs.fetchurl {
            url =
              "https://raw.githubusercontent.com/prometheus/snmp_exporter/v0.22.0/snmp.yml";
            hash = "sha256-vzb7aqaRWjxv4x/Ujqqc5T5h/JspuxYNS7A9zTqc6os=";
          };
        };
      };
      globalConfig.scrape_interval = "10s";
      scrapeConfigs = let
        blackboxTargets = [ "1.1.1.1" "8.8.8.8" ];
        blackboxTCPTargets =
          lib.lists.forEach blackboxTargets (target: "${target}:443");
        blackboxICMPTargets = blackboxTargets ++ allHosts;
      in lib.lists.flatten (lib.lists.forEach allHosts (host:
        lib.attrsets.mapAttrsToList (module: targets: {
          job_name = "blackbox_${module}_${host}";
          metrics_path = "/probe";
          params.module = [ module ];
          static_configs = [{ targets = targets; }];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "${host}:${
                  builtins.toString
                  config.services.prometheus.exporters.blackbox.port
                }";
            }
          ];
        }) {
          icmp = blackboxICMPTargets;
          dns = blackboxTargets;
          tcp = blackboxTCPTargets;
          tls = blackboxTCPTargets;
        })) ++ [
          {
            job_name = "prometheus";
            static_configs = [{
              targets = [
                "localhost:${builtins.toString config.services.prometheus.port}"
              ];
            }];
          }
          {
            job_name = "grafana";
            static_configs = [{
              targets = [
                "localhost:${
                  builtins.toString
                  config.services.grafana.settings.server.http_port
                }"
              ];
            }];
          }
          {
            job_name = "domain";
            metrics_path = "/probe";
            static_configs = [{ targets = [ "jaksi.dev" ]; }];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                target_label = "__address__";
                replacement = "localhost:${
                    builtins.toString
                    config.services.prometheus.exporters.domain.port
                  }";
              }
            ];
          }
          {
            job_name = "node";
            static_configs = [{
              targets = lib.lists.forEach allHosts (target:
                "${target}:${
                  builtins.toString
                  config.services.prometheus.exporters.node.port
                }");
            }];
          }
          {
            job_name = "snmp";
            metrics_path = "/snmp";
            static_configs = [{ targets = [ "192.168.1.4" ]; }];
            params.module = [ "synology" ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "localhost:${
                    builtins.toString
                    config.services.prometheus.exporters.snmp.port
                  }";
              }
            ];
            metric_relabel_configs = [{
              source_labels = [ "__name__" ];
              target_label = "__name__";
              replacement = "snmp_$1";
            }];
          }
          {
            job_name = "systemd";
            static_configs = [{
              targets = lib.lists.forEach allHosts (target:
                "${target}:${
                  builtins.toString
                  config.services.prometheus.exporters.systemd.port
                }");
            }];
          }
          {
            job_name = "home-assistant";
            metrics_path = "/api/prometheus";
            bearer_token = secrets.prometheusHomeAssistantToken;
            static_configs = [{
              targets = [
                "localhost:${
                  builtins.toString
                  config.services.home-assistant.config.http.server_port
                }"
              ];
            }];
          }
        ];
    };
    grafana = {
      enable = true;
      dataDir = "/nix/persist/grafana";
      settings = {
        server.http_addr = "0.0.0.0";
        "auth.proxy" = {
          enabled = true;
          header_name = "X-WEBAUTH-USER";
        };
        "auth" = {
          disable_signout_menu = true;
          disable_login_form = true;
        };
        users.default_theme = "system";
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${
              builtins.toString config.services.prometheus.port
            }";
        }];
      };
    };
    mosquitto = {
      enable = true;
      persistence = false;
      listeners = [{
        address = "localhost";
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }];
    };
    zigbee2mqtt = {
      enable = true;
      dataDir = "/nix/persist/zigbee2mqtt";
      settings.frontend.port = 8081;
    };
    home-assistant = {
      enable = true;
      configDir = "/nix/persist/home-assistant";
      extraComponents = [ "default_config" "mqtt" "met_eireann" "roomba" ];
      config = {
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" "::1" ];
        };
        default_config = { };
        homeassistant = {
          auth_providers = [{
            type = "trusted_networks";
            trusted_networks = [ "0.0.0.0/0" "::/0" ];
            allow_bypass_login = true;
          }];
        };
        prometheus = { };
      };
    };
  };
}
