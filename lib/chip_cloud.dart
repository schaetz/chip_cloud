library chip_cloud;

import 'package:flutter/material.dart';

import 'chip_cloud_delegate.dart';
import 'chip_cloud_options.dart';

//
// A widget that arranges chips or similar widgets in a multi-line layout,
// similar to the Wrap widget, but makes sure that the layout remains
// within the given constraints by hiding chips that cause an overflow.
//
// Can optionally add a final element that indicates that some elements
// have been left out.
//
class ChipCloud<T> extends StatelessWidget {
  final List<T> data;
  final Size constraints;
  final ChipCloudOptions options;

  const ChipCloud({super.key, required this.data, required this.constraints, this.options = const ChipCloudOptions()});

  @override
  Widget build(BuildContext context) {
    return Flow(delegate: ChipCloudDelegate(constraints, options: options), children: _buildElements());
  }

  List<Widget> _buildElements() {
    final elements = data.map<Widget>((T dataSet) => buildElement<T>(dataSet)).toList();
    if (options.showOverflowIndicator == true) {
      elements.add(buildOverflowIndicator());
    }
    return elements;
  }

  Widget buildElement<D>(D dataSet, {Color? backgroundColor}) {
    return Chip(
      label: Text(D == String ? dataSet as String : dataSet.toString()),
      labelStyle: const TextStyle(fontSize: 14.0),
      backgroundColor: backgroundColor,
    );
  }

  Widget buildOverflowIndicator() {
    return buildElement<String>('...', backgroundColor: Colors.white);
  }
}
