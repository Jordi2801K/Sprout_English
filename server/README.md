# Sprout English 서버

FastAPI 기반 영어 학습 API입니다. 전체 프로젝트·역할·검증 결과는 [루트 README](../README.md)를 참고해 주세요.

## 설치와 설정

`server/`에서 실행합니다. Python 3.10 이상, `uv`, MySQL 데이터베이스와 전용 계정을 준비해 주세요.

```bash
uv venv --python 3.10
uv pip install --python .venv/bin/python -r requirements.txt
[ -f .env ] || cp .env.example .env
```

`.env.example`은 값이 모두 비어 있습니다. `.env`에서 API 키와 DB 접속 정보를 채워 주세요. `DB_PORT`는 정수여야 합니다. DB 자체는 먼저 생성해야 하며 서버가 시작 후 테이블 생성을 시도합니다.

## 실행

음성 인식은 Qwen3-ASR 로컬 모델로 처리합니다. 로컬 STT 의존성을 추가로 설치하고 `app.main_local_stt:app` 진입점으로 실행합니다.

```bash
uv pip install --python .venv/bin/python -r requirements-local-stt.txt
LOCAL_STT_QWEN_DEVICE_MAP=cpu LOCAL_STT_QWEN_DTYPE=float32 \
LOCAL_STT_QWEN_ISOLATE_PROCESS=1 \
uv run --no-project --env-file .env .venv/bin/python -m uvicorn \
  app.main_local_stt:app --host 127.0.0.1 --port 8000
```

장치·메모리 설정은 [로컬 STT 안내](../docs/local_stt_switch.md)를 참고해 주세요. 대화·TTS·번역·평가는 OpenAI API를 사용합니다. 모델 학습·파인튜닝은 수행하지 않았습니다. `app.main:app`을 단독으로 실행하면 음성 인식이 코드에 남아 있는 OpenAI STT 경로로 처리되며, 프로젝트에서는 이 경로를 사용하지 않았습니다.

`server/main.py`는 기본 학습 API 진입점이 아닙니다. API 문서는 `http://127.0.0.1:8000/docs`에서 확인할 수 있습니다. `/healthz`는 DB·외부 API 전체의 정상 동작을 보장하지 않습니다.

## 테스트

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -B -m unittest discover \
  -s tests -p 'test_*.py' -v
```

실제 API·DB·모델 추론을 검증하는 통합 테스트는 아닙니다. 실행 결과는 [공개 준비 기록](../docs/PUBLICATION_REVIEW.md)에 구분했습니다.

## 데이터와 레거시 코드

`.env`, `app/storage/`, `data/`, `server/data/`, `models/`, DB 스냅샷·백업은 공개 대상에서 제외합니다. `docs/`의 스키마 정의 SQL과 데이터가 들어 있는 `snapshot*.sql`은 구분합니다.

현재 실행은 `requirements.txt`를 기준으로 안내합니다. `pyproject.toml`·`uv.lock`과 의존성 목록에 차이가 있어 깨끗한 환경의 재설치 검증이 필요합니다. 기존 Alembic 코드는 현재 설정에 없는 `settings.dsn`을 참조하므로 마이그레이션 절차를 실행 안내에 포함하지 않았습니다. 기존 `tools/db_*_abs.sh`는 개인 경로를 사용하므로 공개 대상에서 제외하고 실행하지 않았습니다.
