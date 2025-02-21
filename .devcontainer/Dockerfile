# mcr.microsoft.com/devcontainers/ruby:3.3
FROM mcr.microsoft.com/devcontainers/ruby@sha256:f0aba6315f624cf37768fa465c90f919e624aef9450365b1ae0e9e3b4f6ce6f9

RUN sudo apt-get update && \
    sudo apt-get install --assume-yes cmake && \
    sudo apt-get clean && \
    wget https://www.python.org/ftp/python/3.12.9/Python-3.12.9.tgz && \
    tar -xzf Python-3.12.9.tgz && \
    cd Python-3.12.9 && \
    ./configure prefix=/usr && \
    make && \
    sudo make install && \
    pip3.12 install build && \
    cd .. && \
    rm -rf Python-3.12.9 && \
    rm Python-3.12.9.tgz
