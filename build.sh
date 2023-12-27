rm -rf ./DerivedData ./Payload ./Payload.tipa
xcodebuild build -project TrollDecrypt2.xcodeproj -scheme TrollDecrypt2 -destination 'generic/platform=iOS' -sdk iphoneos -configuration Release -derivedDataPath DerivedData
mkdir ./Payload
cp -r ./DerivedData/Build/Products/Release-iphoneos/TrollDecrypt2.app ./Payload/TrollDecrypt2.app
ldid -Sentitlements.plist Payload/TrollDecrypt2.app/TrollDecrypt2
zip -r -q -o TrollDecrypt2.tipa ./Payload