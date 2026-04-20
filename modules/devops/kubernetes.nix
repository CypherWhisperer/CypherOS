# modules/devops/kubernetes.nix
#
# NixOS module for Kubernetes tooling: k3s cluster, kubectl, Helm,
# local cluster runners, and operational utilities.
#
# WHAT THIS FILE OWNS:
#   - k3s system service (services.k3s)
#   - All kubectl-adjacent CLIs
#   - Helm package manager
#   - Local dev cluster tools (k3d, kind)
#   - Log viewers, secret inspectors, and cluster utilities
#
# WHAT THIS FILE DOES NOT OWN:
#   - Application manifests and Helm charts — those live in project repos
#   - kubeconfig — generated at runtime, stored in ~/.kube/config (never in Nix)
#   - Cluster state — ephemeral by design
#
# K3S vs KUBERNETES (FULL):
#   k3s is a CNCF-certified Kubernetes distribution in a single binary (~60 MB).
#   It removes alpha features, uses sqlite instead of etcd by default, and bundles
#   containerd. Functionally identical to upstream k8s for everything you'll do
#   at beginner stage. The full `kubernetes` package installs the upstream binaries
#   (kubeadm, kubelet, etc.) — Not needed  when running k3s.
#
#   Decision: k3s is enabled. Full kubernetes is commented out with rationale.
#
# K3D vs KIND (LOCAL CLUSTER TOOLS):
#   Both run Kubernetes inside Docker containers for local testing.
#   - k3d: wraps k3s in Docker. Faster startup, lighter, consistent with k3s.
#   - kind: runs upstream k8s in Docker. More "vanilla" — closer to what you'd
#     find in a cloud provider. Slower but more faithful to production clusters.
#   Both are included: use k3d for speed, kind when you need upstream fidelity.
#
# ENABLE:
#   devops.kubernetes.enable = true;  in host configuration.nix
#
# FIRST-TIME SETUP (after nixos-rebuild switch):
#   k3s starts as a systemd service. Access the cluster:
#     sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
#     chmod 600 ~/.kube/config
#     kubectl get nodes   # should show your node as Ready
#
#   For k3d clusters (doesn't use the k3s service above — runs in Docker):
#     k3d cluster create dev
#     kubectl get nodes
#
#   For kind clusters:
#     kind create cluster --name dev
#     kubectl get nodes
#
# VERIFYING THE SETUP:
#   kubectl version --client
#   helm version
#   k3d version
#   kind version
#   kail --version

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.devops.enable &&
    config.cypher-os.devops.kubernetes.enable ) {

    # ── k3s Service ────────────────────────────────────────────────────────────
    # k3s runs as a system service. This makes it start on boot and be managed
    # by systemd. For a dev machine, you may prefer manual start:
    #   services.k3s.enable = true;
    #   systemctl start k3s   (manual, on demand)
    # vs
    #   boot.startK3s = true; (automatic at boot)
    # We enable the service but set it to not start automatically at boot —
    # saves resources when you're not doing k8s work.
    services.k3s = {
      enable = true;

      # role: "server" means this node runs the control plane (API server, scheduler,
      # controller manager) + a worker. "agent" means worker-only, connecting to a
      # remote server. For a single dev machine, "server" is correct.
      role = "server";

      # extraFlags: additional flags passed to the k3s server binary.
      # --write-kubeconfig-mode 644: makes the generated kubeconfig world-readable
      # so you don't need sudo every time. Only do this on a single-user dev machine.
      extraFlags = toString [
        "--write-kubeconfig-mode 644"
        # "--disable traefik"  # uncomment if you prefer to install your own ingress controller
        # "--disable servicelb" # uncomment if you prefer MetalLB or no load balancer
      ];
    };

    # Disable k3s autostart at boot — start manually when needed:
    #   sudo systemctl start k3s
    # Change to true if you want k3s always running.
    systemd.services.k3s.wantedBy = lib.mkForce [];

    # ── System Packages ────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [

      # ── Core Kubernetes CLI ───────────────────────────────────────────────────
      # kubectl: the universal Kubernetes CLI. Works with k3s, k3d, kind, EKS,
      # GKE, AKS — any cluster that speaks the Kubernetes API. Non-negotiable.
      kubectl

      # kubernetes-helm: Helm v3. The de-facto package manager for Kubernetes.
      # Charts are pre-packaged Kubernetes manifests with configurable values.
      # You'll use this to install things like ingress controllers, cert-manager,
      # monitoring stacks, etc. without writing the YAML yourself.
      kubernetes-helm

      # kubernetes-helm-wrapped: Helm with a NixOS path wrapper that handles
      # plugin binary paths correctly. In practice, helm and helm-wrapped are
      # equivalent for manual use. The wrapped version is needed in some
      # automated/scripting contexts where PATH isn't set up the usual way.
      # Included but you'll likely only ever type `helm` (which hits the unwrapped one).
      kubernetes-helm-wrapped

      # ── Local Dev Cluster Tools ───────────────────────────────────────────────
      # k3d: run k3s clusters inside Docker containers. Faster than kind,
      # consistent with the k3s service above. Great for:
      #   - Throwaway clusters for feature testing
      #   - Multi-node cluster simulation on one machine
      #   - CI-like environments locally
      # Usage: k3d cluster create dev --agents 2
      k3d

      # kind: Kubernetes IN Docker. Runs upstream k8s (not k3s) in Docker.
      # Use when you need vanilla k8s behavior (e.g. testing against specific
      # upstream API behavior, or when a tool only supports full k8s).
      # Slower startup than k3d.
      # Usage: kind create cluster --name dev
      kind

      # ── Cluster Utilities ─────────────────────────────────────────────────────
      # kail: streaming log viewer across multiple pods/namespaces simultaneously.
      # Much nicer than running multiple `kubectl logs -f` windows.
      # Usage: kail --ns default   (stream all logs in namespace)
      #        kail -l app=nginx   (stream logs for a label selector)
      kail

      # kubectl-view-secret: decode and display Kubernetes secrets in plaintext.
      # kubectl get secret <n> -o jsonpath=... | base64 -d gets tedious fast.
      # Usage: kubectl view-secret <secret-name> [key]
      kubectl-view-secret

      # kubeprompt: displays current k8s context/namespace in your shell prompt.
      # Your p10k setup may already show this via its kubectl segment — compare
      # and pick one. kubeprompt is standalone if p10k's segment doesn't suit you.
      kubeprompt

      # ── DEFERRED — Operational / Advanced Tools ───────────────────────────────
      # The tools below are genuinely useful but premature at the learning stage.
      # Uncomment as you grow into them. Comments explain when each becomes relevant.

      # kubernetes: full upstream Kubernetes binaries (kubeadm, kubelet, etc.).
      # NOT needed when running k3s — k3s bundles its own versions. Only relevant
      # if you move to a kubeadm-bootstrapped cluster or baremetal production setup.
      # kubernetes

      # kubernetes-metrics-server: Kubernetes Metrics Server for `kubectl top`.
      # Needed for HPA (Horizontal Pod Autoscaler) to work. Deploy into your cluster
      # as a manifest, not a host package:
      #   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
      # kubernetes-metrics-server

      # kubernetes-polaris: policy enforcement / best practices scanner.
      # Checks your manifests against production-readiness standards (resource limits,
      # security contexts, etc.). Great once you're writing real workloads.
      # kubernetes-polaris

      # kubernetes-validate: validates Kubernetes manifests against the API schema
      # before applying. Good CI check. Useful when your manifests grow complex.
      # kubernetes-validate

      # kubernetes-code-generator: scaffolds Go client libraries for custom CRDs.
      # Only relevant if you're writing Kubernetes controllers/operators in Go.
      # kubernetes-code-generator

      # kubernetes-controller-tools: generate CRD manifests and RBAC from Go types.
      # Same as above — controller development territory.
      # kubernetes-controller-tools

      # clusterctl: Cluster API CLI. Manages the lifecycle of entire clusters
      # (create, upgrade, delete cloud k8s clusters declaratively).
      # Relevant when you move beyond local dev into cloud cluster management.
      # clusterctl

      # kns: namespace switcher. Quick context/namespace switching in the shell.
      # `kubectl config set-context --current --namespace=<n>` covers this for now.
      # kns

      # kube-review: tests Kubernetes ValidatingWebhookConfigurations locally.
      # Very niche — only needed if you're writing admission webhooks.
      # kube-review

      # kubeaudit: security auditor for live clusters. Checks for missing resource
      # limits, privileged containers, capabilities, etc. Very useful in production.
      # kubeaudit

      # kubeshark: real-time network traffic analyzer for Kubernetes. Like Wireshark
      # for your cluster's internal traffic. Powerful debugging tool.
      # kubeshark

      # kubestroyer: penetration testing tool for Kubernetes clusters.
      # Useful for understanding attack surfaces once you have a cluster to test.
      # kubeclarity

      # kubeclarity: container image and code vulnerability scanning specifically
      # for k8s workloads. Use trivy (in containers.nix) first — overlapping scope.
      # kubeclarity

      # seabird: GUI Kubernetes client (Electron). Alternative to k9s (TUI) or
      # the web dashboard. Try it if you prefer a GUI workflow over kubectl.
      # seabird

      # gitlab-kas: GitLab Kubernetes Agent Server. Only relevant if you're running
      # GitLab CI/CD pipelines that deploy to Kubernetes clusters via the agent.
      # gitlab-kas

      # kubectl-ai: AI-assisted kubectl. Generates kubectl commands from natural
      # language. Fun but not foundational — build the kubectl muscle memory first.
      # kubectl-ai

      # kubernix: run Kubernetes using Nix for the node environment.
      # Interesting for Nix+k8s integration experiments. Very niche.
      # kubernix

      # arion: Docker Compose-style tool backed by Nix. Declare services as Nix
      # modules instead of YAML. Long-term this fits CypherOS philosophy well.
      # Worth revisiting once you're comfortable with both Nix and Compose.
      # arion
    ];

  };
}
