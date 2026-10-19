#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./build_docker.sh [docker build options]

Build the ROS 2 Jazzy image for the Go2-W description package.
Set GO2W_DOCKER_IMAGE to override the default image tag.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
image_tag="${GO2W_DOCKER_IMAGE:-go2w_description:jazzy}"

exec docker build \
    --tag "$image_tag" \
    --file "$repo_dir/Dockerfile" \
    "$@" \
    "$repo_dir"
