# myapp
<img width="272" height="464" alt="image" src="https://github.com/user-attachments/assets/b88ffc4f-b302-4c01-9a65-b8f5f1e0012f" />
<img width="272" height="464" alt="image" src="https://github.com/user-attachments/assets/a6d459aa-9cbe-4e37-a3bd-06ed17597cc5" />




A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    print("done");
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAErD7oG3owrkSuGcjWMP9_HnZi9FcYZBs",
        appId: "1:1018540097624:android:810ab649a493f70bf24a2d",
        messagingSenderId: "1018540097624",
        projectId: "b-fh-bbc87",
        storageBucket: "b-fh-bbc87.appspot.com",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const RatingApp());
}

