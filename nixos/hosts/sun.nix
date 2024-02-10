# Minisforum UM790 Pro

{ config, lib, pkgs, ... }:

with lib;

let
  allHosts = [ "ant" "sun" "dew" "jet" "way" ];
  secrets = import ../secrets.nix;
in {
  imports = [ ../hardware/amd.nix ../roles/common.nix ../roles/server.nix ];

  networking.hostName = "sun";

  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
  boot.initrd.availableKernelModules = [ "nvme" ];
  networking.firewall.allowedUDPPorts = [ 41642 ];
  environment.persistence."/nix/persist/system".directories =
    [ "/var/lib/persist" ];
  services = {
    tailscale.port = 41642;
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
              "https://raw.githubusercontent.com/prometheus/snmp_exporter/v0.25.0/snmp.yml";
            hash = "sha256-MYV7iQ/J5z6L3yURrVH3W3XP1DF7n0q1XiO5jhAXKbU=";
          };
        };
      };
      globalConfig.scrape_interval = "10s";
      scrapeConfigs = let
        blackboxTargets = [ "1.1.1.1" "8.8.8.8" ];
        blackboxTCPTargets =
          lists.forEach blackboxTargets (target: "${target}:443");
        blackboxICMPTargets = blackboxTargets ++ allHosts;
      in lists.flatten (lists.forEach allHosts (host:
        attrsets.mapAttrsToList (module: targets: {
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
              targets = lists.forEach allHosts (target:
                "${target}:${
                  builtins.toString
                  config.services.prometheus.exporters.node.port
                }");
            }];
          }
          {
            job_name = "snmp";
            metrics_path = "/snmp";
            static_configs = [{ targets = [ "10.0.0.3" ]; }];
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
              targets = lists.forEach allHosts (target:
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
          {
            job_name = "dnsmasq";
            static_configs = [{ targets = [ "way:9153" ]; }];
          }
          {
            job_name = "nftables";
            static_configs = [{ targets = [ "way:8080" ]; }];
            metric_relabel_configs = [
              {
                source_labels = [ "ip_address" ];
                target_label = "name";
                regex = "^(.*)$";
                replacement = "unknown: $1";
              }
              {
                source_labels = [ "ip_address" ];
                target_label = "name";
                regex = "^(100.*)$";
                replacement = "tailscale: $1";
              }
              {
                source_labels = [ "ip_address" ];
                target_label = "name";
                regex = "^127.0.0.1$";
                replacement = "way";
              }
            ] ++ attrsets.mapAttrsToList (name: host: {
              source_labels = [ "ip_address" ];
              target_label = "name";
              regex = "^${host.ip}$";
              replacement = name;
            }) secrets.dhcpHosts;
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
