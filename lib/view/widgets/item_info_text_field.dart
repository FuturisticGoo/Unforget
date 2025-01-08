import 'package:flutter/material.dart';

class ItemInfoTextFormField extends StatefulWidget {
  const ItemInfoTextFormField({
    super.key,
    required this.initialValue,
    required this.label,
    required this.readOnly,
    this.controller,
    this.validator,
  });
  final String label;
  final String initialValue;
  final bool readOnly;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  @override
  State<ItemInfoTextFormField> createState() => _ItemInfoTextFormFieldState();
}

class _ItemInfoTextFormFieldState extends State<ItemInfoTextFormField> {
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          widget.controller?.text = widget.initialValue;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextFormField(
        key: Key("${widget.label}:${widget.readOnly}"),
        initialValue: widget.controller == null ? widget.initialValue : null,
        controller: widget.controller,
        readOnly: widget.readOnly,
        validator: widget.validator,
        decoration: (widget.readOnly)
            ? InputDecoration(
                label: Text(widget.label),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              )
            : InputDecoration(
                label: Text(widget.label),
                border: OutlineInputBorder(),
              ),
      ),
    );
  }
}
