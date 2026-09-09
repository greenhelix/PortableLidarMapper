"""provider 이름 -> 클래스 레지스트리.

새 provider를 추가하면 여기 한 줄만 등록하면 config.yaml에서 바로 선택 가능.
"""
from .null_provider import NullProvider

REGISTRY = {
    "null": NullProvider,
}


def get_provider(name: str, **kwargs):
    if name not in REGISTRY:
        raise ValueError(
            f"알 수 없는 AI provider: '{name}'. 등록된 provider: {list(REGISTRY)}"
        )
    return REGISTRY[name](**kwargs)
