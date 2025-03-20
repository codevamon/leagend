# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.2.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Definir directorio de trabajo
WORKDIR /rails

# Instalar dependencias esenciales
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Variables de entorno necesarias
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Fase de construcción
FROM base AS build

# Instalar herramientas de compilación necesarias
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copiar y instalar gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copiar el código de la aplicación
COPY . .

# Precompilar Bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Asegurar que los archivos binarios sean ejecutables
RUN chmod +x bin/* && \
    sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\.exe$/ruby/' bin/*

# Precompilar assets (sin necesidad de SECRET_KEY_BASE real)
RUN SECRET_KEY_BASE=DUMMY ./bin/rails assets:precompile

# Configurar variable de entorno SECRET_KEY_BASE
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Fase final
FROM base

# Copiar artefactos construidos
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Crear usuario seguro para ejecutar la aplicación
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Configurar entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Exponer puerto
EXPOSE 80

# Comando por defecto
CMD ["./bin/rails", "server"]
