import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom_details.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class ClassroomOverviewScreen extends StatefulWidget {
  const ClassroomOverviewScreen({Key? key}) : super(key: key);
  static const routeName = '/classroom-overview-screen';

  @override
  State<ClassroomOverviewScreen> createState() => _ClassroomOverviewScreenState();
}

class _ClassroomOverviewScreenState extends State<ClassroomOverviewScreen> {
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase =
      serviceLocator<GetClassroomByCodeUseCase>();
  Classroom? _selectedRoom;
  ClassroomDetails? _details;
  bool _isDetailsLoading = false;
  String? _detailsError;

  Future<void> _loadDetails(String code) async {
    setState(() {
      _isDetailsLoading = true;
      _detailsError = null;
    });

    try {
      final details = await _getClassroomByCodeUseCase(code: code);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isDetailsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetailsLoading = false;
        _detailsError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomCubit>(
      create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, state) {
          final classrooms = state.classrooms;
          final dropdownItems = classrooms.map((c) => c.name).toList();
          final isInitialLoading = state.isLoading && classrooms.isEmpty;

          if (classrooms.isNotEmpty && _selectedRoom == null) {
            _selectedRoom = classrooms.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadDetails(_selectedRoom!.code);
            });
          }

          final details = _details;
          return GlobalScaffold(
            hasBackButton: false,
            bodyPadding: EdgeInsets.zero,
            body: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClassroomDropdown(
                              items: dropdownItems.isEmpty
                                  ? const ['Loading...']
                                  : dropdownItems,
                              value: dropdownItems.isEmpty
                                  ? 'Loading...'
                                  : (_selectedRoom?.name ?? dropdownItems.first),
                              onChanged: (value) {
                                if (dropdownItems.isEmpty) return;
                                final selected = classrooms
                                    .firstWhere((c) => c.name == value);
                                setState(() {
                                  _selectedRoom = selected;
                                });
                                _loadDetails(selected.code);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          details?.name.isNotEmpty == true
                              ? details!.name
                              : 'Classroom Overview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isInitialLoading || _isDetailsLoading)
                        const Center(child: PrimaryCircularLoader())
                      else ...[
                        if (_detailsError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Failed to load classroom details',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.red,
                                  ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _OverviewStatCard(
                                title: 'Capacity',
                                value: (details?.capacity ?? 0).toString(),
                              ),
                              _OverviewStatCard(
                                title: 'Ratio',
                                value: '${details?.studentsPerTeacher ?? 0}:1',
                              ),
                              _OverviewStatCard(
                                title: 'Status',
                                value: details?.status.isNotEmpty == true
                                    ? details!.status
                                    : 'ACTIVE',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _ClassroomApiDetailsCard(details: details),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _RatioMonitoringPlaceholder(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.5, color: Color.fromARGB(255, 232, 234, 234)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontFamily: 'Manrope', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontFamily: 'Manrope', color: Color(0xff573353), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassroomApiDetailsCard extends StatelessWidget {
  const _ClassroomApiDetailsCard({required this.details});

  final ClassroomDetails? details;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          width: 1.5,
          color: Color.fromARGB(255, 232, 234, 234),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classroom Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Code', value: details?.code ?? '-'),
            _DetailRow(label: 'Type', value: details?.type ?? '-'),
            _DetailRow(label: 'School', value: details?.school ?? '-'),
            _DetailRow(
              label: 'Age Range',
              value: details?.ageRangeLabel ?? '-',
            ),
            _DetailRow(label: 'Created By', value: details?.createdBy ?? '-'),
            _DetailRow(label: 'Updated By', value: details?.updatedBy ?? '-'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: Color(0xff573353),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: Color(0xff573353),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatioMonitoringPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1.5, color: Color.fromARGB(255, 232, 234, 234)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ratio Monitoring', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'Manrope', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Bar(color: Colors.lightBlue[200]!)),
                const SizedBox(width: 8),
                Expanded(child: _Bar(color: Colors.amber)),
                const SizedBox(width: 8),
                Expanded(child: _Bar(color: Colors.green[200]!)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Available', style: TextStyle(fontFamily: 'Manrope')),
                Text('Scheduled', style: TextStyle(fontFamily: 'Manrope')),
                Text('Unscheduled', style: TextStyle(fontFamily: 'Manrope')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)));
  }
}
