// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// enum _PaymentType { invoice, transaction, refund }

// class _PaymentItem {
//   final DateTime date;
//   final _PaymentType type;
//   final dynamic data;

//   _PaymentItem({required this.date, required this.type, required this.data});
// }

// class StudentBillingCard extends StatefulWidget {
//   const StudentBillingCard({required this.students, super.key});

//   // final List<GuardianStudentModel.StudentModel> students;

//   @override
//   State<StudentBillingCard> createState() => StudentBillingCardState();
// }

// class StudentBillingCardState extends State<StudentBillingCard> {
//   List<StudentEntity> students = [];
//   List<StudentDataModel> transactionData = [];
//   List<InvoiceDTO> invoiceList = [];
//   Set<String> invoiceListIds = {};
//   Set<TransactionDetailModel> transactionList = {};
//   List<InvoiceDetailModel> allInvoicesDetails = [];
//   bool isTransactionsLoading = false;
//   ValueNotifier<String> currentBalance = ValueNotifier('\$ 0.0');
//   bool isInvoiceDetailsLoading = false;
//   bool _isPayNowSubmitting = false;

//   void initState() {
//     super.initState();
//     print('🔍 DEBUG - initState called');
//     print('🔍 DEBUG - widget.students count: ${widget.students.length}');
//     print(
//       '🔍 DEBUG - widget.students IDs: ${widget.students.map((s) => s.id).join(', ')}',
//     );
//     _fetchStudent();
//     _fetchTransactions();
//   }

//   Future<void> _fetchStudent() async {
//     final ids = widget.students.map((student) => student.id).join(',');
//     print('🔍 DEBUG - Fetching students with IDs: $ids');

//     try {
//       final data = await context.read<StudentDataCubit>().getAllStudentsData(
//         parameters: {'id.in': ids, 'sort': 'id,desc'},
//       );

//       print('🔍 DEBUG - Fetched ${data.length} students');
//       for (final student in data) {
//         print(
//           '  - Student ID: ${student.id}, Name: ${student.fullName}, School ID: ${student.schoolId}',
//         );
//       }

//       // Save student data locally for immediate use
//       if (data.isNotEmpty) {
//         final student = data.first;
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setInt('payment_student_id', student.id);

//         // Use guardian's school ID for payment (fallback to authenticated school)
//         String schoolCode =
//             (context.currentGuardian?.schoolId ?? AuthProvider.userSchool.id)
//                 .toString();
//         await prefs.setString('payment_school_code', schoolCode);

//         // Get family ID from current guardian (guardian ID = family ID)
//         int familyId = 0;
//         if (context.currentGuardian != null) {
//           familyId = context.currentGuardian!.id;
//         }
//         await prefs.setInt('payment_family_id', familyId);

//         print('💾 Saved student data locally on app open:');
//         print('  studentId: ${student.id}');
//         print('  familyId: $familyId');
//         print('  schoolCode: $schoolCode (from guardian)');
//         print('  studentSchoolId: ${student.schoolId} (not used for payment)');
//       }

//       if (!mounted) return;
//       setState(() {
//         students = data;
//       });

//       print(
//         '🔍 DEBUG - Updated students list, now has ${students.length} students',
//       );
//     } catch (e) {
//       print('❌ ERROR - Failed to fetch students: $e');
//       if (!mounted) return;
//       setState(() {
//         students = [];
//       });
//     }
//   }

//   void refreshData() {
//     allInvoicesDetails.clear();
//     isTransactionsLoading = false;
//     students.clear();
//     invoiceList.clear();
//     transactionList.clear();
//     allInvoicesDetails.clear();
//     invoiceListIds.clear();
//     _fetchStudent();
//     _fetchTransactions();
//   }

//   Future<void> _fetchTransactions() async {
//     if (!mounted) return;
//     setState(() {
//       isTransactionsLoading = true;
//     });

//     print('🔄 FETCHING TRANSACTIONS - Starting API call...');

//     final DataMap parameters = {
//       'size': '100',
//       'status.equals': 'A',
//       'profileStatus.equals': 'A',
//       'schoolId.equals': AuthProvider.userSchool.id.toString(),
//       'page': '0',
//       'isLedgerTransaction.equals': 'false',
//       'studentId.in': context.currentGuardian!.students
//           .map((student) => student.id)
//           .join(','),
//     };

//     print('📋 TRANSACTION PARAMETERS:');
//     print('   Size: ${parameters['size']}');
//     print('   Status: ${parameters['status.equals']}');
//     print('   Profile Status: ${parameters['profileStatus.equals']}');
//     print('   School ID: ${parameters['schoolId.equals']}');
//     print('   Page: ${parameters['page']}');
//     print(
//       '   Is Ledger Transaction: ${parameters['isLedgerTransaction.equals']}',
//     );
//     print('   Student IDs: ${parameters['studentId.in']}');

//     final List<TransactionDetailModel> data = await context
//         .read<BillingDataCubit>()
//         .getTransactionDetails(parameters: parameters);

//     print('✅ TRANSACTIONS FETCHED - Received ${data.length} transactions');

//     if (!mounted) return;
//     setState(() {
//       isTransactionsLoading = false;
//       transactionList = data.toSet();
//     });

//     print('📊 TRANSACTION DATA SUMMARY:');
//     print('   Total transactions: ${data.length}');
//     if (data.isNotEmpty) {
//       print('   First 3 transactions (should be newest first):');
//       for (int i = 0; i < data.length && i < 3; i++) {
//         print(
//           '     ${i + 1}. ID: ${data[i].id}, Type: ${data[i].transactionType}, Date: ${data[i].date}, Amount: ${data[i].amount}',
//         );
//       }
//     }
//     print(
//       '   Transaction types: ${data.map((t) => t.transactionType).toSet().join(', ')}',
//     );
//   }

//   Row _builtChildrenWidget(StudentEntity studentEntity) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         BlocProvider(
//           create: (context) => sl<DocumentBloc>(),
//           child: DocumentImageWidget(
//             fileUuid: studentEntity.photoUuid,
//             name: studentEntity.fullName,
//             size: 30,
//           ),
//         ),
//         const SizedBox(width: 10),
//         // Wrap the Column with a Flexible or Expanded to constrain width
//         Flexible(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 studentEntity.fullName,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   color: AppColors.primaryColor,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               // to Show the current classroom of the student
//               const SizedBox(height: 4),
//               Text(
//                 studentEntity.roomName,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: AppColors.primaryColor,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   List<TransactionDetailModel> updateLocalBalanceAmount(
//     List<TransactionDetailModel> transactions,
//   ) {
//     List<TransactionDetailModel> updatedTransactions = [];
//     transactions.sort((a, b) => (b.date ?? '').compareTo((a.date ?? '')));
//     for (int i = transactions.length - 1; i >= 0; i--) {
//       final current = transactions[i];
//       final next = i < transactions.length - 1
//           ? updatedTransactions.first
//           : null;

//       final type = current.transactionType;
//       final status = current.processStatus ?? '';
//       final amount = current.amount ?? 0.0;
//       final balance = current.balance ?? 0.0;
//       double localBalanceAmount = 0.0;

//       switch (type) {
//         case 'Payment':
//           if (i == transactions.length - 1) {
//             localBalanceAmount = amount;
//           } else if (status == 'Cancelled') {
//             localBalanceAmount = next?.localBalanceAmount ?? 0.0;
//           } else {
//             localBalanceAmount = (next?.localBalanceAmount ?? 0.0) - amount;
//           }
//           break;

//         case 'Refund':
//           localBalanceAmount = (next?.localBalanceAmount ?? 0.0) + amount;
//           break;

//         case 'Credit':
//           if (i == transactions.length - 1) {
//             localBalanceAmount = amount;
//           } else if (status == 'Cancelled') {
//             localBalanceAmount = next?.localBalanceAmount ?? 0.0;
//           } else {
//             localBalanceAmount = (next?.localBalanceAmount ?? 0.0) - amount;
//           }
//           break;

//         case 'Invoice':
//           if (i == transactions.length - 1) {
//             localBalanceAmount = status != 'Cancelled' ? amount : balance;
//           } else if (status == 'Cancelled') {
//             localBalanceAmount = next?.localBalanceAmount ?? 0.0;
//           } else {
//             localBalanceAmount = amount + (next?.localBalanceAmount ?? 0.0);
//           }
//           break;
//       }

//       final updatedTransaction = current.copyWith(
//         localBalanceAmount: localBalanceAmount,
//       );
//       updatedTransactions.insert(0, updatedTransaction); // Maintain order
//     }

//     _checkIfLocalBalanceZeroOrLess(updatedTransactions);
//     return updatedTransactions;
//   }

//   void _checkIfLocalBalanceZeroOrLess(
//     List<TransactionDetailModel> transactions,
//   ) {
//     for (final txn in transactions) {
//       if ((txn.localBalanceAmount ?? 0.0) <= 0) {
//         debugPrint("⚠️ Zero/Negative Balance: ID ${txn.id}");
//       }
//     }
//   }

//   Widget _builtPaymentTile({
//     required TransactionDetailModel transaction,
//     required StudentEntity student,
//   }) {
//     final paidOnStr = transaction.date;
//     final paidOn = DateTime.parse(paidOnStr ?? '');

//     return ExpansionTile(
//       title: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//             decoration: BoxDecoration(
//               color: const Color.fromRGBO(227, 255, 203, 0.4),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Text(
//               'Payment',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Color.fromRGBO(27, 35, 126, 1),
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Status: ${transaction.processStatus}',
//             style: const TextStyle(
//               fontSize: 12,
//               color: AppColors.primaryColor,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.end,
//           ),
//         ],
//       ),
//       trailing: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Text(
//             '\$${transaction.amount}',
//             style: const TextStyle(fontSize: 20, color: AppColors.primaryColor),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Paid On: ${DateUtilsNew.formatToReadableDate(paidOn)}',
//             style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
//           ),
//         ],
//       ),
//       backgroundColor: Colors.white,
//       collapsedBackgroundColor: Colors.white,
//       collapsedShape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//       children: [
//         Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
//         const SizedBox(height: 5),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Payment Method',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Text(
//               '${transaction.paymentMode}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.end,
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Description',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 '${transaction.displayDescription}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.end,
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Open balance',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Text(
//               '\$${transaction.localBalanceAmount}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: CustomFloatingTextButton(
//                 onPressed: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => BlocProvider(
//                         create: (context) => sl<AddressCubit>(),
//                         child: ViewRecepitScreen(
//                           transaction: transaction,
//                           student: student,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//                 label: 'View Recepit',
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _builtInvoiceTile({
//     required InvoiceDTO invoice,
//     required StudentEntity student,
//   }) {
//     final dateStr = invoice.date;
//     final DateTime dueDate = DateTime.parse(dateStr);
//     return ExpansionTile(
//       title: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 80,
//             padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//             decoration: BoxDecoration(
//               color: const Color.fromRGBO(203, 246, 255, 0.4),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Text(
//               'Invoice',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Color.fromRGBO(27, 35, 126, 1),
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Status: ${invoice.invoiceStatus}',
//             style: const TextStyle(
//               fontSize: 12,
//               color: AppColors.primaryColor,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.end,
//           ),
//         ],
//       ),
//       trailing: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Text(
//             '\$${invoice.invoiceAmount}',
//             style: const TextStyle(fontSize: 20, color: AppColors.primaryColor),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Created On: ${DateUtilsNew.formatToReadableDate(dueDate)}',
//             style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
//           ),
//         ],
//       ),
//       backgroundColor: Colors.white,
//       collapsedBackgroundColor: Colors.white,
//       collapsedShape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//       children: [
//         Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
//         const SizedBox(height: 5),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Student Name',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//               textAlign: TextAlign.end,
//             ),
//             const SizedBox(height: 5),
//             _builtChildrenWidget(student),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Description',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 '${invoice.displayDescription}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.end,
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Open balance',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Text(
//               '\$${invoice.openBalanceAmount}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: CustomFloatingTextButton(
//                 onPressed: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           ViewInvoiceScreen(student: student, invoice: invoice),
//                     ),
//                   );
//                 },
//                 label: 'View Invoice',
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _builtRefundTile({
//     required TransactionDetailModel transaction,
//     required StudentEntity student,
//   }) {
//     final paidOnStr = transaction.date;
//     final paidOn = DateTime.parse(paidOnStr ?? '');

//     return ExpansionTile(
//       title: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 80,
//             padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//             decoration: BoxDecoration(
//               color: const Color.fromRGBO(229, 231, 235, 0.4),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Text(
//               'Refund',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Color.fromRGBO(55, 65, 88, 1),
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Status: ${transaction.processStatus}',
//             style: const TextStyle(
//               fontSize: 12,
//               color: AppColors.primaryColor,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.end,
//           ),
//         ],
//       ),
//       trailing: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Text(
//             '\$${transaction.amount}',
//             style: const TextStyle(fontSize: 20, color: AppColors.primaryColor),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Paid On: ${DateUtilsNew.formatToReadableDate(paidOn)}',
//             style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
//           ),
//         ],
//       ),
//       backgroundColor: Colors.white,
//       collapsedBackgroundColor: Colors.white,
//       collapsedShape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//       children: [
//         Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
//         const SizedBox(height: 5),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Payment Method',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Text(
//               '${transaction.paymentMode}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.end,
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Description',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 '${transaction.displayDescription}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.end,
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Open balance',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.primaryColor.withValues(alpha: 0.5),
//               ),
//             ),
//             Text(
//               '\$${transaction.localBalanceAmount}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//       ],
//     );
//   }

//   List<Widget> _builtPaymentList({
//     required List<InvoiceDTO> invoices,
//     required List<TransactionDetailModel> transactions,
//     required List<TransactionDetailModel> refunds,
//   }) {
//     if (invoices.isEmpty && transactions.isEmpty && refunds.isEmpty) {
//       return [
//         const Center(
//           child: Text(
//             'No Transactions',
//             style: TextStyle(fontSize: 16, color: AppColors.primaryColor),
//           ),
//         ),
//       ];
//     }
//     final List<_PaymentItem> items = [
//       ...invoices.map(
//         (invoice) => _PaymentItem(
//           date: DateTime.parse(invoice.date), // Replace with actual date field
//           type: _PaymentType.invoice,
//           data: invoice,
//         ),
//       ),
//       ...transactions.map(
//         (transaction) => _PaymentItem(
//           date: DateTime.parse(
//             transaction.date ?? '',
//           ), // Replace with actual date field
//           type: _PaymentType.transaction,
//           data: transaction,
//         ),
//       ),
//       ...refunds.map(
//         (transaction) => _PaymentItem(
//           date: DateTime.parse(
//             transaction.date ?? '',
//           ), // Replace with actual date field
//           type: _PaymentType.refund,
//           data: transaction,
//         ),
//       ),
//     ];
//     items.sort((a, b) => b.date.compareTo(a.date));
//     final filteredItems = items.length > 3 ? items.sublist(0, 3) : items;
//     return filteredItems.map((item) {
//       switch (item.type) {
//         case _PaymentType.invoice:
//           final invoice = item.data as InvoiceDTO;
//           final student = students.firstWhere((s) => s.id == invoice.studentId);
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: _builtInvoiceTile(invoice: invoice, student: student),
//           );
//         case _PaymentType.transaction:
//           final transaction = item.data as TransactionDetailModel;
//           final student = students.firstWhere(
//             (s) => transaction.students?[0].id == s.id,
//           );
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: _builtPaymentTile(
//               transaction: transaction,
//               student: student,
//             ),
//           );
//         case _PaymentType.refund:
//           final transaction = item.data as TransactionDetailModel;
//           final student = students.firstWhere(
//             (s) => transaction.students?[0].id == s.id,
//           );
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: _builtRefundTile(transaction: transaction, student: student),
//           );
//       }
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 BlocProvider(
//                   create: (context) => sl<StudentDataCubit>(),
//                   child: GestureDetector(
//                     onTap: () =>
//                         Navigator.pushNamed(context, BillingScreen.routeName),
//                     child: Row(
//                       children: [
//                         const Text(
//                           'Billing',
//                           style: TextStyle(
//                             color: AppColors.primaryColor,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         SvgPicture.asset(MediaRes.redirectArrowGradientIcon),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             // Display students using the local students list that's populated in _fetchStudent()
//             students.isEmpty
//                 ? ShimmerLoaderCard(
//                     child: Container(
//                       height: 100,
//                       decoration: ContainerDecorations.decoration0,
//                     ),
//                   )
//                 : GridView.builder(
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           mainAxisSpacing: 0,
//                           childAspectRatio: 2,
//                           crossAxisSpacing: 10,
//                         ),
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: students.length,
//                     shrinkWrap: true,
//                     itemBuilder: (context, index) {
//                       final student = students[index];
//                       return Align(
//                         alignment: Alignment.centerLeft,
//                         child: BlocProvider(
//                           create: (context) {
//                             final totalTransactionBloc =
//                                 sl<billingCubit.BillingCubit>();
//                             final DataMap parameters = {
//                               'studentId.in': student.id.toString(),
//                               'sort': 'id,desc',
//                               'page': '0',
//                               'size': '100',
//                             };
//                             totalTransactionBloc.getTotalTransactions(
//                               parameters: parameters,
//                             );
//                             return totalTransactionBloc;
//                           },
//                           child:
//                               BlocBuilder<
//                                 billingCubit.BillingCubit,
//                                 billingCubit.BillingState
//                               >(
//                                 builder: (context, state) {
//                                   String tooltipMessage = 'Loading totals...';
//                                   if (state is billingCubit.BillingLoaded) {
//                                     final totals = state.totalTransactions;
//                                     tooltipMessage =
//                                         'Paid: \'\$${totals.amountPaid.toStringAsFixed(2)}\'\nIn Process: \'\$${totals.amountInProcess.toStringAsFixed(2)}\'\nUnpaid: \'\$${totals.amountUnpaid.toStringAsFixed(2)}\'';
//                                     WidgetsBinding.instance.addPostFrameCallback((
//                                       _,
//                                     ) {
//                                       currentBalance.value =
//                                           '\$${totals.amountUnpaid.toStringAsFixed(2)}';
//                                     });
//                                   }
//                                   return Tooltip(
//                                     message: tooltipMessage,
//                                     preferBelow: false,
//                                     child: _builtChildrenWidget(student),
//                                   );
//                                 },
//                               ),
//                         ),
//                       );
//                     },
//                   ),
//             const SizedBox(height: 15),
//             if (isTransactionsLoading)
//               ShimmerLoaderCard(child: Container(height: 65)),
//             if (!isTransactionsLoading)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         ValueListenableBuilder(
//                           valueListenable: currentBalance,
//                           builder: (context, value, _) => Text(
//                             value,
//                             style: const TextStyle(
//                               color: AppColors.themeColor,
//                               fontSize: 24,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         const Text(
//                           'Current\nBalance',
//                           style: TextStyle(
//                             color: Color.fromRGBO(65, 65, 76, 0.8),
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     flex: 3,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: CustomFloatingTextButton(
//                         height: 45,
//                         onPressed:
//                             ((students.isEmpty && widget.students.isEmpty) ||
//                                 _isPayNowSubmitting)
//                             ? null
//                             : () async {
//                                 setState(() => _isPayNowSubmitting = true);

//                                 try {
//                                   // Get outstanding amount from current balance
//                                   final outstandingAmount =
//                                       double.tryParse(
//                                         currentBalance.value.replaceAll(
//                                           RegExp(r'[^0-9.]'),
//                                           '',
//                                         ),
//                                       ) ??
//                                       0.0;

//                                   // Show payment dialog
//                                   await showDialog(
//                                     context: context,
//                                     builder: (context) => PaymentDialog(
//                                       outstandingAmount: outstandingAmount,
//                                     ),
//                                   );
//                                 } catch (e) {
//                                   CoreUtils.showTopSnackBar(
//                                     context: context,
//                                     message: 'Error opening payment dialog: $e',
//                                     isError: true,
//                                   );
//                                 } finally {
//                                   if (mounted)
//                                     setState(() => _isPayNowSubmitting = false);
//                                 }
//                               },
//                         label: (students.isEmpty && widget.students.isEmpty)
//                             ? 'Loading...'
//                             : 'Pay Now',
//                         textStyle: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         isFilled: false,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             const SizedBox(height: 15),
//             BlocConsumer<BillingDataCubit, BillingDataState>(
//               listener: (context, state) {
//                 if (state is GettingBillingData) {
//                   List.generate(5, (index) {
//                     return ShimmerLoaderCard(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 8.0),
//                         child: Container(height: 60),
//                       ),
//                     );
//                   });
//                   return;
//                 }
//               },
//               builder: (context, state) {
//                 if (state is BillingError) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     CoreUtils.showTopSnackBar(
//                       context: context,
//                       isError: true,
//                       isWarning: false,
//                       isSuccess: false,
//                       message: 'Failed to Fetch Billing Data: ${state.message}',
//                       isAdjust: false,
//                     );
//                   });
//                   isTransactionsLoading = false;
//                   return const SizedBox();
//                 }

//                 if (state is GettingTransactionDetails) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ...List.generate(3, (index) {
//                         return ShimmerLoaderCard(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Container(height: 60),
//                           ),
//                         );
//                       }),
//                     ],
//                   );
//                 }
//                 if (state is TransactionDetailsLoaded) {
//                   return BlocProvider(
//                     create: (context) {
//                       final bloc = sl<BillingDataCubit>();
//                       List<int> ids = [];
//                       final transactions = updateLocalBalanceAmount(
//                         state.transactions,
//                       );
//                       transactionList = transactions.toSet();
//                       for (final transaction in transactions) {
//                         if (transaction.transactionType == 'Invoice') {
//                           ids.add(transaction.refTableId!);
//                         }
//                       }
//                       final DataMap parameters = {
//                         'status.equals': 'A',
//                         'refTable.equals': 'Invoice',
//                         'refTableId.in': '${ids.join(',')}',
//                         'sort': 'sequence,asc',
//                         'page': '0',
//                         'size': '100',
//                       };
//                       bloc.getInvoiceDetails(parameters: parameters);
//                       return bloc;
//                     },
//                     child: BlocConsumer<BillingDataCubit, BillingDataState>(
//                       listener: (context, state) {
//                         if (state is InvoiceDetailsLoaded ||
//                             state is BillingError) {
//                           setState(() {
//                             isInvoiceDetailsLoading = false;
//                           });
//                         }
//                         if (state is BillingError) {
//                           WidgetsBinding.instance.addPostFrameCallback((_) {
//                             CoreUtils.showTopSnackBar(
//                               context: context,
//                               isError: true,
//                               isWarning: false,
//                               isSuccess: false,
//                               message: 'Failed to Load Transaction',
//                               isAdjust: false,
//                             );
//                           });
//                           setState(() {
//                             isInvoiceDetailsLoading = false;
//                           });
//                           return;
//                         }
//                       },
//                       builder: (context, state) {
//                         if (state is GettingInvoiceDetails) {
//                           return Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               ...List.generate(5, (_) {
//                                 return ShimmerLoaderCard(
//                                   child: Container(
//                                     height: 75,
//                                     child: const SizedBox(),
//                                   ),
//                                 );
//                               }),
//                             ],
//                           );
//                         }
//                         if (state is InvoiceDetailsLoaded) {
//                           final invoiceDetails = state.invoices;
//                           final List<TransactionDetailModel> paymentList =
//                               transactionList
//                                   .where(
//                                     (transaction) =>
//                                         transaction.transactionType ==
//                                         'Payment',
//                                   )
//                                   .toList();
//                           final List<TransactionDetailModel> refundList =
//                               transactionList
//                                   .where(
//                                     (transaction) =>
//                                         transaction.transactionType == 'Refund',
//                                   )
//                                   .toList();
//                           for (final transaction in transactionList) {
//                             if (transaction.transactionType == 'Invoice') {
//                               for (final invoiceDetail in invoiceDetails) {
//                                 if (invoiceDetail.refTableId ==
//                                     transaction.refTableId) {
//                                   InvoiceDTO invoice = InvoiceDTO(
//                                     id: invoiceDetail.id,
//                                     date: transaction.date!,
//                                     sentDate: '',
//                                     dueDate: '',
//                                     startDate: '',
//                                     endDate: transaction.endDate ?? '',
//                                     invoiceAmount: transaction.amount ?? 0.0,
//                                     balanceAmount: transaction.balance ?? 0.0,
//                                     invoiceStatus:
//                                         transaction.processStatus ?? '',
//                                     description: invoiceDetail.description,
//                                     note: transaction.note ?? '',
//                                     studentId: transaction.students?[0].id ?? 0,
//                                     schoolId: invoiceDetail.schoolId,
//                                     status: invoiceDetail.status,
//                                     lastModified: invoiceDetail.lastModified,
//                                     lastModifiedBy:
//                                         invoiceDetail.lastModifiedBy,
//                                     recurringPlanId: 0,
//                                     openBalanceAmount:
//                                         transaction.localBalanceAmount ?? 0.0,
//                                     invoiceNumber:
//                                         transaction.transactionNumber ?? '',
//                                   );
//                                   if (!invoiceListIds.contains(
//                                     invoiceDetail.id.toString(),
//                                   )) {
//                                     invoiceList.add(invoice);
//                                     invoiceListIds.add(
//                                       invoiceDetail.id.toString(),
//                                     );
//                                   }
//                                 }
//                               }
//                             }
//                           }
//                           isInvoiceDetailsLoading = false;
//                           return Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               ..._builtPaymentList(
//                                 invoices: invoiceList.toList(),
//                                 transactions: paymentList,
//                                 refunds: refundList,
//                               ),
//                             ],
//                           );
//                         }
//                         return Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             ...List.generate(5, (_) {
//                               return ShimmerLoaderCard(
//                                 child: Container(
//                                   height: 75,
//                                   child: const SizedBox(),
//                                 ),
//                               );
//                             }),
//                           ],
//                         );
//                       },
//                     ),
//                   );
//                 }
//                 return Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     ...List.generate(5, (_) {
//                       return ShimmerLoaderCard(
//                         child: Container(height: 75, child: const SizedBox()),
//                       );
//                     }),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
