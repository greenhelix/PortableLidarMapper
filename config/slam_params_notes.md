# slam_toolbox 파라미터 튜닝 메모 (예정)

기본 설정 파일은 `/opt/ros/humble/share/slam_toolbox/config/mapper_params_online_async.yaml` 사용.
휴대용(사람이 들고 걷는) 환경에서 조정이 필요할 것으로 예상되는 항목:

| 파라미터 | 기본값 | 조정 방향(가설) | 이유 |
|---|---|---|---|
| `minimum_travel_distance` | 0.5 | 낮출 가능성 | 도보 이동 속도가 로봇보다 빠름 |
| `minimum_travel_heading` | 0.5 | 낮출 가능성 | 사람 움직임은 회전이 더 급격함 |
| `scan_buffer_size` | 10 | 실측 후 조정 | 진동 노이즈 영향 확인 필요 |

> 실제 하드웨어로 실내 걷기 테스트를 해봐야 의미 있는 값을 확정할 수 있음.
> 지금은 mock 데이터 기준으로 기본값 그대로 사용하고, 실측 후 이 파일 업데이트.
