FROM ros:jazzy-ros-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-colcon-common-extensions \
        python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/go2w_ws

COPY . src/go2w_description/

RUN rosdep update --rosdistro "${ROS_DISTRO}" \
    && apt-get update \
    && rosdep install --from-paths src --ignore-src --rosdistro "${ROS_DISTRO}" -r -y \
    && source "/opt/ros/${ROS_DISTRO}/setup.bash" \
    && colcon build --merge-install --packages-select go2w_description \
        --event-handlers console_direct+ \
    && chmod a+rwx /opt/go2w_ws \
    && chmod -R a+rwX build install \
    && rm -rf log /var/lib/apt/lists/*

COPY --chmod=755 docker/entrypoint.sh /go2w_entrypoint.sh

ENV QT_X11_NO_MITSHM=1

ENTRYPOINT ["/go2w_entrypoint.sh"]
CMD ["ros2", "launch", "go2w_description", "display.launch.py"]
