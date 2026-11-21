# --- Builder ---
FROM python:3.12-slim AS builder
WORKDIR /build

# requirements.txt is at REPO ROOT (atlas-platform-app/, not app/)
COPY requirements.txt .
RUN pip install --no-cache-dir --timeout=300 --retries=3 \
    --trusted-host pypi.org --trusted-host files.pythonhosted.org \
    --index-url http://pypi.org/simple/ \
    -r requirements.txt

# Copy app source — lands at /build/app/
COPY . ./app/

# --- Runtime ---
FROM python:3.12-slim
WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser -s /sbin/nologin appuser

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn

# CRITICAL: COPY /build/app → /app/ (contents land as /app/app/main.py)
COPY --from=builder /build/app .

USER appuser
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Path trace:
#   Builder: repo_root/requirements.txt → /build/requirements.txt
#            repo_root/app/main.py      → /build/app/main.py
#   Runtime: COPY /build/app .          → /app/app/main.py ✓
#   CMD:     uvicorn app.main:app       → imports /app/app/main.py ✓