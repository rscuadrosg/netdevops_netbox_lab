FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# The base image ships the Yarn apt repo with an expired GPG key, which
# breaks apt-get update and the docker-in-docker install. Yarn is unused.
RUN rm -f /etc/apt/sources.list.d/yarn*
