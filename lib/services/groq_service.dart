import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile.dart';

class GroqService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  final String apiKey;

  GroqService(this.apiKey);

  String? _extractChoiceContent(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;
    final message = first['message'];
    if (message is! Map<String, dynamic>) return null;
    final content = message['content'];
    if (content is! String || content.trim().isEmpty) return null;
    return content;
  }

  Future<String> generateWeekJson(
    int weekNum,
    Profile profile,
    String? prevSummary, {
    String? trainingContext,
  }) async {
    final startDay = (weekNum - 1) * 7 + 1;
    final dayTypes = [
      'PUSH DAY',
      'PULL DAY',
      'LEGS DAY',
      'REST',
      'FULL BODY',
      'CORE DAY',
      'REST'
    ];
    final dayIcons = ['🔥', '💪', '🦵', '😴', '⚡', '🏃', '😴'];

    final intensity = profile.intensityLabel;

    String prompt =
        'Generate week $weekNum of a 100% equipment-free calisthenics + face plan. NO pull-ups, NO rows, NO rowing motion, NO pull-up bar, NO doorway bar, NO hanging, NO rings. ABSOLUTELY ZERO exercises that require pulling bodyweight up. Only floor, wall, chair, bed allowed — nothing that needs installation.\n\n';
    if (trainingContext != null && trainingContext.isNotEmpty) {
      prompt += 'CURRENT TRAINING CONTEXT FROM DATABASE:\n$trainingContext\n';
    }
    prompt +=
        'USER PROFILE:\n- Laziness: ${profile.laziness}/10\n- Body: ${profile.height}cm, ${profile.weight}kg, ${profile.age}yo\n- Goal: ${profile.goal}\n- Experience: ${profile.experience}\n- Time per session: ${profile.timePerSession} min\n';
    if (profile.health.isNotEmpty) {
      prompt += '- Health concerns: ${profile.health}\n';
    }
    prompt += '- Intensity: $intensity\n';
    if (prevSummary != null) prompt += '\nPREVIOUS WEEK PERFORMANCE:\n$prevSummary\n';

    prompt +=
        '\nToday should be treated as the current real calendar day. Make the plan progressive and stronger than the previous week while keeping the user recoverable.\n';
    prompt += '7-day structure:\n';
    for (int i = 0; i < 7; i++) {
      prompt += '  Day ${i + 1}: ${dayTypes[i]} - icon: "${dayIcons[i]}"\n';
    }
    prompt +=
        '\nFor non-rest days, create EXACTLY 6 bodyweight exercises (only floor, chair, bed, wall — NO pull-ups, NO rows, NO hanging), EXACTLY 4 face exercises, and 4 lookmax daily tips. Rest days (4,7) must have empty exercise lists, empty faceExercises, and empty lookmax.\n\n';
    prompt += 'Return ONLY valid JSON with this structure:\n';
    prompt +=
        '{\n  "week": $weekNum,\n  "days": [\n    {\n      "day": $startDay,\n      "week": $weekNum,\n      "title": "PUSH DAY",\n      "focus": "Chest · Triceps",\n      "icon": "🔥",\n      "exercises": [\n        { "name": "Push-Ups", "sets": 3, "reps": "10", "target": "Chest · Triceps", "logKey": "pushup", "logVal": 10 }\n      ],\n      "faceExercises": [\n        { "name": "Chin Tucks", "sets": 3, "reps": "15", "target": "Neck · Chin" }\n      ],\n      "lookmax": [\n        "🧴 Skincare: Wash face + moisturize AM/PM"\n      ]\n    }\n  ]\n}';
    prompt +=
        '\n\nRules:\n- Body exercises logKey: "pushup","squat","plank","burpee", or null.\n- Face exercises have NO logKey/logVal.\n- Timed exercises use "30s" format for reps.\n- DAY 4 AND 7: exercises: [], faceExercises: [], lookmax: [].\n- Day numbering starts from $startDay.\n- Face exercises: use detailed, realistic cues for mewing, chin tucks, jaw clenches, cheek sculptor, eye squints, neck resistance, brow lift, lip press.\n- lookmax: 4 short daily tips covering skincare, posture, diet/grooming, sleep.\n- Progressively increase volume, exercise difficulty, or time under tension compared to the previous week without adding equipment.\n- CRITICAL: Exercise names MUST NOT have "(bodyweight)" or "(no equipment)" or any brackets with descriptors. Just the plain name like "Push-Ups", not "Push-Ups (bodyweight)".';

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an elite calisthenics coach. Generate a weekly workout plan as JSON. Zero equipment, no pull-ups, no hanging exercises. Bodyweight only — floor, chair, bed, wall.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.7,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractChoiceContent(data);
    if (content == null) {
      throw Exception('Groq API returned no usable choices');
    }
    return content;
  }

  Future<String> coachChat(List<Map<String, String>> history, Profile profile) async {
    final systemPrompt = '''You are an elite AI fitness & looksmax coach. The user has this profile:
- Laziness: ${profile.laziness}/10
- Body: ${profile.height}cm, ${profile.weight}kg, ${profile.age}yo
- Goal: ${profile.goal}
- Experience: ${profile.experience}
- Time per session: ${profile.timePerSession} min
${profile.health.isNotEmpty ? '- Health: ${profile.health}' : ''}

Give short, actionable advice. Motivate but be realistic. No fluff.''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': messages,
      'temperature': 0.8,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractChoiceContent(data);
    if (content == null) {
      throw Exception('Groq API returned no usable choices');
    }
    return content;
  }

  Future<Map<String, String>> generateExerciseGuide({
    required String name,
    required String target,
    required String meta,
    required String desc,
  }) async {
    final prompt = '''
Create a concise exercise guide as JSON for this home workout movement.

Exercise:
- Name: $name
- Target: $target
- Meta: $meta
- Description: $desc

Return only JSON with these keys:
- start_position
- body_position
- how_to
- finish_position
- why_it_matters
- mistakes

Rules:
- Keep it practical and specific.
- Use body position cues a person can follow immediately.
- Mention alignment, bracing, and range of motion where relevant.
- Keep each value to 1-2 short sentences.
''';

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {
          'role': 'system',
          'content': 'You write concise fitness instruction in JSON only.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.5,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractChoiceContent(data);
    if (content == null) {
      throw Exception('Groq API returned no usable choices');
    }
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<Map<String, String>> generateFaceGuide({
    required String name,
    required String zone,
    required String reps,
    required String subtitle,
    required String howTo,
    required String benefit,
  }) async {
    final prompt = '''
Create a concise face exercise guide as JSON.

Exercise:
- Name: $name
- Zone: $zone
- Reps: $reps
- Subtitle: $subtitle
- How to: $howTo
- Benefit: $benefit

Return only JSON with these keys:
- start_position
- body_position
- how_to
- finish_position
- why_it_matters
- mistakes

Rules:
- Keep it practical and specific.
- Focus on facial posture, jaw, neck, and relaxation cues where relevant.
- Keep each value to 1-2 short sentences.
''';

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {
          'role': 'system',
          'content': 'You write concise face posture instruction in JSON only.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.5,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractChoiceContent(data);
    if (content == null) {
      throw Exception('Groq API returned no usable choices');
    }
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<String> generateWorkoutMotivation({
    required String workoutName,
    required String target,
    required String phase,
    required String contextLine,
  }) async {
    final prompt = '''
Write one short spoken workout motivation line for the user.

Workout: $workoutName
Target: $target
Phase: $phase
Context: $contextLine

Rules:
- Return only one line.
- Keep it under 20 words if possible.
- Be energetic, fresh, and not repetitive.
- Do not explain form or technique.
- Motivate the user to keep going right now.
''';

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a sharp, energetic workout hype coach. Output only one short line.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 1.0,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractChoiceContent(data);
    if (text == null) {
      throw Exception('Groq API returned no usable choices');
    }
    return text.trim();
  }
}
