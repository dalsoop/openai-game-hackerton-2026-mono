# 0004. 슬롯마다 Redis logical DB를 따로 쓰고 키 접두사는 쓰지 않는다

- 날짜: 2026-08-26 (커밋 6054431, 8bb4eb4, aafbcb5)
- 상태: 채택

## 배경

여러 슬롯 허브가 클러스터 Redis 하나를 공유했다. 같은 DB를 쓰자 방 수 집계가 슬롯끼리 섞여 운영 슬롯의 방 만들기가 523으로 실패했다. ioredis `keyPrefix`로 나누려 하자 Colyseus의 pub/sub 채널과 예약 키가 갈라져 방 입장이 4002로 닫혔다.

## 결정

Redis는 클러스터에 하나만 두고, 슬롯마다 다른 logical DB 번호를 준다(`values-games.yaml`의 `redis.slots`). 허브에는 공식 형태의 `REDIS_URL`을 그대로 넘긴다. 로컬 개발은 127.0.0.1:6379의 DB 0을 쓴다.

## 검토한 대안

- 모든 슬롯이 DB 하나 공유: 방 수 집계 혼선으로 방 만들기 실패.
- ioredis `keyPrefix`: Colyseus 입장 4002 실패.
- 슬롯별 Redis 사이드카(커밋 bc4a187에서 시도): 이후 공유 Redis + DB 분리로 바꿨다.

## 결과

- 새 슬롯을 추가하면 `plant-apps.py`가 DB 번호를 배정해야 하고, Redis logical DB 개수(기본 16)가 슬롯 수의 상한이 된다.
- `keyPrefix`를 도입할 수 없다.
