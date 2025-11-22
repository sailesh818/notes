import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:notes_todo/auth/page/login_page.dart';
import '../services/notes_service.dart';
import '../model/note.dart';
import 'note_edit.dart';
import 'gifts_page.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final _service = NotesService.instance;
  final Set<String> _selected = {};
  User? _user;

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    // Listen to auth changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });

    _loadAd();
  }

  /// Load Interstitial Ad
  void _loadAd() {
    InterstitialAd.load(
      //adUnitId: "ca-app-pub-3940256099942544/1033173712", // TEST ID
      adUnitId: "ca-app-pub-6704136477020125/7400933744",  //real ads Id
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show Ad → then navigate
  void _showAdThenNavigate() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadAd();
        _goToAddNote();
      }, onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadAd();
        _goToAddNote();
      });

      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _goToAddNote();
    }
  }

  void _goToAddNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditPage()),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (final id in _selected) {
      await _service.deleteNote(id, userId: _user?.uid);
    }
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _selected.isNotEmpty;
    final isLoggedIn = _user != null;

    return Scaffold(
      appBar: AppBar(
        leading: selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selected.clear()),
              )
            : null,
        title: Text(
          selecting ? "${_selected.length} selected" : "My Notes",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (selecting)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (isLoggedIn)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'signout') {
                  await FirebaseAuth.instance.signOut();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'signout',
                  child: Text('Sign out'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Login to restore your notes 🔑",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GiftPage()),
                  );
                },
                icon: const Icon(Icons.card_giftcard, color: Colors.deepPurple),
                label: const Text(
                  'Send Gifts 🎁',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Note>>(
              // ⚡ Updated: watch notes and sort by createdAt descending
              stream: _service.watchNotes(userId: _user?.uid).map((notes) {
                notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return notes;
              }),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final notes = snap.data ?? [];

                if (notes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notes yet!',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notes.length,
                    itemBuilder: (_, index) {
                      final note = notes[index];
                      final isSelected = _selected.contains(note.id);

                      return GestureDetector(
                        onLongPress: () => _toggle(note.id),
                        onTap: () {
                          if (_selected.isNotEmpty) {
                            _toggle(note.id);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteEditPage(note: note),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[100] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade200,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selecting
          ? null
          : FloatingActionButton(
              onPressed: _showAdThenNavigate,
              child: const Icon(Icons.add),
              tooltip: 'Add Note',
            ),
    );
  }
}
