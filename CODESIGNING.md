# Code Signing Setup for GitHub Actions

This guide explains how to set up code signing for automated builds and releases.

## Overview

The release workflow supports three modes:
1. **Unsigned builds** (default) - No secrets configured
2. **Signed builds** - With certificate secrets
3. **Signed + Notarized builds** - With certificate and Apple ID secrets

## Prerequisites

### 1. Apple Developer Account
- Enrolled in the Apple Developer Program ($99/year)
- Access to [developer.apple.com](https://developer.apple.com)

### 2. Developer ID Application Certificate
- Log in to [developer.apple.com](https://developer.apple.com)
- Go to Certificates, Identifiers & Profiles
- Create a "Developer ID Application" certificate
- Download and install it in your macOS Keychain

## Step-by-Step Setup

### Step 1: Export Your Certificate

Run the export script:

```bash
./export-certificates.sh
```

This script will:
1. Find your Developer ID Application certificate
2. Export it as a password-protected .p12 file
3. Convert it to base64 for GitHub Secrets
4. Show you the next steps

**Keep the terminal window open** - you'll need the file path for the next step.

### Step 2: Add GitHub Secrets

Go to your GitHub repository:
1. Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add the following secrets:

#### Required for Code Signing

**BUILD_CERTIFICATE_BASE64**
- Click "New repository secret"
- Name: `BUILD_CERTIFICATE_BASE64`
- Value: Copy the contents of the base64 file shown by the export script
  ```bash
  cat /path/to/certificate.p12.base64
  ```

**CERTIFICATE_PASSWORD**
- Name: `CERTIFICATE_PASSWORD`
- Value: The password you used when exporting the certificate

**KEYCHAIN_PASSWORD**
- Name: `KEYCHAIN_PASSWORD`
- Value: Any secure password (this is for the temporary build keychain)
- Example: Generate with `openssl rand -base64 32`

#### Optional for Notarization

**APPLE_ID**
- Name: `APPLE_ID`
- Value: Your Apple ID email address

**APPLE_ID_PASSWORD**
- Name: `APPLE_ID_PASSWORD`
- Value: App-specific password (NOT your Apple ID password)
- Generate at: [appleid.apple.com](https://appleid.apple.com) → Security → App-Specific Passwords

**APPLE_TEAM_ID**
- Name: `APPLE_TEAM_ID`
- Value: Your 10-character Team ID
- Find it at: [developer.apple.com/account](https://developer.apple.com/account) → Membership

### Step 3: Test the Setup

Create and push a test tag:

```bash
git tag v0.0.1-test
git push origin v0.0.1-test
```

Check the Actions tab in GitHub to see if the build succeeds.

## Workflow Behavior

### Without Certificates
```
⚠️  Code signing certificates not configured - building unsigned
    To enable code signing, add BUILD_CERTIFICATE_BASE64, CERTIFICATE_PASSWORD,
    and KEYCHAIN_PASSWORD to your repository secrets
```
- Builds an unsigned app
- Users will see "unidentified developer" warning
- Must right-click → Open on first launch

### With Certificates
```
📦 Building signed release...
✅ Build complete
```
- Builds a signed app
- Reduces security warnings
- Still requires manual approval on first launch

### With Certificates + Notarization
```
📦 Building signed release...
📝 Notarizing app...
✅ Notarization complete
```
- Builds a signed app
- Submits to Apple for notarization
- Staples the notarization ticket
- Users can double-click to open (minimal warnings)

## Security Notes

### Certificate Security
- Never commit certificates or passwords to Git
- GitHub Secrets are encrypted and only accessible to Actions
- The temporary keychain is deleted after each build

### Certificate Expiration
- Developer ID certificates expire after 5 years
- You'll need to renew and re-export when it expires
- GitHub Actions will fail when the certificate expires

### App-Specific Passwords
- Used only for notarization
- Can be revoked at appleid.apple.com
- Not the same as your Apple ID password

## Troubleshooting

### Build fails with "No signing certificate found"
- Check that `BUILD_CERTIFICATE_BASE64` is set correctly
- Verify the certificate hasn't expired
- Ensure it's a "Developer ID Application" certificate (not "Development")

### Notarization fails
- Verify `APPLE_ID` is correct
- Check that `APPLE_ID_PASSWORD` is an app-specific password
- Confirm `APPLE_TEAM_ID` matches your developer account
- Check the notarization logs in the Actions output

### "Unidentified developer" warning persists
- Ensure code signing is working (check build logs)
- For best results, enable notarization
- Notarization can take a few minutes

## Local Development

For local development, code signing is handled automatically by Xcode:
- Uses your local keychain certificates
- No special configuration needed
- The [install-and-run.sh](install-and-run.sh) script handles it

## References

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions: Using secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
