# SPDX-License-Identifier: BSD-3-Clause
"""Publish the Go2-W description and TF using externally supplied joint states."""

from pathlib import Path

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
    package_share = Path(get_package_share_directory('go2w_description'))
    robot_description = (
        package_share / 'urdf' / 'go2w_description.urdf'
    ).read_text(encoding='utf-8')

    return LaunchDescription([
        DeclareLaunchArgument(
            'use_sim_time', default_value='false',
            description='Use the ROS simulation clock.',
        ),
        DeclareLaunchArgument(
            'frame_prefix', default_value='',
            description='Prefix applied to published TF frame names.',
        ),
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            output='screen',
            parameters=[{
                'robot_description': ParameterValue(robot_description, value_type=str),
                'use_sim_time': ParameterValue(
                    LaunchConfiguration('use_sim_time'), value_type=bool,
                ),
                'frame_prefix': ParameterValue(
                    LaunchConfiguration('frame_prefix'), value_type=str,
                ),
            }],
        ),
    ])
