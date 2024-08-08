# Stage 1: Build and test
FROM python:3.9 AS build

WORKDIR /app

COPY . /app

RUN pip3 install --no-cache-dir -r requirements.txt

# Install test dependencies separately (optional)
RUN pip3 install --no-cache-dir pytest pytest-flask requests-mock app

ENV PYTHONPATH=/app

# Run tests
RUN pytest --tb=short --disable-warnings --junitxml=report.xml

CMD ["flask", "run", "--host=0.0.0.0"]

# Stage 2: Production
FROM python:3.9 AS production

# Set the working directory
WORKDIR /app

RUN shopt -s extglob && cp -r "./!(tests)" /app

# # Copy only necessary files from the build stage
# COPY ./!(tests) /app

RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0"]