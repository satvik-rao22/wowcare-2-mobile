import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/students/cubit/student_tags_cubit.dart';

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
  final StudentTagsCubit _tagsCubit = serviceLocator<StudentTagsCubit>();
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
      // Uses repository-level caching via CacheManager.
      final names = await _tagsCubit.fetchStudentTagNames(widget.studentCode);
      if (!mounted) return;
      widget.onTagsLoaded(
        names.isNotEmpty ? names : widget.initialTags,
      );
    } catch (_) {
      if (!mounted) return;
      // On error, just use initial tags so UI still shows something.
      widget.onTagsLoaded(widget.initialTags);
    }
  }

  @override
  void dispose() {
    _tagsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget only triggers loading; it renders nothing.
    return const SizedBox.shrink();
  }
}
