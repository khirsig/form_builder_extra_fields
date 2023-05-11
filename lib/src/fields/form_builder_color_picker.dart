import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

extension on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  /*static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }*/

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) {
    /// Converts an rgba value (0-255) into a 2-digit Hex code.
    String hexValue(int rgbaVal) {
      assert(rgbaVal == rgbaVal & 0xFF);
      return rgbaVal.toRadixString(16).padLeft(2, '0').toUpperCase();
    }

    return '${leadingHashSign ? '#' : ''}'
        '${hexValue(alpha)}${hexValue(red)}${hexValue(green)}${hexValue(blue)}';
  }
}

enum ColorPickerType { colorPicker, materialPicker, blockPicker }

/// Creates a field for `Color` input selection
class FormBuilderColorPickerField extends FormBuilderFieldDecoration<Color> {
  //TODO: Add documentation
  final TextEditingController? controller;
  final ColorPickerType colorPickerType;
  final TextCapitalization textCapitalization;

  final TextAlign textAlign;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final bool autofocus;

  final bool obscureText;
  final bool autocorrect;
  final MaxLengthEnforcement? maxLengthEnforcement;

  final int maxLines;
  final bool expands;

  final bool showCursor;
  final int? minLines;
  final int? maxLength;
  final VoidCallback? onEditingComplete;
  final ValueChanged<Color>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final double cursorWidth;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final InputCounterWidgetBuilder? buildCounter;
  final List<Color> availableColors;

  final Widget Function(Color?)? colorPreviewBuilder;

  FormBuilderColorPickerField({
    super.key,
    required super.name,
    super.validator,
    super.initialValue,
    super.decoration,
    super.onChanged,
    super.valueTransformer,
    super.enabled,
    super.onSaved,
    super.autovalidateMode,
    super.onReset,
    super.focusNode,
    bool readOnly = false,
    this.colorPickerType = ColorPickerType.colorPicker,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.maxLengthEnforcement,
    this.maxLines = 1,
    this.expands = false,
    this.showCursor = false,
    this.minLines,
    this.maxLength,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.buildCounter,
    this.controller,
    this.colorPreviewBuilder,
    this.availableColors = const [],
  }) : super(
          builder: (FormFieldState<Color?> field) {
            final state = field as FormBuilderColorPickerFieldState;
            return TextField(
              style: style,
              decoration: state.decoration.copyWith(
                suffixIcon: colorPreviewBuilder != null
                    ? colorPreviewBuilder(field.value)
                    : LayoutBuilder(
                        key: ObjectKey(state.value),
                        builder: (context, constraints) {
                          return Icon(
                            Icons.circle,
                            key: ObjectKey(state.value),
                            size: constraints.minHeight,
                            color: state.value,
                          );
                        },
                      ),
              ),
              enabled: state.enabled,
              readOnly: readOnly,
              controller: state._effectiveController,
              focusNode: state.effectiveFocusNode,
              textAlign: textAlign,
              autofocus: autofocus,
              expands: expands,
              scrollPadding: scrollPadding,
              autocorrect: autocorrect,
              textCapitalization: textCapitalization,
              keyboardType: keyboardType,
              obscureText: obscureText,
              buildCounter: buildCounter,
              cursorColor: cursorColor,
              cursorRadius: cursorRadius,
              cursorWidth: cursorWidth,
              enableInteractiveSelection: enableInteractiveSelection,
              inputFormatters: inputFormatters,
              keyboardAppearance: keyboardAppearance,
              maxLength: maxLength,
              maxLengthEnforcement: maxLengthEnforcement,
              maxLines: maxLines,
              minLines: minLines,
              onEditingComplete: onEditingComplete,
              showCursor: showCursor,
              strutStyle: strutStyle,
              textDirection: textDirection,
              textInputAction: textInputAction,
            );
          },
        );

  @override
  FormBuilderColorPickerFieldState createState() =>
      FormBuilderColorPickerFieldState();
}

class FormBuilderColorPickerFieldState extends FormBuilderFieldDecorationState<
    FormBuilderColorPickerField, Color> {
  late TextEditingController _effectiveController;

  String? get valueString => value?.toHex();

  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _effectiveController.text = valueString ?? '';
    effectiveFocusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    effectiveFocusNode.removeListener(_handleFocus);
    // Dispose the _effectiveController when initState created it
    if (null == widget.controller) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleFocus() async {
    if (effectiveFocusNode.hasFocus && enabled) {
      effectiveFocusNode.unfocus();
      final selected = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final materialLocalizations = MaterialLocalizations.of(context);

          return AlertDialog(
            // title: null, //const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: _buildColorPicker(),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(materialLocalizations.cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(materialLocalizations.okButtonLabel),
              ),
            ],
          );
        },
      );
      if (true == selected) {
        didChange(_selectedColor);
      }
    }
  }

  Widget _buildColorPicker() {
    switch (widget.colorPickerType) {
      case ColorPickerType.colorPicker:
        return ColorPicker(
          pickerColor: value ?? Colors.transparent,
          onColorChanged: _colorChanged,
          colorPickerWidth: 300,
          displayThumbColor: true,
          enableAlpha: true,
          paletteType: PaletteType.hsl,
          pickerAreaHeightPercent: 1.0,
        );
      case ColorPickerType.materialPicker:
        return MaterialPicker(
          pickerColor: value ?? Colors.transparent,
          onColorChanged: _colorChanged,
          enableLabel: true, // only on portrait mode
        );
      case ColorPickerType.blockPicker:
        return BlockPicker(
          pickerColor: value ?? Colors.transparent,
          onColorChanged: _colorChanged,
          availableColors: widget.availableColors,
        );
      default:
        throw 'Unknown ColorPickerType';
    }
  }

  void _colorChanged(Color color) => _selectedColor = color;

  void _setTextFieldString() => _effectiveController.text = valueString ?? '';

  @override
  void didChange(Color? value) {
    super.didChange(value);
    _setTextFieldString();
  }

  @override
  void reset() {
    super.reset();
    _setTextFieldString();
  }
}
