# 📱 Flutter Phone - Premium Glassmorphic Dialer (v1.2.7)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Java](https://img.shields.io/badge/Java-21-ED8B00?logo=openjdk&logoColor=white)](https://openjdk.org)
[![Version](https://img.shields.io/badge/Version-1.2.7--Stable-brightgreen)](#release-information)

A state-of-the-art, high-fidelity phone dialer and contact management application built with Flutter. This project pushes the boundaries of mobile UI/UX by combining the functional efficiency of **Samsung's One UI** with the sleek, modern aesthetics of **Google Pixel**, all wrapped in a custom **Glassmorphism Design System**.

---

## 🎨 Design Philosophy & UX

The application utilizes a sophisticated "Frosted Glass" aesthetic. Every interface element is carefully layered to provide depth, clarity, and visual delight:
- **Dynamic Backgrounds**: Real-time calculated ambient orbs and animated gradients that react to user interaction.
- **Micro-Animations**: Custom scale animations on button presses, staggered list entrance animations, and smooth Hero transitions for contact avatars.
- **One UI Reachability**: Collapsing headers and large-target interactive elements designed for one-handed operation.

---

## 🚀 Key Feature Deep Dive

### 🔢 Smart & Adaptive Dialer
- **Predictive Search**: A specialized "Search as you type" engine that parses names and numbers simultaneously.
- **Haptic Keypad**: Each keypress provides tactile feedback and visual scaling for a physical-button feel.
- **Speed Dial Ecosystem**: Fully configurable long-press shortcuts (2-9) available directly from the keypad.

### 📞 Interactive Call Experience
- **Cinematic Call Screen**: Featuring pulsing avatar glows and dynamic wave patterns that visualize the "active" state of a call.
- **In-Call Keypad**: A compact, translucent DTMF keypad that slides in without obstructing the call controls.
- **Advanced State Management**: Integrated "Hold" mode with visual state changes and on-device "Call Recording" simulation.
- **Post-Call Actions**: A dedicated "Call Ended" summary screen with one-tap "Call Back" and "Quick Message" functionality.

### 👥 Professional Contact Management
- **Intelligent Sorting**: Automatic alphabetical grouping with a Samsung-style side alphabet slider for instant navigation.
- **Rich Profiles**: Deep-dive details for every contact including individual call histories and integrated WhatsApp launching.
- **Smart Actions**: High-contrast swipe actions—**Swipe Right to Call** (Green) and **Swipe Left to Message** (Blue)—with rounded, clipped backgrounds.

### ⚙️ Power-User Settings
- **Custom Ringtones**: A robust file-picker system allowing users to import any `.mp3` or `.wav` file as their system ringtone.
- **Developer Options**: Detailed "About" section with build versioning and integrated Support/Feedback channels.
- **Security Suite**: Granular permission handling that respects user privacy for camera, photos, and notification access.

---

## 🛠️ Technical Specifications

### Modern Tech Stack
- **Framework**: Flutter 3.x (Latest Stable)
- **Language**: Dart 3.x
- **Build System**: Gradle 8.10.2 / AGP 8.7.0
- **Runtime**: Optimized for **Java 21 LTS**

### Integrated Libraries
- `image_picker` & `file_picker`: For seamless media handling.
- `permission_handler`: Robust security and OS-level communication.
- `url_launcher`: Deep-linking for SMS, Calls, and WhatsApp.
- `google_fonts`: Precision typography using the *Inter* and *Roboto* families.

---

## 🏗️ Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Java 21+ installed on your development machine
- An Android emulator or physical device

### Installation Steps

1. **Clone & Navigate**:
   ```bash
   git clone https://github.com/your-username/flutter-phone.git
   cd flutter-phone
   ```

2. **Synchronize Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Build Environment**:
   ```bash
   flutter doctor
   ```

4. **Deployment**:
   ```bash
   # Run in Debug mode
   flutter run

   # Build Release APK
   flutter build apk --release
   ```

---

## 📱 Release Information

- **Current Version**: `1.2.7+1`
- **Release Status**: Stable
- **Compatibility**: Android 5.0+ (API 21) and Windows Desktop.
- **License**: Private / Proprietary

---

*Designed and developed to redefine the standard of communication software.*
