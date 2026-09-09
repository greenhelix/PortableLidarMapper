"""AI 에이전트 provider 공통 인터페이스.

Anthropic/OpenAI/중국계(Qwen, DeepSeek 등) 어떤 모델을 붙이더라도
이 인터페이스만 구현하면 앱/노드 쪽 코드는 수정할 필요가 없다.
providers/ 아래에 새 클래스를 추가하고 config.yaml의 provider 이름만
바꾸면 교체된다.
"""
from abc import ABC, abstractmethod


class AIProvider(ABC):
    @abstractmethod
    def summarize_session(self, session_events: list[str]) -> str:
        """수집 세션 중 기록된 이벤트(로그 문자열 목록)를 사람이 읽을 요약으로 변환."""
        raise NotImplementedError
