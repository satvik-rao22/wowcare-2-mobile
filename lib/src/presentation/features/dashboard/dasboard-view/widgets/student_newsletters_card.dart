// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';

// import '../../../../../core/res/colors.dart';
// import '../../../../../core/res/media_res.dart';
// import '../../../../../core/util/typedefs.dart';

// class StudentNewslettersCard extends StatefulWidget {
//   const StudentNewslettersCard({
//      super.key});
//   @override
//   State<StudentNewslettersCard> createState() => StudentNewslettersCardState();
// }

// class StudentNewslettersCardState extends State<StudentNewslettersCard> {


//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }


 

   
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       margin: const EdgeInsets.all(0),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             onTap: () =>{},
//             //  Navigator.pushNamed(
//             //   context,
//             //   StudentConversationScreen.routeName,
//             //   arguments: {'tab': StudentConversationScreen.newsletterTab},
//             // ),
//             child: Padding(
//               padding: const EdgeInsets.only(top: 16.0, left: 16.0),
//               child: Row(
//                 children: [
//                   const Text(
//                     'Newsletter',
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   SvgPicture.asset(MediaRes.redirectArrowGradientIcon),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // BlocConsumer<NewsletterCubit, NewsletterState>(
//               //   listener: (context, state) {
//               //     if (state is NewsletterError) {
//               //       CoreUtils.showTopSnackBar(
//               //         context: context,
//               //         isError: true,
//               //         isWarning: false,
//               //         isSuccess: false,
//               //         isAdjust: false,
//               //         message: 'Newsletter Error: ${state.errorMessage}',
//               //       );
//                     // return;
//                   // }
//                 // },
//                 // builder: (context, state) {
//                 //   if (state is AllNewslettersLoaded) {
//                 //     if (filteredNewsletters.isEmpty) {
//                 //       return const Padding(
//                 //         padding: EdgeInsets.only(bottom: 8.0),
//                 //         child: Center(
//                 //           child: Text(
//                 //             'No Newsletters',
//                 //             style: TextStyle(
//                 //               color: AppColors.primaryColor,
//                 //               fontSize: 17,
//                 //               fontWeight: FontWeight.w600,
//                 //             ),
//                 //           ),
//                 //         ),
//                 //       );
//                 //     }
//                     // return Container();
//                     return ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: filteredNewsletters.length > 3
//                           ? 3
//                           : filteredNewsletters.length,
//                       itemBuilder: (context, index) {
//                         final letter = filteredNewsletters[index];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8.0),
//                           child: BlocProvider(
//                             create: (context) => sl<DocumentBloc>(),
//                             child: ExpandableNewsletterItem(newsLetter: letter),
//                           ),
//                         );
//                       },
//                     );
//                   }
//                   return ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: 3,
//                     itemBuilder: (context, index) {
//                       return ShimmerLoaderCard(child: Container(height: 75));
//                     },
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
