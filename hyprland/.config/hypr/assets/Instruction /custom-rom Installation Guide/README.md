# ✅ Refined “Fail-Proof” Custom ROM Installation Guide

## 1️⃣ Preparation

```
adb devices
adb reboot bootloader
```

------

## 2️⃣ Boot into Recovery (Temporary OrangeFox)

```
fastboot boot recovery.img
```

> ⚠️ This only boots OrangeFox temporarily. 
>
> (definitely take the recovery.img from orangefox.zip and then place it in the home folder, i mean use cd path/ navigate to folder before running the command....if you're on Linux)

If you want OrangeFox permanently, flash the OrangeFox ZIP from storage after booting into it.

To push it to your phone:

```
adb push OrangeFox-R11.3-spes.zip /sdcard/
```

Then flash it from OrangeFox.

------

## 3️⃣ Clean Wipe (Very Important)

Inside OrangeFox:

- Wipe **Dalvik**
- Wipe **Cache**
- **Format Data** → type `yes`

🚨 **CRITICAL STEP:**
 After formatting, go to:

> Reboot → Recovery

Wait for OrangeFox to fully reload before continuing.

------

## 4️⃣ Flash the ROM (ADB Sideload)

- Go to **Menu → ADB Sideload**
- Swipe to start sideload mode

On your PC:

```
adb sideload crdroid15.zip
```

------

## 5️⃣ Post-Flash Steps

### 🔹 If You Want to Keep OrangeFox (Recommended)

Flash the **OrangeFox ZIP immediately after the ROM**, before rebooting.

------

### 🔹 If Moving from MIUI to Custom ROM

To prevent encryption issues:

- Go to **Wipe**
- **Format Data**
- Type `yes`

(Do this after flashing the ROM and/or GApps.)

------

## 6️⃣ GApps (If Required)

Push to device:

```
adb push MindTheGapps-15.0.0-arm64-20250812_214357.zip /sdcard/
```

Flash it **immediately after installing the ROM**.

After flashing GApps:

- **Format Data again**
- Type `yes`

Then flash it from storage and proceed.

------

## 7️⃣ Magisk (Root)

1. Extract the ROM ZIP on your PC.
2. Locate `boot.img`.
   - If not visible, extract it from `payload.bin`.
3. Transfer `boot.img` to your phone.
4. Patch it using the **Magisk app**.
5. Transfer the patched file back to your PC.

Flash it:

```
fastboot flash boot magisk_patched-30600_6cLee.img
```

------

## 8️⃣ Final Step

Reboot to system.
