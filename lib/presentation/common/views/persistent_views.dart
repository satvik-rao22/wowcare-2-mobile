import 'package:wowcare/core/common/app/providers/tab_navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersistentViews extends StatefulWidget {
  const PersistentViews({super.key,this.body});

  final Widget? body;

  @override
  State<PersistentViews> createState() => _PersistentViewsState();
}

class _PersistentViewsState extends State<PersistentViews> with AutomaticKeepAliveClientMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return  widget.body ?? context.watch<TabNavigator>().currentPage.child;
  }
  
  @override
  bool get wantKeepAlive => true;

  
}
