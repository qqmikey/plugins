import 'dart:async';

import 'package:flutter/material.dart';

import '../camera.dart';

class ZoomableFocusPoint extends StatefulWidget {
  final Widget child;
  final bool focusOnPointDisabled;
  final bool showZoomControl;
  final CameraController cameraController;
  final Color focusColor;
  final double? gestureAreaHeight;

  const ZoomableFocusPoint({
    Key? key,
    required this.child,
    this.focusOnPointDisabled = false,
    this.showZoomControl = false,
    required this.cameraController,
    this.focusColor = Colors.black,
    this.gestureAreaHeight,
  }) : super(key: key);

  @override
  _ZoomableFocusPointState createState() => _ZoomableFocusPointState();
}

class _ZoomableFocusPointState extends State<ZoomableFocusPoint> with TickerProviderStateMixin {
  Matrix4 matrix = Matrix4.identity();
  double zoom = 1;
  double prevZoom = 1;
  bool showZoom = false;
  Timer? t1;
  Timer? t2;

  Offset? focusPoint;
  late AnimationController controller;
  late Animation animation;

  double maxZoomLevel = 11.0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() {
        setState(() {});
      });

    widget.cameraController.getMaxZoomLevel().then((maxZoom) {
      setState(() {
        maxZoomLevel = maxZoom;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    t1?.cancel();
    t2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultHeight = MediaQuery.of(context).size;
    return Stack(
      children: [
        widget.child,
        if (widget.showZoomControl)
          Visibility(
            visible: showZoom,
            child: Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        inactiveTrackColor: const Color(0xFF8D8E98),
                        activeTrackColor: Colors.white,
                        thumbColor: Colors.black,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                      ),
                      child: Slider(
                        value: zoom,
                        onChanged: _handleZoom,
                        label: "$zoom",
                        min: 1,
                        max: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //maintainSize: bool. When true this is equivalent to invisible;
            //replacement: Widget. Defaults to Sizedbox.shrink, 0x0
          ),
        GestureDetector(
          onScaleStart: (scaleDetails) {
            setState(() => prevZoom = zoom);
          },
          onScaleUpdate: (ScaleUpdateDetails scaleDetails) {
            var newZoom = (prevZoom * scaleDetails.scale);
            _handleZoom(newZoom);
          },
          onTapUp: handleFocusOnPoint,
          child: Container(
            height: widget.gestureAreaHeight ?? defaultHeight.width * 16 / 9,
            color: Colors.transparent,
          ),
        ),
        if (focusPoint != null)
          Positioned(
            top: focusPoint!.dy - 40,
            left: focusPoint!.dx - 40,
            child: Opacity(
              opacity: animation.value,
              child: Transform.scale(
                scale: (1 - animation.value / 3.5) + 0.25,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(border: Border.all(color: widget.focusColor, width: 1)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _handleZoom(newZoom) {
    if (newZoom >= 1) {
      if (newZoom > 10) {
        return false;
      }
      setState(() {
        showZoom = true;
        zoom = newZoom;
      });

      t1?.cancel();
      t1 = Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          showZoom = false;
        });
      });
    }
    if (zoom < maxZoomLevel) {
      widget.cameraController.setZoomLevel(zoom);
    }
    return true;
  }

  handleFocusOnPoint(TapUpDetails det) async {
    if (widget.focusOnPointDisabled) return;
    if (t2 != null) {
      controller.value = 0.0;
      t2!.cancel();
    }
    final RenderObject? box = context.findRenderObject();
    final Offset localPoint = (box as RenderBox).globalToLocal(det.globalPosition);
    final Offset scaledPoint = localPoint.scale(1 / box.size.width, 1 / box.size.height);

    setState(() {
      focusPoint = det.globalPosition;
      controller.forward();
    });

    await widget.cameraController.setFocusMode(FocusMode.locked);
    await widget.cameraController.setFocusPoint(Offset(scaledPoint.dx, scaledPoint.dy));

    t2 = Timer(const Duration(milliseconds: 2000), () async {
      controller.reverse();
      setState(() {
        focusPoint = null;
      });
      await widget.cameraController.setFocusPoint(null);
      await widget.cameraController.setFocusMode(FocusMode.auto);
    });
  }
}
