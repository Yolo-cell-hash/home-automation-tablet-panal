import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FrontDoorPage extends StatelessWidget {
  const FrontDoorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Front Door')),
      child: SafeArea(child: Center(child: Text('Front Door Options'))),
    );
  }
}
