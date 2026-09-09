#!/usr/bin/env python3
"""수집 세션 이벤트를 모았다가 세션 종료 시 SQLite(`sessions` 테이블)에 기록하는 노드.

토픽 인터페이스:
- /session_event (std_msgs/String) 구독: 세션 도중 발생한 이벤트 로그 라인 누적
  (예: "거실 스캔 완료")
- /session_end (std_msgs/String) 구독: 메시지가 들어오면 지금까지 모은 이벤트를
  ai/ provider로 요약해서 DB에 저장하고 버퍼를 비움. data는 맵 pgm 경로(선택, 없으면 빈 문자열).

ai/ provider는 저장소 루트의 `ai/` 패키지가 마운트돼 있으면(Docker 개발 환경)
그걸 쓰고, 없으면 요약 없이 이벤트를 이어붙이기만 하는 로컬 폴백을 쓴다.
"""
import datetime
import os

import rclpy
from rclpy.node import Node
from std_msgs.msg import String

try:
    import sys
    sys.path.insert(0, '/lidar_ws')  # docker/run_dev.sh 가 ai/ 를 이 경로에 마운트함
    from ai.providers import get_provider
except ImportError:
    def get_provider(name, **kwargs):
        class _LocalNullProvider:
            def summarize_session(self, events):
                return " / ".join(events) if events else "(기록된 이벤트 없음)"
        return _LocalNullProvider()

from . import db


class SessionLoggerNode(Node):
    def __init__(self):
        super().__init__('session_logger_node')

        self.declare_parameter('db_path', '/lidar_ws/data/rooms.db')
        self.declare_parameter('ai_provider', 'null')

        db_path = self.get_parameter('db_path').value
        provider_name = self.get_parameter('ai_provider').value

        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self.conn = db.connect(db_path)
        self.provider = get_provider(provider_name)

        self.events = []
        self.session_started_at = None

        self.create_subscription(String, '/session_event', self.on_event, 10)
        self.create_subscription(String, '/session_end', self.on_session_end, 10)

        self.get_logger().info(
            f'session_logger_node started (db_path={db_path}, ai_provider={provider_name})'
        )

    def on_event(self, msg: String):
        if self.session_started_at is None:
            self.session_started_at = datetime.datetime.now().isoformat()
        self.events.append(msg.data)
        self.get_logger().info(f'이벤트 기록: {msg.data}')

    def on_session_end(self, msg: String):
        ended_at = datetime.datetime.now().isoformat()
        started_at = self.session_started_at or ended_at
        summary = self.provider.summarize_session(self.events)

        map_pgm_path = msg.data if msg.data else None
        session_id = db.insert_session(
            self.conn, started_at, ended_at, summary, map_pgm_path=map_pgm_path,
        )
        self.get_logger().info(f'세션 저장 완료 (id={session_id}): {summary}')

        self.events = []
        self.session_started_at = None


def main(args=None):
    rclpy.init(args=args)
    node = SessionLoggerNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.conn.close()
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
