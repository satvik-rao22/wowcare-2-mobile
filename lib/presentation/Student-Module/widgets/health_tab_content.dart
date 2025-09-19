import 'package:flutter/material.dart';
import '../../../domain/features/Student-Module/entities/Student-Entity.dart';

class HealthTabContent extends StatefulWidget {
  const HealthTabContent({required this.student, super.key});

  final StudentEntity student;

  @override
  State<HealthTabContent> createState() => _HealthTabContentState();
}

class _HealthTabContentState extends State<HealthTabContent>
    with TickerProviderStateMixin {
  late TabController _tabControllerSecondary;
  bool isExempted = false;

  // Static data for Physicians, PhysicalTrackers, Immunizations, Vaccines, and ScheduleDoses
  final List<Map<String, dynamic>> _physicians = [
    {
      'firstName': 'Dr. Emily',
      'lastName': 'Smith',
      'email': 'emily.smith@hospital.com',
      'phoneNumber': '1234567890',
      'note': '123 Main St, Springfield',
    },
  ];

  final List<Map<String, dynamic>> _physicalTrackers = [
    {
      'id': 1,
      'physicalDate': '2025-08-15',
      'trackerStatus': 'Completed',
      'physicianId': 1,
    },
    {
      'id': 2,
      'physicalDate': '2025-10-01',
      'trackerStatus': 'Scheduled',
      'physicianId': 1,
    },
  ];

  final List<Map<String, dynamic>> _immunizations = [
    {'id': 1, 'vaccineId': 1},
  ];

  final Map<int, Map<String, dynamic>> _vaccineMap = {
    1: {'id': 1, 'name': 'MMR'},
  };

  final List<Map<String, dynamic>> _scheduleDoses = [
    {
      'immunizationId': 1,
      'doseNumber': 1,
      'doseStatus': 'Completed',
      'date': '2025-06-01',
    },
    {
      'immunizationId': 1,
      'doseNumber': 2,
      'doseStatus': 'Scheduled',
      'date': '2025-09-01',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabControllerSecondary = TabController(length: 4, vsync: this);
    _tabControllerSecondary.addListener(() {
      setState(() {});
    });
  }

  void _onRefresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabControllerSecondary.removeListener(() {
      setState(() {});
    });
    _tabControllerSecondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_tabControllerSecondary.index == 3)
          buildImmunizationExemptionWidget(),
        _buildHealthTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabControllerSecondary,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGeneralHealthCard(),
              _buildPhysicianInfo(),
              _buildHealthDatesInfo(),
              _buildImmunizationInfo(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTabBar() {
    return Transform.translate(
      offset: const Offset(0, 6),
      child: TabBar(
        controller: _tabControllerSecondary,
        labelStyle: const TextStyle(
          color: Colors.blue,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        indicatorPadding: _tabControllerSecondary.index == 0
            ? const EdgeInsets.only(right: 8)
            : _tabControllerSecondary.index == 1
            ? const EdgeInsets.only(right: 8)
            : _tabControllerSecondary.index == 2
            ? const EdgeInsets.only(right: 8)
            : EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        dividerHeight: 0,
        indicator: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border.all(color: Colors.blue.withOpacity(1)),
        ),
        tabs: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTab(
              label: 'Health',
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTab(
              label: 'Physician',
              color: Colors.green.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTab(
              label: 'Dates',
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          Tooltip(
            message: 'Immunization',
            preferBelow: false,
            child: _buildTab(
              label: 'Immunization',
              color: Colors.purple.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String label, required Color color}) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Widget buildImmunizationExemptionWidget() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: IntrinsicWidth(
                child: Row(
                  children: [
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isExempted,
                            onChanged: (value) {
                              setState(() {
                                isExempted = value;
                              });
                            },
                            activeColor: Colors.blue.shade400,
                            activeTrackColor: Colors.blue.shade200,
                            inactiveThumbColor: Colors.grey.shade400,
                            inactiveTrackColor: Colors.grey.shade300,
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Exempt student from all immunizations",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Send Reminder",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralHealthCard() {
    return Column(
      children: [
        Card(
          elevation: 0,
          margin: const EdgeInsets.all(0),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CustomRefreshIndicator(
              displacement: 0,
              onRefresh: () async => _onRefresh(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInfoRow(
                      "Allergies",
                      widget.student.allergies.isNotEmpty
                          ? widget.student.allergies
                          : 'No Allergies',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      "Medication",
                      widget.student.medications.isNotEmpty
                          ? widget.student.medications
                          : 'No Medications',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      "Diet Restrictions",
                      widget.student.dietRestriction.isNotEmpty
                          ? widget.student.dietRestriction
                          : 'No Diet Restrictions',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicianInfo() {
    if (_physicians.isEmpty) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: CustomRefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Text(
                        'No Physicians Added',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    return CustomRefreshIndicator(
      displacement: _physicians.length == 1 ? 0 : null,
      onRefresh: () async => _onRefresh(),
      child: SingleChildScrollView(
        child: Column(
          children: _physicians.map((physician) {
            return Column(
              children: [
                _buildPhysicianCard(
                  name: physician['firstName'],
                  lastName: physician['lastName'],
                  email: physician['email'],
                  phoneNumber: physician['phoneNumber'],
                  address: physician['note'],
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatPhoneNumber(String number) {
    if (number.length != 10) return number;
    return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6, 10)}';
  }

  Widget _buildPhysicianCard({
    required String name,
    required String email,
    required String phoneNumber,
    required String address,
    required String lastName,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${name.isEmpty ? '-' : name}  ${lastName.isEmpty ? '-' : lastName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  phoneNumber.isEmpty ? '--' : _formatPhoneNumber(phoneNumber),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 2, color: Colors.grey),
            const SizedBox(height: 16),
            _buildInfoRow("Email ID", email),
            const SizedBox(height: 16),
            _buildInfoRow("Address", address),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDatesInfo() {
    if (_physicalTrackers.isEmpty) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: CustomRefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Text(
                        'No Checkups Available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    final completedTrackers = _physicalTrackers
        .where((tracker) => tracker['trackerStatus'] == 'Completed')
        .toList();

    final pendingTrackers = _physicalTrackers
        .where((tracker) => tracker['trackerStatus'] != 'Completed')
        .toList();

    completedTrackers.sort(
      (a, b) => DateTime.parse(
        b['physicalDate'],
      ).compareTo(DateTime.parse(a['physicalDate'])),
    );
    final latestCompletedTracker = completedTrackers.isNotEmpty
        ? completedTrackers.first
        : null;

    pendingTrackers.sort(
      (a, b) => DateTime.parse(
        b['physicalDate'],
      ).compareTo(DateTime.parse(a['physicalDate'])),
    );

    final trackersToDisplay = [
      if (latestCompletedTracker != null) latestCompletedTracker,
      ...pendingTrackers,
    ];

    return CustomRefreshIndicator(
      displacement: trackersToDisplay.length == 1 ? 0 : null,
      onRefresh: () async => _onRefresh(),
      child: SingleChildScrollView(
        child: Column(
          children: trackersToDisplay.map((tracker) {
            return _buildHealthDatesCard(
              status: tracker['trackerStatus'],
              checkupDate: tracker['physicalDate'],
              trackerId: tracker['id'],
              onEdit: () => _showEditDialog(
                context,
                tracker['physicalDate'],
                tracker['trackerStatus'],
                tracker['id'],
                widget.student.id,
                widget.student.schoolId,
                tracker['physicianId'],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHealthDatesCard({
    required String checkupDate,
    required String status,
    required VoidCallback onEdit,
    required int trackerId,
  }) {
    String displayStatus = status;
    if (status == 'Missed') {
      displayStatus = 'Overdue';
    }
    if (status == 'Due' && checkupDate.isNotEmpty) {
      final checkupDateTime = DateTime.parse(checkupDate);
      final currentDate = DateTime.now();
      if (checkupDateTime.isBefore(currentDate)) {
        displayStatus = 'Overdue';
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.purple),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: displayStatus == 'Completed'
                        ? Colors.green[50]
                        : displayStatus == 'Overdue'
                        ? Colors.red[50]
                        : displayStatus == 'Scheduled'
                        ? Colors.blue[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: displayStatus == 'Completed'
                          ? Colors.green
                          : displayStatus == 'Overdue'
                          ? Colors.red
                          : displayStatus == 'Scheduled'
                          ? Colors.blue
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              "Checkup Date",
              _formatToReadableDate(DateTime.parse(checkupDate)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatToReadableDate(DateTime date) {
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    String checkupDate,
    String status,
    int trackerId,
    int studentId,
    int schoolId,
    int? physicianId,
  ) {
    final formKey = GlobalKey<FormState>();
    final initialDate = DateTime.parse(checkupDate);
    final TextEditingController dateController = TextEditingController(
      text:
          "${initialDate.year}-${initialDate.month.toString().padLeft(2, '0')}-${initialDate.day.toString().padLeft(2, '0')}",
    );
    String selectedStatus = status;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Physical Examination',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF573353),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF573353),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: dateController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: builderContext,
                                initialDate: DateTime.parse(checkupDate),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  dateController.text =
                                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Physical Checkup Date *',
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['Due', 'Scheduled', 'Completed'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedStatus = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    // Simulate save action
                                    Future.delayed(
                                      const Duration(seconds: 1),
                                      () {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Physical examination updated successfully',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                    );
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7175F4),
                                    Color(0xFF9287F4),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImmunizationInfo() {
    if (widget.student.dateOfBirth.isEmpty) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: CustomRefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Text(
                        'Birth Date Not Added',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    if (_immunizations.isEmpty) {
      return _buildEmptyState('No Immunizations Available');
    }

    return CustomRefreshIndicator(
      displacement: _immunizations.length == 1 ? 0 : null,
      onRefresh: () async => _onRefresh(),
      child: SingleChildScrollView(
        child: Column(
          children: _immunizations.map((immunization) {
            final vaccine = _vaccineMap[immunization['vaccineId']];
            if (vaccine == null) {
              return _buildEmptyState('No vaccine found for this immunization');
            }
            return Column(
              children: [
                _buildImmunizationCard(
                  immunization: immunization,
                  vaccine: vaccine,
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildImmunizationCard({
    required Map<String, dynamic> immunization,
    required Map<String, dynamic> vaccine,
  }) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow("Vaccine", vaccine['name']),
                  if (isExpanded)
                    Column(
                      children: [
                        Divider(color: Colors.grey[200], height: 30),
                        ..._scheduleDoses
                            .where(
                              (dose) =>
                                  dose['immunizationId'] == immunization['id'],
                            )
                            .map((dose) => _buildDoseRow(dose))
                            .toList(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color getStatusColor({required String status, required bool isLabel}) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'Due':
        color = Colors.orange;
        break;
      case 'Overdue':
        color = Colors.red;
        break;
      case 'Scheduled':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return isLabel ? color : color.withOpacity(0.1);
  }

  Widget _buildDoseRow(Map<String, dynamic> dose) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 3.5,
            child: Text(
              "Dose ${dose['doseNumber']}",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 3.5,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: getStatusColor(status: dose['doseStatus'], isLabel: false),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: Text(
                dose['doseStatus'],
                style: TextStyle(
                  color: getStatusColor(
                    status: dose['doseStatus'],
                    isLabel: true,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                dose['date'] == ''
                    ? '--'
                    : _formatToReadableDate(DateTime.parse(dose['date'])),
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double? displacement;

  const CustomRefreshIndicator({
    required this.child,
    required this.onRefresh,
    this.displacement,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement ?? 40.0,
      child: child,
    );
  }
}

class AllStudentsListItem extends StatefulWidget {
  const AllStudentsListItem(
    this.student, {
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final StudentEntity student;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  @override
  State<AllStudentsListItem> createState() => _AllStudentsListItemState();
}

class _AllStudentsListItemState extends State<AllStudentsListItem> {
  // Static classroom data
  final Map<int, Map<String, dynamic>> _classrooms = {
    1: {'id': 1, 'photoUuid': 'classroom_photo1', 'name': 'Classroom A'},
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Checkbox(
            value: widget.isSelected,
            onChanged: widget.onSelectionChanged,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onSelectionChanged(!widget.isSelected),
                    child: Tooltip(
                      message: widget.student.fullName,
                      preferBelow: false,
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  widget.student.fullName.isNotEmpty
                                      ? widget.student.fullName[0]
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.student.isSignedIn ||
                                  widget.student.isAbsent ||
                                  widget.student.profileStatus == 'Upcoming')
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          widget.student.profileStatus ==
                                              'Upcoming'
                                          ? const Color.fromARGB(
                                              255,
                                              253,
                                              205,
                                              22,
                                            )
                                          : widget.student.isSignedIn
                                          ? const Color.fromRGBO(0, 177, 21, 1)
                                          : widget.student.isAbsent
                                          ? const Color.fromRGBO(200, 32, 32, 1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final name = widget.student.fullName.trim();
                                final splitName = name.split(' ');

                                final textStyle = const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                );

                                final textPainter1 = TextPainter(
                                  text: TextSpan(
                                    text: splitName.first,
                                    style: textStyle,
                                  ),
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                )..layout(maxWidth: constraints.maxWidth);

                                final textPainter2 = TextPainter(
                                  text: TextSpan(
                                    text: splitName.length > 1
                                        ? splitName[1]
                                        : '',
                                    style: textStyle,
                                  ),
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                )..layout(maxWidth: constraints.maxWidth);

                                return Text(
                                  textPainter2.didExceedMaxLines ||
                                          textPainter2.width >=
                                              constraints.maxWidth
                                      ? '${splitName.first}\n${splitName.length > 1 ? splitName[1] : ''}'
                                      : name,
                                  style: textStyle,
                                  maxLines:
                                      textPainter1.didExceedMaxLines ||
                                          textPainter1.width >=
                                              constraints.maxWidth ||
                                          splitName.length <= 1
                                      ? 1
                                      : 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.student.roomName.isNotEmpty)
                  Container(
                    height: 20,
                    child: VerticalDivider(
                      color: Colors.blue.withOpacity(0.3),
                      thickness: 0.5,
                      width: 0,
                    ),
                  ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 2,
                  child: Tooltip(
                    message: widget.student.roomName.trim(),
                    preferBelow: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            widget.student.roomName,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildClassroomAvatar(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomAvatar() {
    final classroom = _classrooms[widget.student.roomId];
    if (classroom == null || classroom['photoUuid'].isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.blueGrey,
        radius: 16,
        child: Text(
          widget.student.roomName.isNotEmpty ? widget.student.roomName[0] : 'R',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        classroom['name'][0],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
