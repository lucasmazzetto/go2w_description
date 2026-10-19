#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./run_docker.sh [--headless] [--software-rendering] [--] [command [args...]]

Run the Go2-W description package in Docker.
Without a command, the colored model opens in RViz with joint sliders.
Use --headless to publish the model without opening GUI windows.
Use --software-rendering to force CPU rendering.
When available, NVIDIA Container Toolkit is configured automatically for GPU rendering.

Examples:
  ./run_docker.sh
  ./run_docker.sh --headless
  ./run_docker.sh --software-rendering
  ./run_docker.sh bash
  ./run_docker.sh --headless ros2 launch go2w_description description.launch.py

Set GO2W_DOCKER_IMAGE to override the default image tag.
EOF
}

headless=false
software_rendering=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --headless)
            headless=true
            shift
            ;;
        --software-rendering)
            software_rendering=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

image_tag="${GO2W_DOCKER_IMAGE:-go2w_description:jazzy}"
if ! docker image inspect "$image_tag" >/dev/null 2>&1; then
    printf 'Cannot access image %s. Run ./build_docker.sh first.\n' "$image_tag" >&2
    exit 1
fi

docker_args=(
    --rm
    --init
    --interactive
    --network host
    --ipc host
    --user "$(id -u):$(id -g)"
    --env HOME=/tmp
    --env "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}"
    --env "ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY:-0}"
)

if [[ -t 0 && -t 1 ]]; then
    docker_args+=(--tty)
fi

if [[ "$headless" == true ]]; then
    if [[ $# -eq 0 ]]; then
        set -- ros2 launch go2w_description display.launch.py gui:=false rviz:=false
    fi
else
    if [[ -z "${DISPLAY:-}" ]]; then
        printf 'DISPLAY is not set. Use --headless for a windowless run.\n' >&2
        exit 1
    fi
    if [[ ! -d /tmp/.X11-unix ]]; then
        printf 'X11 socket directory /tmp/.X11-unix is missing.\n' >&2
        exit 1
    fi

    xauthority_file="${XAUTHORITY:-$HOME/.Xauthority}"
    if [[ ! -f "$xauthority_file" || ! -r "$xauthority_file" ]]; then
        printf 'Cannot read Xauthority file: %s\n' "$xauthority_file" >&2
        exit 1
    fi
    if [[ "$xauthority_file" != /* ]]; then
        xauthority_file="$PWD/$xauthority_file"
    fi

    docker_args+=(
        --env DISPLAY
        --env XAUTHORITY=/tmp/.Xauthority
        --mount type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,readonly
        --mount "type=bind,src=$xauthority_file,dst=/tmp/.Xauthority,readonly"
    )
fi

render_device=false
nvidia_rendering=false
nvidia_available=false
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    nvidia_available=true
fi

if [[ "$software_rendering" == false \
    && "$nvidia_available" == true \
    && "$(docker info --format '{{json .Runtimes}}' 2>/dev/null || true)" == *'"nvidia"'* ]]; then
    docker_args+=(
        --gpus all
        --env NVIDIA_VISIBLE_DEVICES=all
        --env NVIDIA_DRIVER_CAPABILITIES=graphics,display,utility
        --env __GLX_VENDOR_LIBRARY_NAME=nvidia
    )
    nvidia_rendering=true
    render_device=true
fi

if [[ "$software_rendering" == false \
    && "$nvidia_available" == false \
    && "$nvidia_rendering" == false ]]; then
    for render_node in /dev/dri/renderD*; do
        [[ -c "$render_node" && -r "$render_node" && -w "$render_node" ]] || continue
        docker_args+=(
            --device "$render_node"
            --group-add "$(stat -c '%g' "$render_node")"
        )
        render_device=true
    done
fi

if [[ "$render_device" == false ]]; then
    docker_args+=(--env LIBGL_ALWAYS_SOFTWARE=1)
    if [[ "$nvidia_available" == true && "$software_rendering" == false ]]; then
        printf 'NVIDIA GPU detected, but the NVIDIA Container Toolkit is unavailable; using software rendering.\n' >&2
    fi
    printf 'Using software rendering.\n' >&2
fi

exec docker run "${docker_args[@]}" "$image_tag" "$@"
