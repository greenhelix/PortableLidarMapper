"""
전체 파이프라인 통합 실행 launch 파일.

사용 예:
  # 하드웨어 없이 mock 데이터로 SLAM 파이프라인 검증
  ros2 launch lidar_mapper_bringup bringup.launch.py use_mock:=true

  # 실제 RPLIDAR C1 연결 시 (sllidar_ros2 설치되어 있어야 함, 장치 경로가 다르면 지정)
  ros2 launch lidar_mapper_bringup bringup.launch.py use_mock:=false lidar_serial_port:=/dev/ttyUSB1
"""
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition, UnlessCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    use_mock = LaunchConfiguration('use_mock')
    use_rosbridge = LaunchConfiguration('use_rosbridge')
    lidar_serial_port = LaunchConfiguration('lidar_serial_port')

    return LaunchDescription([
        DeclareLaunchArgument(
            'use_mock', default_value='true',
            description='true면 mock 라이다, false면 실제 RPLIDAR C1 사용'
        ),
        DeclareLaunchArgument(
            'use_rosbridge', default_value='true',
            description='Foxglove/스마트폰 연동용 rosbridge websocket 실행 여부'
        ),
        DeclareLaunchArgument(
            'lidar_serial_port', default_value='/dev/ttyUSB0',
            description='실제 RPLIDAR C1 USB 시리얼 장치 경로 (use_mock:=false일 때만 사용)'
        ),

        # --- 라이다 소스 (mock) ---
        Node(
            package='lidar_mapper_mock',
            executable='mock_scan_publisher',
            name='mock_scan_publisher',
            output='screen',
            condition=IfCondition(use_mock),
        ),

        # --- 센서 마운트 고정 TF (base_footprint->laser) ---
        # 라이다가 몸체(base_footprint) 어디에 붙어있는지는 안 변하므로 이것만 고정.
        Node(
            package='tf2_ros', executable='static_transform_publisher',
            name='tf_base_footprint_to_laser', output='screen',
            arguments=['--frame-id', 'base_footprint', '--child-frame-id', 'laser'],
        ),

        # --- 레이저 오도메트리 (odom->base_footprint) ---
        # 바퀴 인코더가 없는 휴대용 기기라서, 연속된 스캔끼리 비교해서 이동을
        # 추정하는 rf2o로 odom->base_footprint TF를 동적으로 발행한다.
        # map->odom TF는 이 노드가 아니라 slam_toolbox가 알아서 발행한다.
        Node(
            package='rf2o_laser_odometry', executable='rf2o_laser_odometry_node',
            name='rf2o_laser_odometry', output='screen',
            parameters=[{
                'laser_scan_topic': '/scan',
                'odom_topic': '/odom_rf2o',
                'publish_tf': True,
                'base_frame_id': 'base_footprint',
                'odom_frame_id': 'odom',
                'init_pose_from_topic': '',
                # RPLIDAR C1 실제 스캔 속도(10Hz)에 맞춤. 기존 20Hz는 스캔이 없을 때도
                # 계속 "Waiting for laser_scans" 루프를 도는 것 뿐이라 실효 없이 CPU만 씀.
                'freq': 10.0,
            }],
        ),

        # --- 라이다 소스 (실제 하드웨어, sllidar_ros2 패키지 필요) ---
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                PathJoinSubstitution([
                    FindPackageShare('sllidar_ros2'), 'launch', 'sllidar_c1_launch.py'
                ])
            ),
            launch_arguments={'serial_port': lidar_serial_port}.items(),
            condition=UnlessCondition(use_mock),
        ),

        # --- SLAM ---
        # config/mapper_params_online_async.yaml: 휴대(도보) 속도에 맞게 튜닝한 파라미터.
        # 특히 map_update_interval을 기본 5.0초에서 0.5초로 낮춰서 Foxglove에서
        # 지도가 훨씬 빠르게 갱신되도록 함.
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                PathJoinSubstitution([
                    FindPackageShare('slam_toolbox'), 'launch', 'online_async_launch.py'
                ])
            ),
            launch_arguments={
                # docker/run_dev.sh가 프로젝트 config/ 를 /lidar_ws/config 로 마운트해둠
                # (session_logger_node의 db_path와 동일한 컨테이너 경로 관례).
                'slam_params_file': '/lidar_ws/config/mapper_params_online_async.yaml',
                'use_sim_time': 'false',
            }.items(),
        ),

        # --- rosbridge (Foxglove/스마트폰 연동) ---
        Node(
            package='rosbridge_server',
            executable='rosbridge_websocket',
            name='rosbridge_websocket',
            output='screen',
            condition=IfCondition(use_rosbridge),
        ),

        # rosapi: rosbridge 클라이언트(Foxglove 등)가 토픽/타입 목록을 조회할 때 필요.
        # 이게 없으면 연결은 되지만 "topics_and_raw_types" 같은 서비스 호출이 실패함.
        Node(
            package='rosapi',
            executable='rosapi_node',
            name='rosapi',
            output='screen',
            condition=IfCondition(use_rosbridge),
        ),
    ])
