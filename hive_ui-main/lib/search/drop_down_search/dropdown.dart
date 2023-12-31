// ignore_for_file: empty_catches

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef DropDownFind = Future<List<String>> Function(String str);

class DropdownEditingController<T> extends ChangeNotifier {
  T? _value;

  DropdownEditingController({T? value}) : _value = value;

  T? get value => _value;

  set value(T? newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

/// Create a dropdown form field
class DropdownFormField<T> extends StatefulWidget {
  final bool autoFocus;

  /// It will trigger on user search
  final bool Function(String item, String str)? filterFn;

  /// Check item is selectd
  final bool Function(String? item1, String? item2)? selectedFn;

  /// Return list of items what need to list for dropdown.
  /// The list may be offline, or remote data from server.
  final DropDownFind findFn;

  /// Build dropdown Items, it get called for all dropdown items
  ///  [item] = [dynamic value] List item to build dropdown Listtile
  /// [lasSelectedItem] = [null | dynamic value] last selected item, it gives user chance to highlight selected item
  /// [position] = [0,1,2...] Index of the list item
  /// [focused] = [true | false] is the item if focused, it gives user chance to highlight focused item
  /// [onTap] = [Function] *important! just assign this function to Listtile.onTap  = onTap, incase you missed this,
  /// the click event if the dropdown item will not work.
  ///
  final ListTile Function(
    String item,
    int position,
    bool focused,
    bool selected,
    Function() onTap,
  ) dropdownItemFn;

  /// Build widget to display selected item inside Form Field
  final Widget Function(String? item) displayItemFn;

  final InputDecoration? decoration;
  final Color? dropdownColor;
  final DropdownEditingController<String>? controller;
  final void Function(String item)? onChanged;
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;

  /// height of the dropdown overlay, Default: 240
  final double? dropdownHeight;

  /// Style the search box text
  final TextStyle? searchTextStyle;

  /// Message to disloay if the search dows not match with any item, Default : "No matching found!"
  final String emptyText;

  /// Give action text if you want handle the empty search.
  final String emptyActionText;

  /// this functon triggers on click of emptyAction button
  final Future<void> Function()? onEmptyActionPressed;

  final FocusNode? focusNode;

  final bool isProduct;

  const DropdownFormField({
    Key? key,
    required this.dropdownItemFn,
    required this.displayItemFn,
    required this.findFn,
    this.focusNode,
    this.filterFn,
    this.autoFocus = false,
    this.isProduct = false,
    this.controller,
    this.validator,
    this.decoration,
    this.dropdownColor,
    this.onChanged,
    this.onSaved,
    this.dropdownHeight,
    this.searchTextStyle,
    this.emptyText = "No matching found!",
    this.emptyActionText = 'Create new',
    this.onEmptyActionPressed,
    this.selectedFn,
  }) : super(key: key);

  @override
  DropdownFormFieldState createState() => DropdownFormFieldState<String>();
}

class DropdownFormFieldState<T> extends State<DropdownFormField>
    with SingleTickerProviderStateMixin {
  final FocusNode _widgetFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ValueNotifier<List<String>> _listItemsValueNotifier =
      ValueNotifier<List<String>>([]);
  final TextEditingController _searchTextController = TextEditingController();
  late ScrollController _scrollController;
  final DropdownEditingController<String> _controller =
      DropdownEditingController<String>();

  int scrollViewPort = 1;

  bool _selectedFn(dynamic item1, dynamic item2) => item1 == item2;

  bool get _isEmpty => _selectedItem == null;
  bool _isFocused = false;

  OverlayEntry? _overlayEntry;
  OverlayEntry? _overlayBackdropEntry;
  List<String>? _options;
  int _listItemFocusedPosition = 0;
  String? _selectedItem;
  Widget? _displayItem;
  Timer? _debounce;
  String? _lastSearchString;

  DropdownEditingController<String>? get _effectiveController =>
      widget.controller ?? _controller;

  DropdownFormFieldState() : super();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    if (_effectiveController!.value != null) {
      _selectedItem = _effectiveController!.value;
    }

    if (widget.autoFocus) {
      widget.focusNode != null
          ? widget.focusNode!.requestFocus()
          : _widgetFocusNode.requestFocus();
    }

    _effectiveController!.addListener(() {
      if (_effectiveController!.value!.isEmpty) {
        setState(() {
          _selectedItem = null;
        });
      }
    });
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _overlayEntry != null) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    try {
      _searchTextController.dispose();
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _displayItem = widget.displayItemFn(_selectedItem);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (widget.focusNode != null) {
            widget.focusNode!.requestFocus();
          } else {
            _widgetFocusNode.requestFocus();
          }
          _toggleOverlay();
        },
        child: Focus(
          autofocus: widget.autoFocus,
          focusNode: widget.focusNode ?? _widgetFocusNode,
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          onKey: (focusNode, event) {
            return _onKeyPressed(event);
          },
          child: FormField(
            validator: (str) {
              if (widget.validator != null) {
                return widget.validator!(_effectiveController!.value);
              }
              return null;
            },
            onSaved: (str) {
              if (widget.onSaved != null) {
                widget.onSaved!(_effectiveController!.value);
              }
            },
            builder: (state) {
              return InputDecorator(
                decoration: widget.decoration ??
                    const InputDecoration(
                      border: UnderlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                isEmpty: _isEmpty,
                isFocused: _isFocused,
                child: _overlayEntry != null
                    ? EditableText(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        controller: _searchTextController,
                        cursorColor: Colors.black87,
                        focusNode: _searchFocusNode,
                        backgroundCursorColor: Colors.transparent,
                        onChanged: (str) {
                          if (_overlayEntry == null) {
                            _addOverlay();
                          }
                          _onTextChanged(str);
                        },
                        onSubmitted: (str) {
                          _searchTextController.value =
                              const TextEditingValue(text: "");
                          _setValue();
                          _removeOverlay();
                          // _widgetFocusNode.nextFocus();
                        },
                        onEditingComplete: () {},
                      )
                    : _displayItem ?? Container(),
              );
            },
          ),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    final renderObject = context.findRenderObject() as RenderBox;
    final Size size = renderObject.size;
    var overlay = OverlayEntry(builder: (context) {
      return Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 3.0),
          child: Material(
              elevation: 4.0,
              child: SizedBox(
                height: widget.dropdownHeight ?? 240,
                child: Container(
                  color: widget.dropdownColor ?? Colors.white70,
                  child: ValueListenableBuilder(
                      valueListenable: _listItemsValueNotifier,
                      builder: (context, List<String> items, child) {
                        return _options != null && _options!.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                controller: _scrollController,
                                itemCount: items.length,
                                itemBuilder: (context, position) {
                                  final item = items[position];
                                  void onTap() {
                                    _listItemFocusedPosition = position;
                                    _searchTextController.value =
                                        const TextEditingValue(text: "");
                                    _removeOverlay();
                                    _setValue();
                                    _searchFocusNode.unfocus();
                                  }

                                  ListTile listTile = widget.dropdownItemFn(
                                    item,
                                    position,
                                    position == _listItemFocusedPosition,
                                    (widget.selectedFn ?? _selectedFn)(
                                        _selectedItem, item),
                                    onTap,
                                  );

                                  return SizedBox(height: 65, child: listTile);
                                })
                            : Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.emptyText,
                                      style: const TextStyle(
                                          color: Colors.black45),
                                    ),
                                    if (widget.onEmptyActionPressed != null)
                                      TextButton(
                                        onPressed: () async {
                                          await widget.onEmptyActionPressed!();
                                          _search(
                                              _searchTextController.value.text);
                                        },
                                        child: Text(widget.emptyActionText),
                                      ),
                                  ],
                                ),
                              );
                      }),
                ),
              )),
        ),
      );
    });

    return overlay;
  }

  OverlayEntry _createBackdropOverlay() {
    return OverlayEntry(
        builder: (context) => Positioned(
            left: 0,
            top: 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
              },
            )));
  }

  _addOverlay() {
    if (_overlayEntry == null) {
      _search("");
      _overlayBackdropEntry = _createBackdropOverlay();
      _overlayEntry = _createOverlayEntry();
      if (_overlayEntry != null) {
        // Overlay.of(context)!.insert(_overlayEntry!);
        if (_overlayBackdropEntry != null) {
          Overlay.of(context).insertAll([_overlayBackdropEntry!, _overlayEntry!]);
        }
        setState(() {
          _searchFocusNode.requestFocus();
        });
      }
    }
  }

  /// Dettach overlay from the dropdown widget
  _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayBackdropEntry!.remove();
      _overlayEntry!.remove();
      _overlayEntry = null;
      _searchTextController.value = TextEditingValue.empty;
      setState(() {});
    }
  }

  _toggleOverlay() {
    if (_overlayEntry == null) {
      _addOverlay();
    } else {
      _removeOverlay();
    }
  }

  _onTextChanged(String? str) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_lastSearchString != str) {
        _lastSearchString = str;
        _search(str ?? "");
      }
    });
  }

  KeyEventResult _onKeyPressed(RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      if (_searchFocusNode.hasFocus) {
        _toggleOverlay();
      } else {
        _toggleOverlay();
      }
      _setValue();
      return KeyEventResult.handled;
    } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
      _removeOverlay();
      return KeyEventResult.handled;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      int v = _listItemFocusedPosition;
      v++;

      if (v >= _options!.length) v = 0;
      _listItemFocusedPosition = v;
      _listItemsValueNotifier.value = List<String>.from(_options ?? []);

      return KeyEventResult.handled;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      int v = _listItemFocusedPosition;
      v--;
      if (v < 0) v = _options!.length - 1;
      _listItemFocusedPosition = v;
      _listItemsValueNotifier.value = List<String>.from(_options ?? []);

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  _search(String str) async {
    List<String> items = await widget.findFn(str);
    if (str.isNotEmpty && widget.filterFn != null) {
      items = items.where((item) => widget.filterFn!(item, str)).toList();
    }
    _options = items;
    _listItemsValueNotifier.value = items;
  }

  _setValue() {
    var item = _options![_listItemFocusedPosition];
    _selectedItem = item;

    _effectiveController!.value = _selectedItem;

    if (widget.onChanged != null) {
      widget.onChanged!(_selectedItem!);
    }

    setState(() {});
  }
}
