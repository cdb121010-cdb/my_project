- APB(Advanced Peripheral Bus) 기반의 **RGB PWM 컨트롤러(APB Slave IP)**를 Verilog로 직접 설계하고, MicroBlaze 프로세서 시스템에 통합한 프로젝트입니다.
- PC(UART) 터미널에서 **RGB 값(0~255)**을 입력받아 **RGB LED 2개(총 6채널)**를 독립적으로 제어합니다.
- Vivado(하드웨어) + Vitis(소프트웨어)로 전체 임베디드 시스템을 구성하고 동작을 검증했습니다.

---

## 원본 PDF

디지털 시스템 설계 기말보고서 (2025-06-20)

디지털 시스템 설계 기말보고서 (2025-06-20)

---

## 프로젝트 개요

- **목표**: APB 기반 PWM 컨트롤러를 직접 설계하고 MicroBlaze 시스템에 통합하여, UART 입력으로 RGB LED 2개를 제어
- **제어 범위**: R/G/B 각 채널 **0~255(256단계)** 밝기
- **입출력**: PC 터미널(UART, 9600bps) ↔ MicroBlaze ↔ AXI-to-APB Bridge ↔ Custom RGB Controller(APB Slave)

## 개발 환경

- 보드: **Nexys A7-50T (xc7s50csg324-1)**
- 하드웨어: **Vivado 2023.1**, Verilog HDL
- 소프트웨어: **Vitis 2023.1**, C
- 터미널: **Tera Term (9600 bps)**

---

## 시스템 구성 요약

1. **MicroBlaze Processor**
    - 소프트웨어 실행 및 주변장치 제어
2. **AXI Interconnect**
    - 메인 버스
3. **AXI to APB Bridge**
    - AXI ↔ APB 프로토콜 변환 (커스텀 APB Slave IP 연결)
4. **AXI Uartlite**
    - PC와 UART 통신
5. **Custom RGB Controller (APB Slave)**
    - RGB LED 2개 제어용 **6채널 PWM** 포함

---

## 레지스터 맵(핵심만)

- 총 6개 채널(LED0: R/G/B, LED1: R/G/B)에 대해 **각 8-bit(0~255)** 밝기 레지스터를 사용
- 소프트웨어는 APB를 통해 주소 기반으로 읽기/쓰기

### 명령어 체계(사용자 관점)

- **컬러 설정**: `(LED 번호) (R) (G) (B)`
    - 예: `0 120 60 10`
- **정보 확인**: `(LED 번호)`
    - 예: `1` → 현재 설정된 R/G/B를 출력

---

## PWM 생성 로직(요약)

- 100MHz 기준으로 **1ms 주기**(=100,000클럭)를 만드는 카운터를 구성
- 각 채널의 밝기값(0~255)을 스케일링하여, 주기 카운터와 비교해 High/Low를 생성
    - 핵심 비교: `pwm_period_counter < w_scaled_duty`

---

## 시연영상

- 동영상(Shorts): https://youtube.com/shorts/Qn91vLUIbvw

---

## 개선점 정리(보고서 기반)

### 

1. PWM 스케일링 정확도
- 현재는 `100000/256 ≈ 390.625`를 근사해 **391을 곱하는 방식**을 사용
- 영향: 완전한 선형/정확 듀티 보장이 어려움(예: duty=255가 100%가 아니라 약 99.7%)
- 개선 아이디어: **DDA(누산기) 방식** 또는 더 높은 비트 정밀도로 `duty * PWM_PERIOD / 256` 계산

### 

1. 레지스터 접근 로직의 확장성/안정성
- 주소별 case 하드코딩 → 레지스터가 늘면 수정 비용 증가
- APB 쓰기 완료를 1사이클로 가정 → 복잡한 내부 로직에서 안정성 저하 가능
- 개선 아이디어: 파라미터화(parameterize), FSM 기반 접근, 필요 시 PREADY 핸드셰이크 확장

---

## 빠른 체크리스트(공유용)

- [ ]  PDF 원본 확인
- [ ]  프로젝트 목표/환경/구성 1분 요약 읽기
- [ ]  명령어 예시로 동작 방식 이해
- [ ]  개선점 토글 열어보고 향후 방향 확인
