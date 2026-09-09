#!/usr/bin/env python3
"""
하드웨어(RPLIDAR C1) 도착 전, 실제 라이다와 동일한 /scan(LaserScan) 토픽을
발행해서 slam_toolbox / rosbridge / Foxglove 파이프라인을 미리 검증하기 위한 mock 노드.

실제 센서로 교체 시: 이 노드를 끄고 sllidar_ros2의 sllidar_c1_launch.py 를
그대로 실행하면 된다. 토픽 이름(/scan)과 메시지 타입(LaserScan)이 동일하므로
slam_toolbox 등 상위 노드는 코드 수정이 필요 없다.
"""
import math
import numpy as np
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import LaserScan


class MockScanPublisher(Node):
    def __init__(self):
        super().__init__('mock_scan_publisher')

        self.declare_parameter('frame_id', 'laser')
        self.declare_parameter('publish_rate_hz', 10.0)
        self.declare_parameter('num_points', 360)
        self.declare_parameter('room_radius_m', 3.0)

        self.frame_id = self.get_parameter('frame_id').value
        rate = self.get_parameter('publish_rate_hz').value
        self.num_points = self.get_parameter('num_points').value
        self.room_radius = self.get_parameter('room_radius_m').value

        self.publisher_ = self.create_publisher(LaserScan, '/scan', 10)
        self.timer = self.create_timer(1.0 / rate, self.timer_callback)
        self.t = 0.0

        self.get_logger().info(
            f'Mock scan publisher started (frame_id={self.frame_id}, '
            f'rate={rate}Hz, points={self.num_points})'
        )

    def timer_callback(self):
        msg = LaserScan()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = self.frame_id

        msg.angle_min = 0.0
        msg.angle_max = 2.0 * math.pi
        msg.angle_increment = 2.0 * math.pi / self.num_points
        msg.time_increment = 0.0
        msg.scan_time = 1.0 / 10.0
        msg.range_min = 0.15
        msg.range_max = 12.0

        # 정사각형 방 형태를 흉내내는 가짜 거리값 + 약간의 노이즈
        # (파이프라인 검증용이며 실제 지도 품질과는 무관)
        angles = np.linspace(msg.angle_min, msg.angle_max, self.num_points, endpoint=False)
        base = self.room_radius / np.maximum(
            np.abs(np.cos(angles)), np.abs(np.sin(angles))
        )
        noise = np.random.normal(0.0, 0.02, size=self.num_points)
        ranges = np.clip(base + noise + 0.05 * math.sin(self.t), msg.range_min, msg.range_max)

        msg.ranges = ranges.astype(float).tolist()
        msg.intensities = []

        self.publisher_.publish(msg)
        self.t += 1.0 / 10.0


def main(args=None):
    rclpy.init(args=args)
    node = MockScanPublisher()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
