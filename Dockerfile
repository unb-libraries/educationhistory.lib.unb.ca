FROM node:26-alpine AS base

ENV APP_ROOT=/nuxt

ENV NODE_ENV=production

ENV NUXT_SITE_ID=educationhistory
ENV NUXT_SITE_URI=educationhistory.lib.unb.ca
ENV NUXT_SITE_UUID=f1de2d88-eedf-4115-af2b-d55cf0a30215
ENV HUSKY=0

WORKDIR $APP_ROOT

# Deliberately no COPY: keeps this layer pure toolchain, and cached.
RUN apk update && \
    apk add bash && \
    npm install -g corepack && \
    corepack enable pnpm


# Local development image
FROM base AS development

ENV NODE_ENV=development

COPY . .

RUN apk update && \
    apk add curl && \
    pnpm install

CMD ["pnpm", "dev"]


# Throw-away build image
FROM base AS build

# Install from the manifests alone, so editing content/ does not reinstall node_modules.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
# pnpm runs `postinstall` and `prepare` during install, so both files must exist by then.
COPY scripts/postinstall.mjs ./scripts/
COPY .husky/install.mjs ./.husky/

RUN pnpm install --frozen-lockfile --prod=false

COPY . .

# No image is produced if the generated site is incomplete; see the script for why.
RUN pnpm run generate && \
    node scripts/verify-generate.mjs


# Deployment image
FROM ghcr.io/unb-libraries/nuxt-ssg:3.23.x

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Into $APP_WEBROOT, not over it: the base image ships .well-known/ there.
COPY --from=build /nuxt/.output/public/ ${APP_WEBROOT}/

LABEL ca.unb.lib.generator="nuxt-ssg" \
  org.opencontainers.image.title="educationhistory.lib.unb.ca" \
  org.opencontainers.image.description="The Development of the Theory and Practice of Education in New Brunswick 1784-1900." \
  org.opencontainers.image.vendor="University of New Brunswick Libraries" \
  org.opencontainers.image.authors="UNB Libraries <libsupport@unb.ca>" \
  org.opencontainers.image.url="https://educationhistory.lib.unb.ca" \
  org.opencontainers.image.source="https://github.com/unb-libraries/educationhistory.lib.unb.ca" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.version="$VERSION" \
  org.opencontainers.image.revision="$VCS_REF" \
  org.opencontainers.image.created="$BUILD_DATE"
