# Unitree Go2-W Description

This ROS 2 package provides the Unitree Go2-W robot description for RViz, robot drivers, and simulators. It includes the colored URDF, meshes, inertial data, collision geometry, TF launch files, and a default RViz configuration. The root link is `base`, and the model includes `imu` and `radar` sensor frames.

The package contains the robot model and TF publication only. Gazebo plugins, wheel controllers, sensor simulation, and locomotion control belong in the application or simulator that uses this description.

<img width="998" height="526" alt="urdf" src="https://github.com/user-attachments/assets/3c96ae2c-98e5-4eae-9c3f-db2e0ef0f413" />

## 💻 Installation

Clone this repository into the `src` directory of a ROS 2 workspace. Create a workspace first if you do not already have one:

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
git clone https://github.com/lucasmazzetto/go2w_description.git
```

### 🐧 Linux Setup

This package is developed for Ubuntu 24.04 and ROS 2 Jazzy Jalisco. Other ROS 2 distributions may require small changes to dependency names or launch files.

#### 📚 Requirements

- Ubuntu 24.04 or another Linux distribution with ROS 2 installed
- ROS 2 Jazzy Jalisco
- `colcon`
- `rosdep`

The ROS dependencies include `robot_state_publisher`, `joint_state_publisher`, `joint_state_publisher_gui`, and `rviz2`.

#### 🛠️ Build

From the workspace root, source ROS 2, install dependencies, and build the package:

```bash
cd ~/ros2_ws
source /opt/ros/jazzy/setup.bash
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --packages-select go2w_description
source install/setup.bash
```

After a successful build, the package is ready to use. Replace the Jazzy setup path if you are using another ROS 2 distribution.

### 🐳 Docker Setup

Docker provides a reproducible ROS 2 Jazzy environment with the package and its RViz dependencies installed. Install Docker Engine or Docker Desktop first. GUI mode requires an X11 display; use headless mode on machines without a desktop session. On NVIDIA systems, install the NVIDIA Container Toolkit for hardware-accelerated RViz; software rendering remains available as a fallback.

#### 🛠️ Build

Run the build script from this repository's directory. The first build may take several minutes while ROS dependencies are downloaded:

```bash
cd ~/ros2_ws/src/go2w_description
./build_docker.sh
```

#### 🏃 Run

Start the colored model in RViz:

```bash
./run_docker.sh
```

The script forwards the host X11 display and automatically configures NVIDIA Container Toolkit when an NVIDIA GPU and runtime are available. Otherwise, it uses an accessible Mesa render device when possible. If no compatible render device is available, software rendering is used automatically. To force software rendering, run:

```bash
./run_docker.sh --software-rendering
```

For a windowless run, start the description and joint-state publishers without RViz:

```bash
./run_docker.sh --headless
```

Verify that the package is installed in the image:

```bash
./run_docker.sh --headless ros2 pkg prefix go2w_description
```

Run the tests in one container so their result files are available to `colcon test-result`:

```bash
./run_docker.sh --headless bash -lc \
  'colcon test --merge-install --packages-select go2w_description && colcon test-result --verbose'
```

Open a shell in the configured container when needed:

```bash
./run_docker.sh --headless bash
```

The scripts use `go2w_description:jazzy` by default. Set `GO2W_DOCKER_IMAGE` to use another image tag:

```bash
GO2W_DOCKER_IMAGE=my-go2w-description:latest ./build_docker.sh
GO2W_DOCKER_IMAGE=my-go2w-description:latest ./run_docker.sh
```

## 🚀 Usage

### 🚗 Visualize the robot

After building the package, launch RViz with the joint slider window:

```bash
source ~/ros2_ws/install/setup.bash
ros2 launch go2w_description display.launch.py
```

The display launch publishes the robot description, starts a joint-state publisher, and opens RViz with the checked-in configuration.

To display the default pose without joint sliders:

```bash
ros2 launch go2w_description display.launch.py gui:=false
```

To publish the robot without opening RViz or another GUI:

```bash
ros2 launch go2w_description display.launch.py gui:=false rviz:=false
```

To use the ROS simulation clock:

```bash
ros2 launch go2w_description display.launch.py use_sim_time:=true
```

### 🤖 Use with a driver or simulator

Start only `robot_state_publisher` when another node or simulator publishes `sensor_msgs/msg/JointState` messages on `joint_states`:

```bash
ros2 launch go2w_description description.launch.py
```

The description launch accepts these arguments:

| Argument | Default | Description |
| --- | --- | --- |
| `use_sim_time` | `false` | Use the ROS simulation clock. |
| `frame_prefix` | empty | Prefix published TF frame names. |

For example:

```bash
ros2 launch go2w_description description.launch.py frame_prefix:=go2w/
```

The 16 movable joints are:

```text
FL_hip_joint       FL_thigh_joint       FL_calf_joint       FL_foot_joint
FR_hip_joint       FR_thigh_joint       FR_calf_joint       FR_foot_joint
RL_hip_joint       RL_thigh_joint       RL_calf_joint       RL_foot_joint
RR_hip_joint       RR_thigh_joint       RR_calf_joint       RR_foot_joint
```

The `base` root link includes the manufacturer's inertia. KDL reports a warning because it does not support inertia on a root link; TF publication continues to work normally.

## 🎨 Appearance

The checked-in model has a gray body and legs, silver-gray wheel hubs, near-black tires, black trim, and off-white logos. The colors are baked into the URDF materials and Collada meshes, so no generation step or appearance configuration is required during build or launch.

## 🧪 Testing

The appearance tests validate the URDF structure, physical properties, visual origins and scales, mesh resource paths, material bindings, and separate wheel tire and hub materials.

From a built workspace:

```bash
colcon test --packages-select go2w_description
colcon test-result --verbose
```

## 📦 Package Layout

| Path | Purpose |
| --- | --- |
| `urdf/go2w_description.urdf` | Colored Go2-W URDF |
| `dae/` | Robot mesh files |
| `config/joint_names_go2w_description.yaml` | Joint-name list |
| `launch/description.launch.py` | TF publication from external joint states |
| `launch/display.launch.py` | Standalone RViz and joint-state preview |
| `rviz/go2w.rviz` | Default RViz configuration |
| `test/test_appearance.py` | URDF and baked-material tests |
| `Dockerfile` | ROS 2 Jazzy Docker image definition |
| `build_docker.sh` | Docker image build helper |
| `run_docker.sh` | Docker run and visualization helper |

## Credits and License

The Go2-W model and mesh assets are credited to Unitree Robotics. The original copyright notice and BSD-3-Clause license are preserved in [`LICENSE`](LICENSE). The ROS 2 launch integration and tests in this package are also released under the BSD-3-Clause license.
