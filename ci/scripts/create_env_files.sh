#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Generates .env.dev / .env.staging / .env.prod from CI environment variables.
#
# All three files MUST exist at build time because they are declared as Flutter
# assets in pubspec.yaml. Only the file matching the built flavor is actually
# loaded at runtime (main_<flavor>.dart -> dotenv.load('.env.<flavor>')), but
# the asset bundler fails if any of the three are missing.
#
# The library (texts) API has production values only for now, so dev and
# staging fall back to them unless DEV_/STAGING_LIBRARY_* are set.
#
# Mirrors the Codemagic "Create environment files" pre-build step.
# ---------------------------------------------------------------------------
set -euo pipefail

# Every flavor falls back to this one, and the chant list cannot load without
# it, so a build without it would ship broken. Fail here instead.
if [[ -z "${LIBRARY_CHANTS_TAG_ID:-}" ]]; then
  echo "::error::LIBRARY_CHANTS_TAG_ID secret is not set"
  exit 1
fi

# --- Development -----------------------------------------------------------
{
  echo "BASE_API_URL=${DEV_BASE_API_URL:-}"
  echo "LIBRARY_API_URL=${DEV_LIBRARY_API_URL:-${LIBRARY_API_URL:-}}"
  echo "LIBRARY_CHANTS_TAG_ID=${DEV_LIBRARY_CHANTS_TAG_ID:-${LIBRARY_CHANTS_TAG_ID:-}}"
  echo "AUTH0_SCHEME=org.pecha.app.dev"
  echo "AUTH0_AUDIENCE=${DEV_AUTH0_AUDIENCE:-}"
  echo "PHONE_LOGIN_ENABLED=${DEV_PHONE_LOGIN_ENABLED:-false}"
  echo "ENVIRONMENT=development"
} > .env.dev

# --- Staging ---------------------------------------------------------------
{
  echo "BASE_API_URL=${STAGING_BASE_API_URL:-}"
  echo "LIBRARY_API_URL=${STAGING_LIBRARY_API_URL:-${LIBRARY_API_URL:-}}"
  echo "LIBRARY_CHANTS_TAG_ID=${STAGING_LIBRARY_CHANTS_TAG_ID:-${LIBRARY_CHANTS_TAG_ID:-}}"
  echo "AUTH0_SCHEME=org.pecha.app.staging"
  echo "AUTH0_AUDIENCE=${STAGING_AUTH0_AUDIENCE:-}"
  echo "PHONE_LOGIN_ENABLED=${STAGING_PHONE_LOGIN_ENABLED:-false}"
  echo "ENVIRONMENT=staging"
} > .env.staging

# --- Production ------------------------------------------------------------
{
  echo "BASE_API_URL=${BASE_API_URL:-}"
  echo "LIBRARY_API_URL=${LIBRARY_API_URL:-}"
  echo "LIBRARY_CHANTS_TAG_ID=${LIBRARY_CHANTS_TAG_ID:-}"
  echo "AUTH0_SCHEME=org.pecha.app"
  echo "AUTH0_AUDIENCE=${AUTH0_AUDIENCE:-}"
  echo "PHONE_LOGIN_ENABLED=${PHONE_LOGIN_ENABLED:-false}"
  echo "ENVIRONMENT=production"
} > .env.prod

echo "Created .env.dev, .env.staging, .env.prod"
