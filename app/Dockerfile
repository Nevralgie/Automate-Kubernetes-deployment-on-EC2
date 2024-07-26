FROM python:3.9-slim

# Install dependencies for mysql
RUN apt-get update && apt-get install -y \
    gcc \
    libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /python-docker

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

EXPOSE 80

CMD ["python3", "-m" , "flask", "run", "--host=0.0.0.0"]