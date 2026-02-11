# Build stage — override base with: docker build --build-arg ELIXIR_BASE=tag .
# Run script/latest_elixir_base_tag.sh to get the current recommended tag.
ARG ELIXIR_BASE=1.17.0-erlang-26.2.5.4-debian-bookworm-20260202
FROM hexpm/elixir:${ELIXIR_BASE} AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set env for production
ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files and fetch deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV && \
    mkdir -p config && \
    echo "import Config" > config/runtime.exs

# Copy source and compile release
COPY lib lib
RUN mix compile && mix release

# Runtime stage
FROM debian:bookworm-slim AS runtime

WORKDIR /app

# Install runtime deps only (openssl for TLS, ca-certificates)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    ca-certificates \
    libncurses6 \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/bot_army ./

# Default env (override in k8s or docker run)
ENV NATS_HOST=nats
ENV NATS_PORT=4222

USER nobody

CMD ["/app/bin/bot_army", "start"]
