// //////////////////////////////////////////////////////////////////container document with no radius/////////////////////////////////////////////////////////////////////////////////////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';
// import 'package:shimmer/shimmer.dart';


// class RectangularDocumentWidget extends StatefulWidget {
//   final String fileUuid;
//   final double width;
//   final double height;
//   final String? placeholderAsset;
//   final BoxFit fit;
//   final VoidCallback? onTap;
//   final BorderRadius? borderRadius;
//   final Widget? errorWidget;
//   final Color? backgroundColor;
//   final Border? border;

//   const RectangularDocumentWidget({
//     Key? key,
//     required this.fileUuid,
//     this.width = 100.0,
//     this.height = 80.0,
//     this.placeholderAsset,
//     this.fit = BoxFit.cover,
//     this.onTap,
//     this.borderRadius,
//     this.errorWidget,
//     this.backgroundColor,
//     this.border,
//   }) : super(key: key);

//   @override
//   State<RectangularDocumentWidget> createState() => _RectangularDocumentWidgetState();
// }

// class _RectangularDocumentWidgetState extends State<RectangularDocumentWidget> {
//   @override
//   void initState() {
//     super.initState();
//     if (widget.fileUuid.isNotEmpty) {
//       _fetchDocument();
//     }
//   }

//   @override
//   void didUpdateWidget(RectangularDocumentWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.fileUuid != oldWidget.fileUuid && widget.fileUuid.isNotEmpty) {
//       _fetchDocument();
//     }
//   }

//   void _fetchDocument() {
//     DataMap parameters = {
//       'fileUuid.equals': widget.fileUuid,
//       'status.equals': 'A'
//     };
//     context.read<DocumentBloc>().add(DownloadDocument(parameters));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: BlocBuilder<DocumentBloc, DocumentState>(
//         builder: (context, state) {
//           if (state is DocumentDownloaded) {
//             Uint8List? imageData = state.fileData;

//                 debugPrint('imageData: $imageData');

//             if (imageData.isNotEmpty) {
//               return _buildContainer(
//                 child: Image.memory(
//                   imageData,
//                   fit: widget.fit,
//                   errorBuilder: (context, error, stackTrace) =>
//                       _buildPlaceholder(),
//                 ),
//               );
//             } else {
//               return _buildPlaceholder();
//             }
//           } else if (state is DownloadingDocument) {
//             return _buildShimmer();
//           } else {
//             return _buildPlaceholder();
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildContainer({required Widget child}) {
//     return Container(
//       width: widget.width,
//       height: widget.height,
//       decoration: BoxDecoration(
//         color: widget.backgroundColor,
//         border: widget.border,
//         borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
//       ),
//       child: ClipRRect(
//         borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
//         child: child,
//       ),
//     );
//   }

//   Widget _buildPlaceholder() {
//     final placeholder = widget.errorWidget ??
//         (widget.placeholderAsset != null
//             ? Image.asset(
//                 widget.placeholderAsset!,
//                 width: widget.width,
//                 height: widget.height,
//                 fit: widget.fit,
//               )
//             : Container(
//                 width: widget.width,
//                 height: widget.height,
//                 color: Colors.grey[200],
//                 child: Center(
//                   child: Image.asset(
//                     MediaRes.userImageMale,
//                     width: widget.width * 0.6,
//                     height: widget.height * 0.6,
//                   ),
//                 ),
//               ));

//     return _buildContainer(child: placeholder);
//   }

//   Widget _buildShimmer() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         width: widget.width,
//         height: widget.height,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
// }