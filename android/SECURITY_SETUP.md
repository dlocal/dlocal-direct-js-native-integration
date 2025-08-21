# Security Setup Guide

## Protecting Sensitive Data

This project uses environment-based configuration to keep sensitive data like API keys out of version control.

## Setup Instructions

### 1. Configure Your Secrets

1. Copy the template file:
   ```bash
   cp secrets.properties.template secrets.properties
   ```

2. Edit `secrets.properties` and replace the placeholder with your actual DLocal public key:
   ```properties
   DLOCAL_PUBLIC_KEY=your_actual_public_key_here
   ```

### 2. Verify Git Ignore

The `secrets.properties` file is already added to `.gitignore` to prevent accidental commits.

### 3. Build the Project

The public key will be automatically available in your code via `BuildConfig.DLOCAL_PUBLIC_KEY`.

## Security Benefits

- ✅ Secrets are never committed to version control
- ✅ Each developer can use their own keys
- ✅ Easy to rotate keys without code changes
- ✅ Template file shows what needs to be configured

## Important Notes

- **Never commit** `secrets.properties` to version control
- **Always use** `BuildConfig.DLOCAL_PUBLIC_KEY` in your code instead of hardcoded values
- The template file (`secrets.properties.template`) **should be committed** to help other developers

## Troubleshooting

If you get build errors about missing BuildConfig fields:
1. Make sure `secrets.properties` exists and contains valid values
2. Clean and rebuild the project: `./gradlew clean build`
3. Verify that `buildFeatures.buildConfig = true` is set in `build.gradle.kts`
