# Shared helpers for sim.sh / studio.sh (sourced, not executed).
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${ASE_IMAGE:-ase-riscv-gem5:local}"

# Git Bash on Windows: stop it from rewriting container paths, and use a Windows-style mount path.
export MSYS_NO_PATHCONV=1
MOUNT="$(cd "$REPO" && (pwd -W 2>/dev/null || pwd))"

# On Linux, run as the current user so files in results/ and programs/ are not owned by root.
USER_ARGS=()
[[ "$(uname -s)" == "Linux" ]] && USER_ARGS=(--user "$(id -u):$(id -g)")

die() { echo "error: $*" >&2; exit 1; }

ensure_image() {
    command -v docker >/dev/null 2>&1 || die "Docker is not installed. See INSTALL_DOCKER.md."
    docker info >/dev/null 2>&1 || die "Docker is installed but not running. Start Docker Desktop and retry."
    [[ -f "$REPO/setup_default" ]] || die "setup_default not found: run this from the ase_riscv_gem5_sim repository."
    docker image inspect "$IMAGE" >/dev/null 2>&1 && return 0
    # A registry name (contains '/') is pulled; otherwise (or if the pull fails) build locally.
    if [[ "$IMAGE" == */* ]]; then
        echo "Pulling $IMAGE ..."
        docker pull "$IMAGE" && return 0
        echo "Pull failed; building the image locally instead."
    fi
    echo "Building the image $IMAGE (one time, can take 1-3 hours) ..."
    docker build -t "$IMAGE" -f "$REPO/docker/Dockerfile" "$REPO" || die "image build failed"
}
