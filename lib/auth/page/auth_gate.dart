import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_todo/pages/note_list.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _ensureAnonymousLogin() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _ensureAnonymousLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return NoteListPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
