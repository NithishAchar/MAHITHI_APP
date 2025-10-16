# 📱 MAHITHI – College Information & Authentication App

MAHITHI is a **Flutter + Firebase** application built as a **Final Year Project**.  
It provides a unified platform for **students, faculty, and the public** to register, log in, and access relevant college information in a simple, secure, and user-friendly interface.

---

## 🚀 Features

### 🔐 Authentication
- Firebase Authentication with **Email & Password**
- Separate login and registration for:
  - 👨‍🎓 Students (Login via Registration Number)
  - 👩‍🏫 Faculty (Login via Faculty ID)
  - 🌐 Public Users (Login via Email)
- Password reset via Firebase
- Real-time Auth State Management using **Riverpod**

### 🏠 Core Screens
| Screen | Description |
|---------|--------------|
| **Login Selection Page** | Choose between Student, Faculty, or Public login |
| **Student Login / Register** | Secure student authentication flow |
| **Faculty Registration Page** | Faculty registration & data storage |
| **Public Login / Register** | Access for general users |
| **Forgot Password Screen** | Email-based password recovery |
| **Home Page** | Displays user-specific dashboard |
| **Profile Page** | Shows user information from Firebase |

---

## 🧠 Tech Stack

| Technology | Purpose |
|-------------|----------|
| **Flutter (Dart)** | Frontend UI framework |
| **Firebase Authentication** | User login & signup |
| **Firebase Core** | Firebase project configuration |
| **Riverpod** | State management |
| **Material 3** | Modern UI design |
| **Google Fonts & Animations (optional)** | Enhanced UI aesthetics |

---

## 🏗️ Project Structure
lib/
- ├── main.dart
- ├── firebase_options.dart
- ├── services/
- │ └── firebase_service.dart
- ├── screens/
- │ ├── login_selection_page.dart
- │ ├── home_page.dart
- │ ├── profile_page.dart
- │ ├── student_login_screen.dart
- │ ├── student_registration_screen.dart
- │ ├── faculty_registration_page.dart
- │ ├── public_login_screen.dart
- │ ├── public_registration_screen.dart
- │ └── forgot_password_screen.dart


---

## ⚙️ Installation & Setup

### 1️⃣ Prerequisites
Make sure you have:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0 or above)
- Firebase project created at [Firebase Console](https://console.firebase.google.com/)
- Android Studio / VS Code with Flutter extensions installed

---

### 2️⃣ Clone this repository

git clone https://github.com/your-username/mahithi-app.git
cd mahithi-app
3️⃣ Setup Firebase

Create a new Firebase project.

Enable Email/Password Authentication.

Download your google-services.json and GoogleService-Info.plist.

Run FlutterFire CLI to generate firebase_options.dart:

flutterfire configure

##4️⃣ Install Dependencies
flutter pub get

##5️⃣ Run the App
flutter run

##🧩 Key Providers
Firebase Service Provider
final firebaseServiceProvider = Provider((ref) => FirebaseService());

Auth State Provider
final authStateProvider = StreamProvider((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

##💡 Future Enhancements

- 🔔 Push Notifications using Firebase Cloud Messaging (FCM)

- 🗂️ Cloud Firestore integration for data storage

- 🎨 Enhanced UI with custom animations and theme

- 💬 Chat system for students and faculty

- 📊 Admin dashboard for college management

##📸 Screenshots (Add later)

You can include screenshots of login, register, and home screens here.

👨‍💻 Author

##Nithish Acharya
- LinkedIn:https://www.linkedin.com/in/nithish-acharya-aa7283290
- Github:https://github.com/NithishAchar


💡 Passionate about Flutter, Firebase, and Full-Stack Development

##🪪 License

This project is licensed under the MIT License 

🌟 Support

If you like this project, please give it a ⭐ on GitHub.
