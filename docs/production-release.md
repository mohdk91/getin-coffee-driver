# GETIN Driver production release

Production builds must use `APP_ENV=production` and an HTTPS `API_BASE_URL`.

Android submissions target API 36. Keep the upload keystore and `android/key.properties` outside Git.

iOS submissions are built in Codemagic. Configure Apple signing there and use Xcode 26 or later. The source deployment target is iOS 13 or later.

## Android

```bash
export GETIN_API_BASE_URL="https://api.example.com"
export GETIN_BUILD_NAME="1.0.0"
export GETIN_BUILD_NUMBER="1"
bash tool/release/build_android.sh
```

## Codemagic iOS

Set the same three environment values in Codemagic and run:

```bash
bash tool/release/build_ios_codemagic.sh
```

Never commit signing passwords, keystores, API bearer tokens, Stripe secret keys, or webhook secrets.
