FROM openjdk:8

RUN apt update && apt install -y cmake g++ openjdk-8-dbg

RUN git clone --depth=1 https://github.com/jvm-profiling-tools/perf-map-agent /agent && cd /agent && cmake . && make
