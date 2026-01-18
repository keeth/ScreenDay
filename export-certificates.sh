#!/bin/bash

# Script to export certificates for GitHub Actions code signing
# Run this locally to create the certificates that will be uploaded to GitHub Secrets

set -e

echo "📦 Certificate Export Script for GitHub Actions"
echo "================================================"
echo ""
echo "This script will help you export your Apple Developer certificates"
echo "for use in GitHub Actions automated builds."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: $TEMP_DIR"
echo ""

# Prompt for certificate password
echo "🔐 Enter a password to protect the exported certificate:"
echo "   (You'll need to save this as CERTIFICATE_PASSWORD in GitHub Secrets)"
read -s CERT_PASSWORD
echo ""

# Export the certificate
echo "📤 Exporting Developer ID Application certificate..."
echo "   (You may be prompted for your keychain password)"
echo ""

security find-identity -v -p codesigning | grep "Developer ID Application"

echo ""
echo "Enter the SHA-1 hash of your Developer ID Application certificate"
echo "(Copy the 40-character hex string from above):"
read CERT_HASH

if [ -z "$CERT_HASH" ]; then
    echo "❌ Error: No certificate hash provided"
    exit 1
fi

# Export certificate to p12
P12_PATH="$TEMP_DIR/certificate.p12"
security export -k ~/Library/Keychains/login.keychain-db \
    -t identities \
    -f pkcs12 \
    -P "$CERT_PASSWORD" \
    -o "$P12_PATH" \
    "$CERT_HASH"

if [ ! -f "$P12_PATH" ]; then
    echo "❌ Error: Failed to export certificate"
    exit 1
fi

# Convert to base64
CERT_BASE64_PATH="$TEMP_DIR/certificate.p12.base64"
base64 -i "$P12_PATH" -o "$CERT_BASE64_PATH"

echo ""
echo "✅ Certificate exported successfully!"
echo ""
echo "================================================"
echo "Next Steps - Add these to GitHub Secrets:"
echo "================================================"
echo ""
echo "1. Go to your GitHub repository"
echo "2. Settings > Secrets and variables > Actions"
echo "3. Add the following secrets:"
echo ""
echo "   Name: BUILD_CERTIFICATE_BASE64"
echo "   Value: (paste the content of the file below)"
echo "   File: $CERT_BASE64_PATH"
echo ""
echo "   Name: CERTIFICATE_PASSWORD"
echo "   Value: (the password you entered above)"
echo ""
echo "   Name: KEYCHAIN_PASSWORD"
echo "   Value: (choose a temporary password for the build keychain)"
echo ""
echo "4. Optionally add for notarization:"
echo ""
echo "   Name: APPLE_ID"
echo "   Value: (your Apple ID email)"
echo ""
echo "   Name: APPLE_ID_PASSWORD"
echo "   Value: (app-specific password from appleid.apple.com)"
echo ""
echo "   Name: APPLE_TEAM_ID"
echo "   Value: (your 10-character Team ID)"
echo ""
echo "================================================"
echo ""
echo "To view the base64 certificate content:"
echo "  cat $CERT_BASE64_PATH"
echo ""
echo "⚠️  Keep this terminal window open until you've copied the values!"
echo "    The temporary files will be in: $TEMP_DIR"
echo ""
