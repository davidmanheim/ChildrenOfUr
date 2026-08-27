FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://storage.googleapis.com/dart-archive/channels/stable/release/2.1.1/sdk/dartsdk-linux-x64-release.zip -o /tmp/dart.zip \
    && unzip -q /tmp/dart.zip -d /opt \
    && rm /tmp/dart.zip
# Dart 2.1.1's legacy dev compiler emits a dynamic method call for the
# `timerTicks` function stored on Primitives.  Modern browsers surface that as
# NoSuchMethodError on Type whenever Stopwatch is used.  Call the function
# directly, matching the fixed kernel compiler runtime shipped in the SDK.
RUN perl -pi -e 's/dart\.dsend\([^,]+, .timerTicks., \[\]\)/dart.dcall(_js_helper.Primitives.timerTicks, [])/g' /opt/dart-sdk/lib/dev_compiler/legacy/dart_sdk.js /opt/dart-sdk/lib/dev_compiler/*/legacy/dart_sdk.js
ENV PATH="/opt/dart-sdk/bin:${PATH}"
WORKDIR /app
COPY vendor/ /vendor/
COPY coUclient/pubspec.yaml ./
RUN pub get
RUN pub global activate webdev 1.0.0
COPY coUclient/ ./
