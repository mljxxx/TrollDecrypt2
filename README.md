# TrollDecrypt2
iOS IPA Decrypter for TrollStore

## Compare With TrollDecrypt
Only support pid or identifier to decrypt.<br/>
Use identifier option,it will try to find the process of identifier,and then suspend it,finally decrypt it.After that it will resume the process.(this use to decrypt app extension)

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
configure Signing in Signing & Capabilities
./build.sh
```

## Credits / Thanks
- [TrollDecryptor](https://github.com/wh1te4ever/TrollDecryptor) by wh1te4ever
- [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted) by Stefan Esser
- [bfdecrypt](https://github.com/BishopFox/bfdecrypt) by BishopFox
- [opa334](https://github.com/opa334) for some pieces of code
- [TrollDecrypt](https://github.com/donato-fiore/TrollDecrypt) by donato-fiore
- App Icon by super.user