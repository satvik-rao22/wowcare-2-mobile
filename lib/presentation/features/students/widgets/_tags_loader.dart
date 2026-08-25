import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

/// Lightweight widget to lazily load tags for a student using
/// `GET /api/v1/student-tags/{studentCode}` and report them back
/// to the parent via [onTagsLoaded].
class TagsLoader extends StatefulWidget {
  const TagsLoader({
    required this.studentCode,
    required this.initialTags,
    required this.onTagsLoaded,
  });

  final String studentCode;
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsLoaded;

  @override
  State<TagsLoader> createState() => _TagsLoaderState();
}

class _TagsLoaderState extends State<TagsLoader> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final repo = serviceLocator<StudentRepository>();
      // Uses repository-level caching via CacheManager.
      final names =
          await (repo as dynamic).getStudentTagNames(
                studentCode: widget.studentCode,
              )
              as List<String>;
      if (!mounted) return;
      widget.onTagsLoaded(names.isNotEmpty ? names : widget.initialTags);
    } catch (_) {
      if (!mounted) return;
      // On error, just use initial tags so UI still shows something.
      widget.onTagsLoaded(widget.initialTags);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget only triggers loading; it renders nothing.
    return const SizedBox.shrink();
  }
}
