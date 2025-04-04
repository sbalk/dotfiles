#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <package_name>"
    echo "Example: $0 requests"
    exit 1
}

# Check if a package name is provided
if [ $# -eq 0 ]; then
    usage
fi

PACKAGE_NAME="$1"
PACKAGE_NAME_NO_DASHES=$(echo "$PACKAGE_NAME" | tr - _)

# Get the latest version
echo "Fetching package information..."
LATEST_VERSION=$(pip index versions "$PACKAGE_NAME" 2>/dev/null | head -n 1 | awk '{print $2}')

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not find version information for $PACKAGE_NAME"
    exit 1
fi

# Remove parentheses from version number
CLEAN_VERSION=$(echo "$LATEST_VERSION" | tr -d '()')

# Construct PyPI URL for the .tar.gz file
DOWNLOAD_URL="https://files.pythonhosted.org/packages/source/${PACKAGE_NAME:0:1}/$PACKAGE_NAME/$PACKAGE_NAME_NO_DASHES-$CLEAN_VERSION.tar.gz"

# Print latest version and URL
echo "Latest version: $LATEST_VERSION"
echo "Download URL: $DOWNLOAD_URL"

# Extract filename from URL
FILENAME="$PACKAGE_NAME-$CLEAN_VERSION.tar.gz"

# Download the package
echo "Downloading $PACKAGE_NAME $LATEST_VERSION..."
wget -q --show-progress "$DOWNLOAD_URL" -O "$FILENAME"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to download the package. The .tar.gz file might not exist for this package."
    exit 1
fi

# Run OpenSSL SHA256 on the downloaded package
echo "Calculating SHA256 hash..."
openssl dgst -sha256 "$FILENAME"

# Clean up the downloaded file (optional)
# Uncomment the following line if you want to remove the downloaded file after processing
# rm "$FILENAME"

echo "Run the following commands:"
echo "git fetch upstream"
echo "git checkout -b $CLEAN_VERSION"
echo "git reset --hard upstream/main"
echo "# 👋 make the changes now! 👮‍♀️"
echo "git add -u ."
echo "git commit -m \"Bump to $PACKAGE_NAME $CLEAN_VERSION\""
echo "git push origin $CLEAN_VERSION"
