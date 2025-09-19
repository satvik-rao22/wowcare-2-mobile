import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/features/Student-Module/Student-Module-DataSource/student_data_cubit.dart';
import '../../../domain/features/Student-Module/entities/Student-Entity.dart';
import '../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../shared/common/widgets/custom_shimmer_loader.dart';

class DatesTabContent extends StatefulWidget {
  const DatesTabContent({required this.student, super.key});

  final StudentEntity student;

  @override
  State<DatesTabContent> createState() => _DatesTabContentState();
}

class _DatesTabContentState extends State<DatesTabContent> {
  @override
  void initState() {
    super.initState();
    context.read<StudentDataCubit>().getAllStudents(widget.student.id);
  }

  void _onRefresh() {
    context.read<StudentDataCubit>().getAllStudents(widget.student.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: CustomRefreshIndicator(
        onRefresh: () async => _onRefresh(),
        child: SingleChildScrollView(
          child: BlocBuilder<StudentDataCubit, StudentDataState>(
            builder: (context, state) {
              if (state is AllStudentsDataLoaded) {
                final student = state.students.first;
                final dateEntries = [
                  {
                    'label': 'Enroll Date',
                    'date': student.registrationDate,
                    'status': 'completed',
                  },
                  {
                    'label': 'School Start Date',
                    'date': student.startDate,
                    'status': 'completed',
                  },
                  {
                    'label': 'Current Classroom Start Date',
                    'date': student.roomStartDate,
                    'status': 'completed',
                  },
                  {
                    'label': 'Upcoming Move Date',
                    'date': student.expectedMoveDate,
                    'status': 'overdue',
                  },
                  {
                    'label': 'School Leaving Date',
                    'date': student.leavingDate,
                    'status': 'due',
                  },
                ];

                final completedDates = dateEntries
                    .where(
                      (entry) =>
                          entry['status'] == 'completed' &&
                          entry['date'].toString().isNotEmpty,
                    )
                    .toList();
                final nonCompletedDates = dateEntries
                    .where(
                      (entry) =>
                          [
                            'due',
                            'scheduled',
                            'overdue',
                          ].contains(entry['status']) &&
                          entry['date'].toString().isNotEmpty,
                    )
                    .toList();

                completedDates.sort(
                  (a, b) => DateTime.parse(
                    b['date'].toString(),
                  ).compareTo(DateTime.parse(a['date'].toString())),
                );
                final latestCompleted = completedDates.isNotEmpty
                    ? completedDates.first
                    : null;

                nonCompletedDates.sort(
                  (a, b) => DateTime.parse(
                    b['date'].toString(),
                  ).compareTo(DateTime.parse(a['date'].toString())),
                );
                final latestNonCompleted =
                    nonCompletedDates.isNotEmpty &&
                        (latestCompleted == null ||
                            DateTime.parse(
                                      nonCompletedDates.first['date']
                                          .toString(),
                                    )
                                    .difference(
                                      DateTime.parse(
                                        latestCompleted?['date'].toString() ??
                                            '2000-01-01',
                                      ),
                                    )
                                    .inDays >=
                                365)
                    ? nonCompletedDates.first
                    : null;

                final displayDates = [
                  if (latestCompleted != null) latestCompleted,
                  if (latestNonCompleted != null) latestNonCompleted,
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Important Dates",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (displayDates.isEmpty)
                      const Center(
                        child: Text(
                          'No relevant dates available',
                          style: TextStyle(color: Colors.blue, fontSize: 15),
                        ),
                      )
                    else
                      ...displayDates.map(
                        (entry) => Column(
                          children: [
                            _buildDateRow(
                              entry['label'].toString(),
                              entry['date'].toString(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                  ],
                );
              } else if (state is GettingAllStudentsData) {
                return const ShimmerLoader(height: 400);
              }
              return Center(
                child: Text(
                  'Error fetching data',
                  style: TextStyle(color: Colors.blue.withOpacity(0.6)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Tooltip(
            preferBelow: false,
            message: label,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blue.withOpacity(0.5),
                letterSpacing: 14 * (-3 / 100),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            date.isEmpty
                ? '- -'
                : DateFormat('MMM dd, yyyy').format(DateTime.parse(date)),
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
