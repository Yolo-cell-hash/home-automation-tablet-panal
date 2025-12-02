import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ConnectivityPage extends StatelessWidget {
  const ConnectivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Connectivity')),
      child: SafeArea(child: Center(child: Text('Connectivity Options'))),
    );
  }
}
