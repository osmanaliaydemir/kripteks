# Security Configuration Guide

## ⚠️ CRITICAL: Secrets Management

This project uses **appsettings.Development.json** (gitignored) to store sensitive configuration locally. **NEVER** commit API keys, connection strings, or other secrets to version control.

## Setup Instructions

### 1. Local Development Setup

After cloning the repository, create your local development configuration:

```bash
cd backend/src/Kripteks.Api
cp appsettings.Development.json.example appsettings.Development.json
```

### 2. Configure Your Secrets

Edit `appsettings.Development.json` and replace the placeholder values with your actual credentials:

- **ConnectionStrings.DefaultConnection**: Your database connection string
- **MailSettings**: Email credentials for notifications
- **JwtSettings.Secret**: A secure random string (minimum 32 characters)
- **AiSettings**: Your AI service API keys
  - DeepSeekApiKey
  - GeminiApiKey
  - OpenAiApiKey
- **NewsSettings.CryptoPanicApiKey**: Your CryptoPanic API key

### 3. Verify Gitignore

The `.gitignore` file is configured to exclude:

- `**/appsettings.Development.json`
- `**/appsettings.*.json` (except appsettings.json)
- `.env` files

**Before committing**, always verify with:

```bash
git status
```

Ensure `appsettings.Development.json` is **NOT** listed in "Changes to be committed".

## Production Deployment

For production environments:

1. **DO NOT** use `appsettings.Development.json`
2. Use environment variables or secure secret management services:
   - Azure Key Vault
   - AWS Secrets Manager
   - Environment variables in hosting platform

3. Configure secrets in your hosting environment (e.g., MonsterASP control panel)

## What's Safe to Commit

✅ **Safe to commit:**

- `appsettings.json` (contains only placeholders)
- `appsettings.Development.json.example` (template with no real secrets)
- `.gitignore`

❌ **NEVER commit:**

- `appsettings.Development.json` (contains real secrets)
- Any file with actual API keys, passwords, or connection strings
- `.env` files with real values

## Emergency: If You Accidentally Commit Secrets

1. **Immediately rotate all exposed credentials** (change passwords, regenerate API keys)
2. Contact the repository administrator
3. Follow GitHub's guide: <https://docs.github.com/code-security/secret-scanning/working-with-secret-scanning-and-push-protection>

## Additional Security Best Practices

- Use strong, unique secrets for each environment
- Rotate credentials regularly
- Use least-privilege access for database users
- Enable 2FA on all service accounts
- Monitor for unauthorized access

---

**Last Updated**: 2026-02-05
**Security Contact**: Repository Administrator
