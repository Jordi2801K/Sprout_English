# Qwen 로컬 STT 실행

이 프로젝트는 음성 인식에 사전학습된 `Qwen/Qwen3-ASR-1.7B`만 사용합니다. 모델을 학습하거나 파인튜닝하지 않았습니다. 대화 생성·TTS·번역·평가에는 OpenAI API가 필요합니다.

## 준비

먼저 [루트 README](../README.md)의 서버 설치와 `.env` 설정을 완료해 주세요. `server/`에서 추가 패키지를 설치합니다.

```bash
uv pip install --python .venv/bin/python -r requirements-local-stt.txt
```

모델 다운로드를 위한 네트워크와 저장 공간, CPU 또는 가속기·추론 메모리가 필요합니다. 현재 하드웨어별 최소 요구량과 속도는 검증하지 않았습니다. 모델 파일은 저장소에 포함하지 않습니다.

## 서버 실행

`server/`에서 실행합니다. 아래 명령은 루프백으로 바인딩하며 기존 프로세스를 종료하지 않습니다.

```bash
LOCAL_STT_QWEN_DEVICE_MAP=cpu LOCAL_STT_QWEN_DTYPE=float32 \
LOCAL_STT_QWEN_ISOLATE_PROCESS=1 \
uv run --no-project --env-file .env .venv/bin/python -m uvicorn \
  app.main_local_stt:app --host 127.0.0.1 --port 8000
```

기본 모델 ID는 `Qwen/Qwen3-ASR-1.7B`입니다. `LOCAL_STT_QWEN_MODEL`에 다른 로컬 경로를 지정할 수도 있습니다. 최초 실행은 모델 다운로드·로딩·워밍업으로 지연될 수 있습니다. 모델 로딩과 실제 전사는 이번 공개 준비 작업에서 실행하지 않았습니다.

기존 `scripts/run_local_stt_server.sh`는 zsh 전용이고 `0.0.0.0`으로 바인딩합니다. 기본적으로 같은 로컬 STT 서버 프로세스를 재시작하므로 위 직접 실행 명령을 우선 안내합니다. 이 스크립트를 사용할 때도 `.env`를 먼저 전달해야 합니다.

## 적용 범위

- `POST /speech/turn`: 녹음 파일을 Qwen으로 전사합니다.
- `WS /speech/realtime`: 음성을 버퍼링한 뒤 Qwen으로 전사합니다. 이 모드는 OpenAI 실시간 전사 분기를 사용하지 않습니다.
- `GET /speech/providers`: 런타임·워밍업 상태를 확인합니다. 응답에는 서버의 Python 실행 경로도 포함되므로 외부 공유 시 확인해 주세요.

상태 조회 성공은 실제 음성 인식 정확도나 성능 검증을 의미하지 않습니다.

## Flutter 실행

새 터미널의 프로젝트 루트에서 기본 앱 또는 설정 전용 앱을 선택합니다.

```bash
flutter run -t lib/main.dart \
  --dart-define=ENGLISH_AI_SERVER_BASE_URL=http://127.0.0.1:8000

# 설정 전용 앱을 사용할 때는 위 명령의 진입점을 다음으로 바꿉니다.
# -t lib/main_frontend_local_stt.dart
```

Android 에뮬레이터·USB 실기기 연결 방법은 루트 README를 참고해 주세요.

## 사용하지 않은 OpenAI STT 경로

`server/app/main.py`에는 OpenAI 전사 API로 음성을 인식하는 코드가 남아 있습니다. `app.main:app`을 단독으로 실행하면 이 경로가 쓰이지만, 프로젝트 개발·시연에서는 사용하지 않았고 실행 안내에도 포함하지 않습니다.
