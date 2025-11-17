# 📱 README — Disfruta Antofagasta (Flutter)

Guía **simple, sin FVM** para correr la app en Android y generar APK.

---

## ✅ Requisitos rápidos

* Flutter instalado (global)
* Android Studio (para emulador/SDK)

Comprueba:

```bash
flutter --version
flutter doctor -v
flutter doctor --android-licenses
```

---

## 🚀 Pasos ultra simples

1. **Clona y entra al proyecto**

```bash
git clone <URL_DEL_REPO>
cd disfruta_antofagasta
```

2. **Crea `.env` (solo `API_URL`)**

```bash
printf "API_URL=https://TU_API_AQUI
" > .env
```

3. **Instala dependencias**

```bash
flutter pub get
```

4. **Android: abre un emulador** (o conecta un dispositivo con depuración USB)

* Android Studio → Device Manager → Launch
* O lista dispositivos:

```bash
flutter devices
```

5. **Android: corre la app**

```bash
flutter run -d android
```

6. **Android: genera APK (debug) para compartir rápido**

```bash
flutter build apk --debug
# Salida: build/app/outputs/flutter-apk/app-debug.apk
```

---

### 🍎 iOS (macOS requerido)

A) **Requisitos**

```bash
xcodebuild -version        # Xcode 15+
which pod || sudo gem install cocoapods
cd ios && pod install && cd -
```

B) **Corre en simulador iOS** (iPhone 15, por ejemplo)

```bash
# Abre un simulador desde Xcode (Window > Devices and Simulators) o:
xcrun simctl boot "iPhone 15" || true
flutter devices
flutter run -d ios
```

C) **(Opcional) Generar build para TestFlight/App Store**

> Requiere cuenta de Apple Developer y firmas configuradas.

1. Abre `ios/Runner.xcworkspace` en Xcode.
2. En el target **Runner**, pestaña **Signing & Capabilities**: selecciona tu **Team**, Bundle ID único y modo **Release**.
3. Incrementa versión si corresponde (Marketing/Build).
4. Opción 1 — **Xcode Archive**: Product → Archive → Distribute a TestFlight/App Store.
5. Opción 2 — **CLI** (si ya tienes firmas y ExportOptions):

```bash
flutter build ipa --release
# Exporta con Xcode Organizer o usa un ExportOptions.plist si lo tienes
```


---

## 📦 (Opcional) Release firmado (APK/AppBundle)

Solo si vas a distribuir públicamente o subir a Play Store.

```bash
# 1) Crear keystore (una vez)
keytool -genkey -v -keystore android/keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000

# 2) android/key.properties (NO subir al repo)
cat > android/key.properties << 'EOF'
storePassword=TU_PASS
keyPassword=TU_PASS
keyAlias=upload
storeFile=keystore.jks
EOF

# 3) Generar release
flutter build appbundle --release   # Play Store
# o
flutter build apk --release         # APK firmado
```

---

## 🧯 Problemas comunes

* **Licencias Android**: `flutter doctor --android-licenses` y acepta todo.
* **No aparece dispositivo**: abre un AVD en Android Studio o conecta un teléfono (activar Depuración USB).
* **Error de permisos en scripts**: `chmod +x dev.sh build_apk.sh`.

---

Listo. Con esto cualquiera puede levantar la app y generar el APK sin pasos extra.
