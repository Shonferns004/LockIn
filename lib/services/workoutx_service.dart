import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseMedia {
  final String? imageUrl;

  ExerciseMedia({this.imageUrl});
}

class WorkoutXService {
  static const _baseUrl = 'https://api.workoutxapp.com';

  final String apiKey;
  final Map<String, ExerciseMedia> _cache = {};

  WorkoutXService(this.apiKey);

  // Map our exercise names to search-friendly queries
  static final Map<String, String> _nameOverrides = {
    'push-up': 'push up',
    'squat': 'bodyweight squat',
    'bicycle crunch': 'bicycle crunch',
    'leg raise': 'leg raise',
    'calf raise': 'standing calf raise',
    'wall sit': 'wall sit',
    'superman hold': 'prone hold',
    'snow angels': 'snow angel',
    'self-resistance curl': 'bicep curl',
  };

  String _searchQuery(String exerciseName) {
    final lower = exerciseName.trim().toLowerCase();
    return _nameOverrides[lower] ?? lower.replaceAll('-', ' ');
  }

  Future<ExerciseMedia?> lookup(String exerciseName) async {
    final normalized = exerciseName.trim().toLowerCase();
    if (_cache.containsKey(normalized)) return _cache[normalized];

    try {
      final query = _searchQuery(exerciseName);
      final uri = Uri.parse('$_baseUrl/v1/exercises/name/${Uri.encodeComponent(query)}');
      final response = await http.get(uri, headers: {
        'X-WorkoutX-Key': apiKey,
      });

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final data = body?['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>?;
      final gifUrl = first?['gifUrl'] as String?;
      if (gifUrl == null || gifUrl.isEmpty) return null;

      final media = ExerciseMedia(imageUrl: gifUrl);
      _cache[normalized] = media;
      return media;
    } catch (_) {
      return null;
    }
  }
}
