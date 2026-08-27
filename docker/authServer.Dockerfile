FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://storage.googleapis.com/dart-archive/channels/stable/release/2.7.0/sdk/dartsdk-linux-x64-release.zip -o /tmp/dart.zip \
    && unzip -q /tmp/dart.zip -d /opt \
    && rm /tmp/dart.zip
ENV PATH="/opt/dart-sdk/bin:${PATH}"
WORKDIR /app
COPY vendor/ /vendor/
COPY authServer/pubspec.yaml ./
RUN pub get
COPY authServer/ ./
