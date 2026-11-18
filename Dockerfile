FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN useradd -m appuser

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

USER appuser

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]