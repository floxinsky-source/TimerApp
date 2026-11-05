#!/bin/bash
# Собирает НЕподписанный TimerApp.ipa (его потом подписывает Sideloadly / AltStore
# / iOS App Signer через ваш Apple ID).
set -euo pipefail
cd "$(dirname "$0")"

rm -rf build Payload TimerApp.ipa

xcodebuild \
  -project TimerApp.xcodeproj \
  -scheme TimerApp \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

mkdir Payload
cp -R build/Build/Products/Release-iphoneos/TimerApp.app Payload/
zip -qry TimerApp.ipa Payload
rm -rf Payload

echo "Готово: $(pwd)/TimerApp.ipa"
