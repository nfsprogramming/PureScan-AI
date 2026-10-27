import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _loadBookmarks();
    return [];
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bookmarked_ingredients');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> toggleBookmark(String ingredientName) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (state.contains(ingredientName)) {
      state = state.where((item) => item != ingredientName).toList();
    } else {
      state = [...state, ingredientName];
    }
    
    await prefs.setStringList('bookmarked_ingredients', state);
  }

  bool isBookmarked(String ingredientName) {
    return state.contains(ingredientName);
  }
}

final bookmarksProvider = NotifierProvider<BookmarksNotifier, List<String>>(() {
  return BookmarksNotifier();
});
