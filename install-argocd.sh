#!/usr/bin/env bash
# =============================================================================
#  install-argocd.sh
#  Installs a NON-HA (single replica) Argo CD for LEARNING purposes.
#  Auto-detects OS (Ubuntu/Debian Linux or macOS) and CPU arch (amd64/arm64).
#
#  What it does:
#    1. Detects OS + architecture
#    2. Installs prerequisites if missing: kubectl, docker, kind
#    3. Uses your current Kubernetes cluster, or creates a local kind cluster
#    4. Installs Argo CD (non-HA manifest) into the "argocd" namespace
#    5. Installs the argocd CLI
#    6. Prints the admin password and how to open the UI
#
#  Usage:
#    chmod +x install-argocd.sh
#    ./install-argocd.sh            # install
#    ./install-argocd.sh uninstall  # remove Argo CD (and the kind cluster it made)
#
#  Optional environment variables:
#    ARGOCD_VERSION=v3.1.0 ./install-argocd.sh   # pin a version (default: stable)
#    KIND_CLUSTER_NAME=my-lab ./install-argocd.sh
# =============================================================================

set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_VERSION="${ARGOCD_VERSION:-stable}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-argocd-lab}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-300s}"

# ---------- pretty logging ----------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ---------- 1. detect OS and architecture ----------
detect_system() {
  case "$(uname -s)" in
    Linux)
      OS="linux"
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${ID:-unknown}"
      else
        DISTRO="unknown"
      fi
      if [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "debian" ]]; then
        warn "Detected Linux distro '$DISTRO'. Script is tested on Ubuntu; continuing anyway."
      fi
      ;;
    Darwin)
      OS="darwin"
      DISTRO="macos"
      ;;
    *)
      error "Unsupported OS: $(uname -s). Only Ubuntu and macOS are supported."
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $(uname -m)" ;;
  esac

  # sudo only when not root (Linux)
  if [[ "$OS" == "linux" && "$EUID" -ne 0 ]]; then SUDO="sudo"; else SUDO=""; fi

  success "Detected system: OS=$OS ($DISTRO), ARCH=$ARCH"
}

# ---------- 2. prerequisites ----------
check_homebrew() {
  if [[ "$OS" == "darwin" ]] && ! command_exists brew; then
    error "Homebrew is required on macOS. Install it first:
  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  fi
}

install_base_tools_linux() {
  if ! command_exists curl; then
    info "Installing curl..."
    $SUDO apt-get update -y && $SUDO apt-get install -y curl ca-certificates
  fi
}

install_kubectl() {
  if command_exists kubectl; then
    success "kubectl already installed"
    return
  fi
  info "Installing kubectl..."
  if [[ "$OS" == "darwin" ]]; then
    brew install kubectl
  else
    local ver
    ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${ver}/bin/linux/${ARCH}/kubectl"
    $SUDO install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
  fi
  success "kubectl installed: $(kubectl version --client 2>/dev/null | head -n1)"
}

install_docker() {
  if command_exists docker; then
    # docker exists, make sure the daemon is reachable
    if docker info >/dev/null 2>&1; then
      success "Docker is installed and running"
      return
    fi
    if [[ "$OS" == "darwin" ]]; then
      if command_exists colima; then
        info "Starting colima..."
        colima start
        return
      fi
      error "Docker is installed but not running. Start Docker Desktop (or OrbStack/colima) and re-run."
    else
      if ! $SUDO docker info >/dev/null 2>&1; then
        info "Starting Docker service..."
        $SUDO systemctl start docker
      fi
      if ! docker info >/dev/null 2>&1; then
        error "Your user can't access Docker. Run:
  sudo usermod -aG docker \$USER && newgrp docker
then re-run this script."
      fi
      return
    fi
  fi

  info "Docker not found, installing it (needed for the local kind cluster)..."
  if [[ "$OS" == "darwin" ]]; then
    # colima = lightweight free Docker runtime for macOS
    brew install colima docker
    colima start --cpu 2 --memory 4
  else
    curl -fsSL https://get.docker.com | $SUDO sh
    $SUDO systemctl enable --now docker
    $SUDO usermod -aG docker "$USER" || true
    warn "Docker installed. Your user was added to the 'docker' group."
    error "Please log out/in (or run 'newgrp docker') and then re-run this script."
  fi
  success "Docker is ready"
}

install_kind() {
  if command_exists kind; then
    success "kind already installed"
    return
  fi
  info "Installing kind..."
  if [[ "$OS" == "darwin" ]]; then
    brew install kind
  else
    curl -fsSLo /tmp/kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-linux-${ARCH}"
    $SUDO install -m 0755 /tmp/kind /usr/local/bin/kind
    rm -f /tmp/kind
  fi
  success "kind installed: $(kind version)"
}

# ---------- 3. cluster ----------
ensure_cluster() {
  if kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
    success "Using existing cluster (context: $(kubectl config current-context))"
    return
  fi

  warn "No reachable Kubernetes cluster found. Creating a local kind cluster '${KIND_CLUSTER_NAME}'..."
  install_docker
  install_kind

  if kind get clusters 2>/dev/null | grep -qx "$KIND_CLUSTER_NAME"; then
    info "kind cluster '${KIND_CLUSTER_NAME}' already exists, switching to it"
    kubectl config use-context "kind-${KIND_CLUSTER_NAME}"
  else
    kind create cluster --name "$KIND_CLUSTER_NAME" --wait 120s
  fi
  success "Cluster ready (context: $(kubectl config current-context))"
}

# ---------- 4. install Argo CD ----------
install_argocd() {
  local manifest_url="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

  info "Creating namespace '${ARGOCD_NAMESPACE}'..."
  kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  info "Applying Argo CD NON-HA manifest (${ARGOCD_VERSION})..."
  # server-side apply avoids the "annotation too long" error on large CRDs
  kubectl apply -n "$ARGOCD_NAMESPACE" --server-side --force-conflicts -f "$manifest_url"

  info "Waiting for Argo CD deployments to become available (timeout ${WAIT_TIMEOUT})..."
  kubectl wait --for=condition=available deployment --all -n "$ARGOCD_NAMESPACE" --timeout="$WAIT_TIMEOUT"
  kubectl rollout status statefulset/argocd-application-controller -n "$ARGOCD_NAMESPACE" --timeout="$WAIT_TIMEOUT"

  success "Argo CD is running"
  kubectl get pods -n "$ARGOCD_NAMESPACE"
}

# ---------- 5. install argocd CLI ----------
install_argocd_cli() {
  if command_exists argocd; then
    success "argocd CLI already installed"
    return
  fi
  info "Installing argocd CLI..."

  if [[ "$OS" == "darwin" && "$ARGOCD_VERSION" == "stable" ]]; then
    brew install argocd
  else
    local url
    if [[ "$ARGOCD_VERSION" == "stable" ]]; then
      url="https://github.com/argoproj/argo-cd/releases/latest/download/argocd-${OS}-${ARCH}"
    else
      url="https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-${OS}-${ARCH}"
    fi
    curl -fsSLo /tmp/argocd "$url"
    if [[ "$OS" == "darwin" ]]; then
      sudo install -m 0555 /tmp/argocd /usr/local/bin/argocd
    else
      $SUDO install -m 0555 /tmp/argocd /usr/local/bin/argocd
    fi
    rm -f /tmp/argocd
  fi
  success "argocd CLI installed: $(argocd version --client --short 2>/dev/null || echo ok)"
}

# ---------- 6. show access info ----------
print_access_info() {
  info "Fetching initial admin password..."
  local password=""
  for _ in {1..30}; do
    password="$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
      -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode 2>/dev/null || true)"
    [[ -n "$password" ]] && break
    sleep 2
  done

  echo
  echo -e "${GREEN}==================== Argo CD installed ====================${NC}"
  echo "  Namespace : $ARGOCD_NAMESPACE"
  echo "  Username  : admin"
  echo "  Password  : ${password:-<not found yet, run the command below>}"
  echo
  echo "  1) Open the UI (keep this running in a terminal):"
  echo "       kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
  echo "     Then browse to: https://localhost:8080  (accept the self-signed cert)"
  echo
  echo "  2) Login with the CLI (while port-forward is running):"
  echo "       argocd login localhost:8080 --username admin --password '<password>' --insecure"
  echo
  echo "  Get password again:"
  echo "       kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode; echo"
  echo -e "${GREEN}===========================================================${NC}"
}

# ---------- uninstall ----------
uninstall() {
  detect_system
  info "Removing Argo CD from namespace '${ARGOCD_NAMESPACE}'..."
  kubectl delete -n "$ARGOCD_NAMESPACE" \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" \
    --ignore-not-found || true
  kubectl delete namespace "$ARGOCD_NAMESPACE" --ignore-not-found || true

  if command_exists kind && kind get clusters 2>/dev/null | grep -qx "$KIND_CLUSTER_NAME"; then
    read -r -p "Delete kind cluster '${KIND_CLUSTER_NAME}' too? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] && kind delete cluster --name "$KIND_CLUSTER_NAME"
  fi
  success "Uninstall complete"
}

# ---------- main ----------
main() {
  case "${1:-install}" in
    install)
      detect_system
      check_homebrew
      [[ "$OS" == "linux" ]] && install_base_tools_linux
      install_kubectl
      ensure_cluster
      install_argocd
      install_argocd_cli
      print_access_info
      ;;
    uninstall)
      uninstall
      ;;
    *)
      echo "Usage: $0 [install|uninstall]"
      exit 1
      ;;
  esac
}

main "$@"