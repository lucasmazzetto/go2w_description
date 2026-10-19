# SPDX-License-Identifier: BSD-3-Clause
"""Display Go2-W in RViz with synthetic joint states and optional joint sliders."""

from pathlib import Path

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition, UnlessCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
    package_share = Path(get_package_share_directory('go2w_description'))
    use_sim_time = LaunchConfiguration('use_sim_time')
    joint_state_parameters = [{
        'use_sim_time': ParameterValue(use_sim_time, value_type=bool),
    }]

    return LaunchDescription([
        DeclareLaunchArgument(
            'gui', default_value='true',
            description='Use joint sliders instead of the headless joint state publisher.',
        ),
        DeclareLaunchArgument(
            'rviz', default_value='true', description='Start RViz.',
        ),
        DeclareLaunchArgument(
            'use_sim_time', default_value='false',
            description='Use the ROS simulation clock.',
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                str(package_share / 'launch' / 'description.launch.py'),
            ),
            launch_arguments={'use_sim_time': use_sim_time}.items(),
        ),
        Node(
            package='joint_state_publisher_gui',
            executable='joint_state_publisher_gui',
            name='joint_state_publisher_gui',
            parameters=joint_state_parameters,
            condition=IfCondition(LaunchConfiguration('gui')),
        ),
        Node(
            package='joint_state_publisher',
            executable='joint_state_publisher',
            name='joint_state_publisher',
            parameters=joint_state_parameters,
            condition=UnlessCondition(LaunchConfiguration('gui')),
        ),
        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', str(package_share / 'rviz' / 'go2w.rviz')],
            parameters=[{
                'use_sim_time': ParameterValue(use_sim_time, value_type=bool),
            }],
            condition=IfCondition(LaunchConfiguration('rviz')),
        ),
    ])
