# modules/devops/databases.nix
#
# NixOS module for local development database services and management tooling.
#
# WHAT THIS FILE OWNS:
#   - PostgreSQL service (services.postgresql)
#   - Redis service (services.redis)
#   - SQLite (library + CLI, no daemon needed)
#   - MongoDB CLI tools
#   - DB management GUIs (DBGate, MongoDB Compass)
#   - Improved CLI clients (pgcli, litecli, usql, redis-cli)
#
# WHAT THIS FILE DOES NOT OWN:
#   - Database data directories — managed by their respective services,
#     stored in /var/lib/postgresql, /var/lib/redis, etc.
#   - Application-level schemas and migrations — those live in project repos
#   - Production credentials — never in Nix, use sops-nix (see secrets.nix)
#
# SERVICE vs PACKAGE DISTINCTION:
#   PostgreSQL and Redis need system services (daemons). SQLite is just a
#   library — no service. MongoDB is excluded from the service definition
#   below (see rationale in the MongoDB section).
#
# ENABLE:
#   devops.databases.enable = true;  in your host configuration.nix
#
# FIRST-TIME SETUP (PostgreSQL):
#   After nixos-rebuild switch, create your dev superuser:
#     sudo -u postgres psql
#     CREATE USER cypher_dev WITH SUPERUSER PASSWORD 'devpassword';
#     CREATE DATABASE cypher_dev OWNER cypher_dev;
#     \q
#   Then connect:
#     psql -U cypher_dev -d cypher_dev
#     pgcli -U cypher_dev cypher_dev   (nicer alternative)
#
# FIRST-TIME SETUP (Redis):
#   Redis starts automatically. No auth in dev (see securityConfig below).
#     redis-cli ping   → PONG
#
# VERIFYING THE SETUP:
#   systemctl status postgresql
#   systemctl status redis
#   psql --version
#   redis-cli --version
#   sqlite3 --version
#   pgcli --version

{ config, pkgs, lib, ... }:

{
  # ── Module Option ────────────────────────────────────────────────────────────
  options.cypher-os.devops.databases.enable = lib.mkEnableOption
    "local development database services (PostgreSQL, Redis, SQLite, MongoDB tools)";

  config = lib.mkIf config.cypher-os.devops.databases.enable {

    # ── PostgreSQL ─────────────────────────────────────────────────────────────
    # The most capable open-source Relational DBMS. Prisma-based Next.js projects
    # can target this locally
    #
    # The NixOS postgresql module manages:
    #   - The PostgreSQL data directory (/var/lib/postgresql/<version>/)
    #   - The postgres system user and group
    #   - The systemd service unit
    #   - Initial database cluster creation (initdb)
    services.postgresql = {
      enable = true;

      # package: pinned to a specific major version. Pinning is important because
      # PostgreSQL requires a manual upgrade process between major versions (pg_upgrade).
      # nixpkgs ships multiple versions simultaneously. 16 is current stable LTS.
      # Change to pkgs.postgresql_17 when you're ready to upgrade and run pg_upgrade.
      package = pkgs.postgresql_16;

      # enableTCPIP: allow connections over TCP (127.0.0.1), not just the Unix socket.
      # Required for most ORMs (Prisma, SQLAlchemy) and GUI clients (DBGate, pgcli).
      enableTCPIP = true;

      # authentication: pg_hba.conf rules. Controls who can connect, from where,
      # and with what auth method.
      # FORMAT: type  database  user  address  method
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
        log_connections    = true;
        log_disconnections = true;

        # Tuning for a dev machine (not production values):
        # shared_buffers: ~25% of RAM is the production recommendation.
        # On a dev machine, 256MB is fine.
        shared_buffers = "256MB";
      };

      # ensureDatabases / ensureUsers: declaratively create databases and users
      # on first startup. These are idempotent — safe to leave here permanently.
      # Note: ensureUsers cannot set passwords (security constraint). Set the
      # password manually once: ALTER USER cypher_dev WITH PASSWORD 'yourpassword';
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
    # In-memory data structure store. Upstash Redis usage in Next.js projects
    # can be tested locally against this instance.
    #
    # NixOS supports multiple named Redis instances: services.redis.servers.<name>.
    # We declare one "dev" instance. Ports are configurable per instance.
    services.redis.servers.dev = {
      enable = true;

      # bind: only accept connections from localhost. Never expose Redis to the
      # network — it has no authentication in this config.
      bind = "127.0.0.1";

      # port: default Redis port. Change if you need multiple instances or have
      # a conflict. Your app's REDIS_URL will be: redis://127.0.0.1:6379
      port = 6379;

      # requirePass: UNSET here for local dev convenience. For staging/prod,
      # use sops-nix to inject the password as a secret:
      #   requirePassFile = config.sops.secrets.redis_password.path;
      # requirePass = "devpassword";  # uncomment for local auth testing

      # save: RDB snapshot intervals. Format: [[seconds changes] ...]
      # This is a dev instance — disable persistence if you want a clean slate
      # every restart, or keep these defaults for persistence.
      save = [
        [900 1]   # save after 900s if at least 1 key changed
        [300 10]  # save after 300s if at least 10 keys changed
        [60  10000] # save after 60s if at least 10000 keys changed
      ];

      # loglevel: "debug" | "verbose" | "notice" | "warning"
      # "notice" is appropriate for dev — less noise than "verbose".
      settings.loglevel = "notice";
    };

    # ── System Packages ────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [

      # ── PostgreSQL Tooling ────────────────────────────────────────────────────
      # pgcli: PostgreSQL CLI with autocomplete, syntax highlighting, and
      # multi-line editing. Replace bare `psql` for interactive sessions.
      # Usage: pgcli -U cypher_dev cypher_dev
      pgcli

      # ── SQLite ────────────────────────────────────────────────────────────────
      # sqlite: the SQLite CLI (sqlite3). No daemon — SQLite is a file-based DB.
      # Also installs the shared library used by applications linking against SQLite.
      sqlite

      # litecli: SQLite CLI with autocomplete and syntax highlighting.
      # Same quality-of-life improvement that pgcli gives PostgreSQL, but for SQLite.
      # Usage: litecli path/to/database.db
      litecli

      # ── Redis Tooling ─────────────────────────────────────────────────────────
      # redis: installs redis-cli. The Redis server is declared above as a service;
      # this adds the CLI client for interactive use.
      # Usage: redis-cli ping   redis-cli monitor   redis-cli --scan
      redis

      # ── Universal SQL Client ──────────────────────────────────────────────────
      # usql: universal SQL CLI that speaks PostgreSQL, MySQL, SQLite, and more
      # using a single tool and consistent syntax. Good for polyglot projects.
      # Usage: usql pg://cypher_dev@localhost/cypher_dev
      usql

      # ── MongoDB CLI Tools ─────────────────────────────────────────────────────
      # mongodb-tools: official MongoDB utilities — mongodump, mongorestore,
      # mongoexport, mongoimport, mongostat, mongotop. Essential for backup,
      # migration, and data inspection workflows.
      mongodb-tools

      # mongodb-atlas-cli: CLI for MongoDB Atlas (the cloud offering). Manage
      # clusters, users, backups, and data from the terminal.
      # Usage: atlas --help
      mongodb-atlas-cli

      # ── GUI Clients ───────────────────────────────────────────────────────────
      # dbgate: universal open-source DB GUI. Supports PostgreSQL, MySQL, SQLite,
      # MongoDB, Redis, and more in one app. Good default choice.
      # Run: dbgate
      dbgate

      # mongodb-compass: official MongoDB GUI. Better MongoDB-specific features
      # than DBGate (schema visualization, explain plans, aggregation builder).
      # Use DBGate for day-to-day; Compass for deep MongoDB work.
      mongodb-compass

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # MongoDB server (mongod) is not declared as a service here.
      # Reason: mongod on NixOS has had packaging inconsistencies, and MongoDB's
      # licensing (SSPL) makes nixpkgs inclusion complicated. For local MongoDB
      # dev, prefer:
      #   1. A Docker container: docker run -d -p 27017:27017 mongo:latest
      #   2. MongoDB Atlas free tier (cloud, no local setup)
      #   3. When the nixpkgs package stabilizes, add services.mongodb here.
      # mongodb  # uncomment if/when services.mongodb becomes stable in nixpkgs
    ];

  };
}
