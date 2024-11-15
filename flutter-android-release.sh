#!/bin/bash

# Check if keytool command exists
if ! command -v keytool &> /dev/null; then
    echo "Keytool not found. Installing keytool..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y openjdk-11-jdk
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install openjdk@11
    elif [[ "$OSTYPE" == "msys" ]]; then
        echo "Please install keytool manually for Windows."
        exit 1
    else
        echo "Unsupported OS. Please install keytool manually."
        exit 1
    fi
fi

# Set default values
DEFAULT_KEYSTORE="keys/upload-keystore.jks"
DEFAULT_KEY_ALIAS="upload"
DEFAULT_KEY_PASSWORD="123456"
DEFAULT_KEY_STORE_PASSWORD="123456"
DEFAULT_VALIDITY=10000

# Create keys directory if not exists
mkdir -p keys

# Check if keystore exists
if [[ -f "$DEFAULT_KEYSTORE" ]]; then
    read -p "Keystore already exists. Do you want to overwrite it? (y/n): " overwrite_keystore
    # Delete keystore if user wants to overwrite
    if [[ "$overwrite_keystore" == "y" ]]; then
        rm -f "$DEFAULT_KEYSTORE"
    fi
    if [[ "$overwrite_keystore" != "y" ]]; then
        echo "Skipping keystore creation."
        exit 0
    fi
fi

# Ask for custom values or use defaults
read -p "Enter key alias (default: $DEFAULT_KEY_ALIAS): " key_alias
key_alias=${key_alias:-$DEFAULT_KEY_ALIAS}

read -p "Enter key password (default: hidden): " -s key_password
key_password=${key_password:-$DEFAULT_KEY_PASSWORD}
echo

read -p "Enter keystore password (default: hidden): " -s keystore_password
keystore_password=${keystore_password:-$DEFAULT_KEY_STORE_PASSWORD}
echo

# Additional values for keystore information
read -p "Enter your first and last name (default: Unknown): " first_last_name
first_last_name=${first_last_name:-Unknown}

read -p "Enter your organizational unit (default: Unknown): " org_unit
org_unit=${org_unit:-Unknown}

read -p "Enter your organization (default: Unknown): " organization
organization=${organization:-Unknown}

read -p "Enter your city or locality (default: Unknown): " city
city=${city:-Unknown}

read -p "Enter your state or province (default: Unknown): " state
state=${state:-Unknown}

read -p "Enter your two-letter country code (default: US): " country
country=${country:-US}

# Generate keystore with additional information
keytool -genkey -v -keystore "$DEFAULT_KEYSTORE" -storepass "$keystore_password" \
    -keyalg RSA -keysize 2048 -validity "$DEFAULT_VALIDITY" -alias "$key_alias" -keypass "$key_password" \
    -dname "CN=$first_last_name, OU=$org_unit, O=$organization, L=$city, S=$state, C=$country"

echo "Keystore generated at $DEFAULT_KEYSTORE."

# Create or update android/key.properties
KEY_PROPERTIES_FILE="android/key.properties"
if [[ -f "$KEY_PROPERTIES_FILE" ]]; then
    read -p "key.properties file exists. Do you want to overwrite it? (y/n): " overwrite_key_properties
    if [[ "$overwrite_key_properties" != "y" ]]; then
        echo "Skipping key.properties creation."
        exit 0
    fi
fi

cat <<EOF > $KEY_PROPERTIES_FILE
storePassword=$keystore_password
keyPassword=$key_password
keyAlias=$key_alias
storeFile=../../$DEFAULT_KEYSTORE
EOF
echo "Created key.properties file."

# Update android/app/build.gradle
GRADLE_FILE="android/app/build.gradle"
SIGNING_CONFIG="    signingConfigs {\n        release {\n            keyAlias = keystoreProperties['keyAlias']\n            keyPassword = keystoreProperties['keyPassword']\n            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n            storePassword = keystoreProperties['storePassword']\n        }\n    }\n"

KEYSTORE_PROPERTIES_CONFIG="def keystoreProperties = new Properties()\ndef keystorePropertiesFile = rootProject.file('key.properties')\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n}\n"

if [[ -f "$GRADLE_FILE" ]]; then
    if ! grep -q "def keystoreProperties" "$GRADLE_FILE"; then
        awk -v config="$KEYSTORE_PROPERTIES_CONFIG" '/android \{/ {print config;} 1' "$GRADLE_FILE" > temp.gradle && mv temp.gradle "$GRADLE_FILE"
        echo "Keystore properties added to build.gradle."
    else
        echo "Keystore properties already exist in build.gradle."
    fi

    if ! grep -q "signingConfigs {" "$GRADLE_FILE"; then
        awk -v config="$SIGNING_CONFIG" '/^android {/ { print; print config; next }1' "$GRADLE_FILE" > temp.gradle && mv temp.gradle "$GRADLE_FILE"
        echo "Signing configuration added to build.gradle."
    else
        echo "Signing configuration already exists in build.gradle."
    fi

    # Replace signingConfig signingConfigs.debug with signingConfig signingConfigs.release
    if grep -q "signingConfig signingConfigs.debug" "$GRADLE_FILE"; then
        sed -i.bak 's/signingConfig signingConfigs\.debug/signingConfig signingConfigs\.release/g' "$GRADLE_FILE"
        echo "Replaced 'signingConfig signingConfigs.debug' with 'signingConfig signingConfigs.release' in $GRADLE_FILE."
    else
        echo "'signingConfig signingConfigs.debug' not found in $GRADLE_FILE."
    fi
else
    echo "Error: build.gradle file not found at $GRADLE_FILE."
fi

# Check AndroidManifest.xml for INTERNET permission
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
INTERNET_PERMISSION='<uses-permission android:name="android.permission.INTERNET"/>'

if [[ -f "$MANIFEST_FILE" ]]; then
    if ! grep -q "$INTERNET_PERMISSION" "$MANIFEST_FILE"; then
        read -p "INTERNET permission not found in AndroidManifest.xml. Do you want to add it? (y/n): " add_permission
        if [[ "$add_permission" == "y" ]]; then
            awk -v permission="$INTERNET_PERMISSION" '/<manifest/{print; print permission; next}1' "$MANIFEST_FILE" > temp.xml && mv temp.xml "$MANIFEST_FILE"
            echo "INTERNET permission added to AndroidManifest.xml."
        else
            echo "Skipping INTERNET permission addition."
        fi
    else
        echo "INTERNET permission already exists in AndroidManifest.xml."
    fi
else
    echo "Error: AndroidManifest.xml file not found at $MANIFEST_FILE."
fi

echo "Script completed."
