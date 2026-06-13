"""
launch/display.launch.py
Launches robot_state_publisher, joint_state_publisher_gui, and RViz2
to visualise the robot_arm URDF/Xacro model.

Usage:
    ros2 launch robot_arm_description display.launch.py
"""

import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
import xacro


def generate_launch_description():
    pkg_share = get_package_share_directory('robot_arm_description')

    # ── Process Xacro → URDF string ──────────────────────────────────────
    xacro_file = os.path.join(pkg_share, 'urdf', 'robot_arm.urdf.xacro')
    robot_description_content = xacro.process_file(xacro_file).toxml()
    robot_description = {'robot_description': robot_description_content}

    # ── RViz config ───────────────────────────────────────────────────────
    rviz_config = os.path.join(pkg_share, 'config', 'robot_arm.rviz')

    # ── Nodes ─────────────────────────────────────────────────────────────
    robot_state_publisher_node = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',
        parameters=[robot_description],
    )

    joint_state_publisher_gui_node = Node(
        package='joint_state_publisher_gui',
        executable='joint_state_publisher_gui',
        output='screen',
    )

    rviz_node = Node(
        package='rviz2',
        executable='rviz2',
        output='screen',
        arguments=['-d', rviz_config] if os.path.exists(rviz_config) else [],
    )

    return LaunchDescription([
        robot_state_publisher_node,
        joint_state_publisher_gui_node,
        rviz_node,
    ])
