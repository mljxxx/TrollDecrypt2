# TrollDecrypt2
iOS IPA Decrypter for TrollStore

## How to use
1. Download and install TrollDecrypt2 from [here](https://github.com/mljxxx/TrollDecrypt2/releases)
2. enter pid or identifier,then click decrypt button
3. if use identifier,it will try to find the process of identifier,and then suspend it,finally decrypt it(use for appex)
4. Once finished decrypting, you can get the `.ipa` file from app document path(use filza).

## How to build
```
git clone https://github.com/mljxxx/TrollDecrypt2.git
cd TrollDecrypt2
open TrollDecrypt2.xcodeproj
build
#find the app file in DerivedData path,and use ldid to add entitlements.
ldid -Sentitlements.plist TrollDecrypt2.app/TrollDecrypt2
then use Payload folder wrap it,zip it,change .zip to .tipa
```

## Credits / Thanks
- [TrollDecryptor](https://github.com/wh1te4ever/TrollDecryptor) by wh1te4ever
- [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted) by Stefan Esser
- [bfdecrypt](https://github.com/BishopFox/bfdecrypt) by BishopFox
- [opa334](https://github.com/opa334) for some pieces of code
- [TrollDecrypt](https://github.com/donato-fiore/TrollDecrypt) by donato-fiore
- App Icon by super.user