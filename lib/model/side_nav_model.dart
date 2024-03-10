import 'package:get/get.dart';

class SideNavController extends GetxController {
  // Declare observable state fields for MouseRegion hover states
  var mouseRegionHovered1 = false.obs;
  var mouseRegionHovered2 = false.obs;
  var mouseRegionHovered3 = false.obs;
  var mouseRegionHovered4 = false.obs;

  // Initialization
  @override
  void onInit() {}

  // Disposal
  @override
  void onClose() {}

  // Actions blocks (converted to GetX methods)
  void onMouseRegionHovered1(bool hovered) {
    mouseRegionHovered1.value = hovered;
  }

  void onMouseRegionHovered2(bool hovered) {
    mouseRegionHovered2.value = hovered;
  }

  void onMouseRegionHovered3(bool hovered) {
    mouseRegionHovered3.value = hovered;
  }

  void onMouseRegionHovered4(bool hovered) {
    mouseRegionHovered4.value = hovered;
  }

  // Additional helper methods (if any)
}
