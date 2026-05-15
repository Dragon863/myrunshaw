// Originally from https://pub.dev/packages/zoomable_interactive_viewer
// Many thanks to Ali Hussnain :)

import 'package:flutter/material.dart';

/// A customizable widget that provides interactive zoom and pan functionality
/// with options to animate scaling and zoom buttons.
class ZoomableInteractiveViewer extends StatefulWidget {
  /// The widget to be displayed and zoomed within the viewer.
  final Widget child;

  /// Enable or disable animation for double-tap zooming.
  final bool enableAnimation;

  /// Curve for the zoom-in and zoom-out animations.
  final Curve animationCurve;

  /// Defines the margins beyond which the child cannot be moved.
  final EdgeInsets boundaryMargin;

  /// Scale for Double Tap Zoom, Default is 2.0
  final double doubleTapZoomScale;

  /// Minimum scale for zooming out.
  final double minScale;

  /// Maximum scale for zooming in.
  final double maxScale;

  /// Step scale value for the zoom-in magnifier.
  final double zoomInMagnifierScale;

  /// Step scale value for the zoom-out magnifier.
  final double zoomOutMagnifierScale;

  /// Enable or disable panning. It is automatically disabled when fully zoomed out.
  final bool panEnabled;

  /// Enable or disable scaling. Default is `true`.
  final bool scaleEnabled;

  /// Constrain the child within its parent's size boundaries.
  final bool constrained;

  /// Color for the zoom-in magnifier button.
  final Color zoomInMagnifierColor;

  /// Color for the zoom-out magnifier button.
  final Color zoomOutMagnifierColor;

  /// Display zoom-in and zoom-out buttons in the widget.
  final bool enableZoomInMagnifier;

  /// Creates a ZoomableInteractiveViewer with interactive zoom and pan options.
  const ZoomableInteractiveViewer({
    super.key,
    required this.child,
    this.enableAnimation = true,
    this.animationCurve = Curves.easeInOut,
    this.boundaryMargin = const EdgeInsets.all(20),
    this.minScale = 1.0,
    this.maxScale = 4.0,
    this.zoomInMagnifierScale = 1.0,
    this.zoomOutMagnifierScale = 1.0,
    this.doubleTapZoomScale = 2.0,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.constrained = true,
    this.zoomInMagnifierColor = Colors.white,
    this.zoomOutMagnifierColor = Colors.white,
    this.enableZoomInMagnifier = false,
  })  : assert(minScale <= maxScale,
            'minScale must be less than or equal to maxScale'),
        assert(doubleTapZoomScale <= maxScale,
            'doubleTapZoomScale must be less than maxScale range'),
        assert(zoomInMagnifierScale > 0,
            'zoomInMagnifierScale must be greater than zero'),
        assert(zoomOutMagnifierScale > 0,
            'zoomOutMagnifierScale must be greater than zero'),
        assert(
            !enableZoomInMagnifier ||
                (zoomInMagnifierScale != 0 && zoomOutMagnifierScale != 0),
            'Zoom magnifier scale values must be non-zero if magnifier buttons are enabled');

  @override
  State<ZoomableInteractiveViewer> createState() =>
      ZoomableInteractiveViewerState();
}

class ZoomableInteractiveViewerState extends State<ZoomableInteractiveViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late ValueNotifier<bool> _isZoomed;
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  final GlobalKey _widgetKey = GlobalKey();

  // Getters for accessing private members in tests
  TransformationController get transformationController =>
      _transformationController;
  ValueNotifier<bool> get isZoomed => _isZoomed;
  TapDownDetails? get doubleTapDetails => _doubleTapDetails;
  AnimationController get animationController => _animationController;
  Animation<Matrix4>? get animation => _animation;
  bool handlePanStatus(bool isZoomed) => _handlePanStatus(isZoomed);

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _isZoomed = ValueNotifier<bool>(false);
    // Track the transformation controller scale to detect zoom state
    _transformationController.addListener(() {
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      if (currentScale < widget.minScale) {
        _transformationController.value = Matrix4.identity()
          ..scale(widget.minScale);
      } else if (currentScale > widget.maxScale) {
        _transformationController.value = Matrix4.identity()
          ..scale(widget.maxScale);
      }
      if (currentScale > widget.minScale && !_isZoomed.value) {
        _isZoomed.value = true; // Set zoomed state to true
      } else if (currentScale <= widget.minScale && _isZoomed.value) {
        _isZoomed.value = false; // Set zoomed state to false
      }
    });

    // Initialize the animation controller with a fixed duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        // Update transformation on animation tick
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    _isZoomed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isZoomed,
      builder: (context, isZoomed, child) {
        return Stack(
          children: [
            // GestureDetector for handling double-tap zoom actions
            GestureDetector(
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: SizedBox(
                key: _widgetKey,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: widget.boundaryMargin,
                  minScale: widget.minScale,
                  maxScale: widget.maxScale,
                  panEnabled: _handlePanStatus(isZoomed),
                  scaleEnabled: widget.scaleEnabled,
                  constrained: widget.constrained,
                  child: widget.child,
                ),
              ),
            ),
            // Zoom in and out buttons if enabled
            if (widget.enableZoomInMagnifier)
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _handleButtonZoomIn,
                      icon: Icon(
                        Icons.zoom_in,
                        color: widget.zoomInMagnifierColor,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _handleButtonZoomOut,
                      icon: Icon(
                        Icons.zoom_out,
                        color: widget.zoomOutMagnifierColor,
                      ),
                    ),
                  ],
                ),
              )
          ],
        );
      },
    );
  }

  /// Handles double-tap zooming functionality, zooming in and out based on current scale.
  void _handleDoubleTap() {
    final Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();
    final position = _doubleTapDetails!.localPosition;

    Matrix4 endMatrix;

    if (currentScale == widget.minScale) {
      // Adjust the translation factor based on doubleTapZoomScale to prevent zooming outside the screen
      double translationFactor = widget.doubleTapZoomScale < 2.0
          ? widget.doubleTapZoomScale -
              1.0 // Scale down translation if zoom level is low
          : 2.0; // Default factor for higher zoom levels

      // Zoom in with a double tap
      endMatrix = Matrix4.identity()
        ..translate(
            -position.dx * translationFactor, -position.dy * translationFactor)
        ..scale(widget.doubleTapZoomScale);
    } else {
      // Reset zoom to original scale
      endMatrix = Matrix4.identity();
    }

    if (widget.enableAnimation) {
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: endMatrix,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));
      _animationController.forward(from: 0);
    } else {
      _transformationController.value = endMatrix;
    }
  }

  /// Handles the zoom-in button logic, zooming in at the widget's center.
  void _handleButtonZoomIn() {
    final Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();

    final RenderBox renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset widgetCenter =
        renderBox.localToGlobal(size.center(Offset.zero));

    if (currentScale + widget.zoomInMagnifierScale > widget.maxScale) {
      currentScale = widget.maxScale;
    } else {
      currentScale += widget.zoomInMagnifierScale;
    }

    Matrix4 endMatrix = Matrix4.identity()
      ..translate(-widgetCenter.dx * (currentScale - 1),
          -widgetCenter.dy * (currentScale - 1))
      ..scale(currentScale);

    if (widget.enableAnimation) {
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: endMatrix,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));
      _animationController.forward(from: 0);
    } else {
      _transformationController.value = endMatrix;
    }
  }

  /// Handles the zoom-out button logic, zooming out from the widget's center.
  void _handleButtonZoomOut() {
    final Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();

    final RenderBox renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset widgetCenter =
        renderBox.localToGlobal(size.center(Offset.zero));

    if (currentScale - widget.zoomOutMagnifierScale < widget.minScale) {
      currentScale = widget.minScale;
    } else {
      currentScale -= widget.zoomOutMagnifierScale;
    }

    Matrix4 endMatrix = Matrix4.identity()
      ..translate(-widgetCenter.dx * (currentScale - 1),
          -widgetCenter.dy * (currentScale - 1))
      ..scale(currentScale);

    if (widget.enableAnimation) {
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: endMatrix,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));
      _animationController.forward(from: 0);
    } else {
      _transformationController.value = endMatrix;
    }
  }

  /// Handles pan behavior based on current zoom state.
  bool _handlePanStatus(bool isZoomed) {
    if (!widget.panEnabled) {
      return false;
    }
    return isZoomed;
  }
}
