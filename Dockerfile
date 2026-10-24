# Use Python 3.9 slim as base (required for spaCy 2.3.5 and thinc compatibility)
FROM python:3.9-slim

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# Set root working directory
WORKDIR /app

# Install system dependencies needed for compiling packages and database client
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    curl \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file first to take advantage of Docker layer caching
COPY App/requirements.txt /app/App/requirements.txt

# Install Python dependencies, spaCy model, and NLTK stopwords, then purge build tools to save disk space
RUN pip install --no-cache-dir --upgrade pip "setuptools<70" wheel && \
    pip install --no-cache-dir -r /app/App/requirements.txt && \
    pip install --no-cache-dir https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-2.3.1/en_core_web_sm-2.3.1.tar.gz && \
    mkdir -p /root/nltk_data/corpora && \
    curl -sSL https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/stopwords.zip -o /tmp/stopwords.zip && \
    python -m zipfile -e /tmp/stopwords.zip /root/nltk_data/corpora && \
    rm -f /tmp/stopwords.zip && \
    apt-get purge -y --auto-remove build-essential gcc g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cache /tmp/*

# Copy the application source code into the image
COPY . /app

# Patch pyresparser with the custom resume_parser.py provided in the repository
RUN PY_SITE=$(python -c "import site; print(site.getsitepackages()[0])") && \
    cp pyresparser/resume_parser.py "$PY_SITE/pyresparser/resume_parser.py" && \
    echo "Successfully patched pyresparser in $PY_SITE/pyresparser"

# Switch working directory to App (where App.py, Courses.py, and Logo are located)
WORKDIR /app/App

# Expose Streamlit default port
EXPOSE 8501

# Healthcheck to verify that Streamlit server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl --fail http://localhost:8501/healthz || exit 1

# Start the Streamlit application
ENTRYPOINT ["streamlit", "run", "App.py", "--server.port=8501", "--server.address=0.0.0.0"]
