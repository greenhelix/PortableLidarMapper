"""기본 provider. 외부 API를 호출하지 않고 이벤트를 그대로 이어붙인 텍스트를 반환한다.
실제 모델(Anthropic/OpenAI/Qwen 등)을 아직 연결하지 않은 상태에서도
파이프라인이 깨지지 않도록 하는 fallback 역할."""
from ..provider import AIProvider


class NullProvider(AIProvider):
    def summarize_session(self, session_events: list[str]) -> str:
        if not session_events:
            return "(기록된 이벤트 없음)"
        return " / ".join(session_events)
