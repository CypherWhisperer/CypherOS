# modules/devops/databases.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.databases.enable) {

    # ── PostgreSQL ─────────────────────────────────────────────────────────────
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16; # Change to _17 when  needed and run pg_upgrade.
      enableTCPIP = true;

      # authentication: pg_hba.conf rules. Controls who can connect, from where,
      # and with what auth method:
      #   local  = Unix socket connections
      #   host   = TCP/IP connections
      #   md5    = password (hashed). scram-sha-256 is stronger but less compatible.
      #   trust  = no password (dev only — never in production)
      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE  USER      ADDRESS         METHOD
        local   all       postgres                  trust
        local   all       all                       md5
        host    all       all       127.0.0.1/32    md5
        host    all       all       ::1/128         md5
      '';

      # settings: postgresql.conf parameters.
      settings = {
        # log_connections / log_disconnections: useful during development to see
        # all connection activity in `journalctl -u postgresql`.
        log_connections = true;
        log_disconnections = true;

        # Tuning for a dev machine (not production values):
        # shared_buffers: ~25% of RAM is the production recommendation.
        # On a dev machine, 256MB is fine.
        shared_buffers = "256MB";
      };

      ensureDatabases = [ "cypher_dev" ];
      ensureUsers = [
        {
          name = "cypher_dev";
          # ensureDBOwnership: makes cypher_dev the owner of the cypher_dev database.
          ensureDBOwnership = true;
        }
      ];
    };

    # ── Redis ──────────────────────────────────────────────────────────────────
    services.redis.servers.dev = {
      enable = true;
      bind = "127.0.0.1";
      port = 6379;

      # requirePass: UNSET here for local dev convenience. For staging/prod,
      # use sops-nix to inject the password as a secret:
      #   requirePassFile = config.sops.secrets.redis_password.path;
      # requirePass = "devpassword";  # uncomment for local auth testing

      save = [
        [
          900
          1
        ]
        [
          300
          10
        ]
        [
          60
          10000
        ]
      ];

      # loglevel: "debug" | "verbose" | "notice" | "warning"
      # "notice" is appropriate for dev — less noise than "verbose".
      settings.loglevel = "notice";
    };

    environment.systemPackages = with pkgs; [

      # ── PostgreSQL tooling ────────────────────────────────────────────────────
      pgcli # psql replacement with autocomplete and syntax highlighting

      # pgvector: PostgreSQL extension for vector similarity search. Required for
      # AI/ML workloads (embeddings, RAG pipelines) that store vectors alongside
      # relational data. Installed as a package — must be enabled per-database:
      #   CREATE EXTENSION vector;
      # See: https://github.com/pgvector/pgvector
      #
      # pgvector # Currently (2026-05-29) missing from nixpkgs; install manually if needed:

      # ── SQLite ────────────────────────────────────────────────────────────────
      sqlite # file-based DB; no daemon
      litecli # sqlite CLI with autocomplete and syntax highlighting

      # ── Redis tooling ─────────────────────────────────────────────────────────
      redis # installs redis-cli; the server is the service above

      # ── Universal SQL client ──────────────────────────────────────────────────
      usql # single CLI for PostgreSQL, MySQL, SQLite, and more

      # ── MongoDB CLI tools ─────────────────────────────────────────────────────
      mongodb-tools # mongodump, mongorestore, mongoexport, mongoimport, mongostat
      mongodb-atlas-cli # manage Atlas cloud clusters from the terminal

      # ── ClickHouse ────────────────────────────────────────────────────────────
      # Column-oriented OLAP database. Extremely fast for analytical queries over
      # large datasets. Increasingly common in observability stacks (as a Loki
      # backend), data engineering pipelines, and anywhere you'd outgrow PostgreSQL
      # for read-heavy analytics. CLI only here — run the server via Docker:
      #   docker run -d -p 8123:8123 -p 9000:9000 clickhouse/clickhouse-server
      clickhouse # installs clickhouse-client CLI

      # ── GUI clients ───────────────────────────────────────────────────────────
      dbgate # universal open-source DB GUI; PostgreSQL, MySQL, SQLite, MongoDB, Redis
      mongodb-compass # official MongoDB GUI; use for deep MongoDB work (explain plans, aggregations)

      # ── EXCLUDED ──────────────────────────────────────────────────────────────
      # mongod (server)  # SSPL license makes nixpkgs inclusion unreliable; use Docker instead:
      #                  #   docker run -d -p 27017:27017 mongo:latest
      # uncomment if/when services.mongodb becomes stable in nixpkgs
    ];

  };
}
