import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

const List<String> _list = [
  'Developer',
  'Designer',
  'Consultant',
  'Student',
];

class SimpleDropdown extends StatelessWidget {
  const SimpleDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      hintText: 'Select job role',
      items: _list,
      initialItem: _list[0],
      onChanged: (value) {},
    );
  }
}
