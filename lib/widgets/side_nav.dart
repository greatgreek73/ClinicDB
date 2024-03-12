import 'package:cached_network_image/cached_network_image.dart';
import 'package:clinicdb/configs/constants.dart';
import 'package:clinicdb/model/side_nav_model.dart';
import 'package:clinicdb/theme/dark_theme.dart';
import 'package:clinicdb/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SideNavWidget extends StatefulWidget {
  const SideNavWidget({
    super.key,
    int? selectedNav,
  }) : selectedNav = selectedNav ?? 1;

  final int selectedNav;

  @override
  State<SideNavWidget> createState() => _SideNavWidgetState();
}

class _SideNavWidgetState extends State<SideNavWidget> {
  late SideNavController _model;

  @override
  void initState() {
    super.initState();
    _model = SideNavController();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: MediaQuery.of(context).size.width >
          600, // Adjust width threshold as needed
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: 270,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            boxShadow: const [
              BoxShadow(
                blurRadius: 3,
                color: Color(0x33000000),
                offset: Offset(0, 1),
              )
            ],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
                        child: Icon(
                          Icons.flourescent_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 36,
                        ),
                      ),
                      Text(
                        'flow.io',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 36),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 12,
                  thickness: 2,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 12, 16, 0),
                          child: Text(
                            'Platform Navigation',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        MouseRegion(
                          opaque: false,
                          cursor: MouseCursor.defer ?? MouseCursor.defer,
                          onEnter: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered1.value = true);
                          }),
                          onExit: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered1.value = false);
                          }),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16, 12, 16, 12),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.of(context).pushNamed(
                                  'webFlow_01',
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                width: double.infinity,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: () {
                                    if (_model.mouseRegionHovered1.value) {
                                      return Colors.grey.shade300;
                                    } else if (widget.selectedNav == 1) {
                                      return AppColors.kPrimaryColor;
                                    } else {
                                      return Colors.grey;
                                    }
                                  }(),
                                  borderRadius: BorderRadius.circular(12),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      8, 0, 6, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        Icons.space_dashboard,
                                        color: widget.selectedNav == 1
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).cardColor,
                                        size: 24,
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(12, 0, 0, 0),
                                        child: Text(
                                          'Page One',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        MouseRegion(
                          opaque: false,
                          cursor: MouseCursor.defer ?? MouseCursor.defer,
                          onEnter: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered2.value = true);
                          }),
                          onExit: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered2.value = false);
                          }),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16, 12, 12, 16),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.of(context).pushNamed(
                                  'webFlow_02',
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                width: double.infinity,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: () {
                                    if (_model.mouseRegionHovered2.value) {
                                      return Colors.grey.shade300;
                                    } else if (widget.selectedNav == 1) {
                                      return AppColors.kPrimaryColor;
                                    } else {
                                      return Colors.grey;
                                    }
                                  }(),
                                  borderRadius: BorderRadius.circular(12),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      8, 0, 6, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        Icons.forum_rounded,
                                        color: widget.selectedNav == 2
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).primaryColor,
                                        size: 24,
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(12, 0, 0, 0),
                                        child: Text(
                                          'Page Two',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        MouseRegion(
                          opaque: false,
                          cursor: MouseCursor.defer ?? MouseCursor.defer,
                          onEnter: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered3.value = true);
                          }),
                          onExit: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered3.value = false);
                          }),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16, 12, 16, 12),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.of(context).pushNamed(
                                  'webFlow_03',
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                width: double.infinity,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: () {
                                    if (_model.mouseRegionHovered3.value) {
                                      return Colors.grey.shade300;
                                    } else if (widget.selectedNav == 1) {
                                      return AppColors.kPrimaryColor;
                                    } else {
                                      return Colors.grey;
                                    }
                                  }(),
                                  borderRadius: BorderRadius.circular(12),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      8, 0, 6, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        Icons.work,
                                        color: widget.selectedNav == 3
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).primaryColor,
                                        size: 24,
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(12, 0, 0, 0),
                                        child: Text(
                                          'Page Three',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 12, 16, 12),
                          child: Text(
                            'Settings',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        MouseRegion(
                          opaque: false,
                          cursor: MouseCursor.defer ?? MouseCursor.defer,
                          onEnter: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered4.value = true);
                          }),
                          onExit: ((event) async {
                            setState(
                                () => _model.mouseRegionHovered4.value = false);
                          }),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16, 0, 16, 0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.of(context).pushNamed(
                                  'webFlow_04',
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                width: double.infinity,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: () {
                                    if (_model.mouseRegionHovered4.value) {
                                      return Colors.grey.shade300;
                                    } else if (widget.selectedNav == 1) {
                                      return Colors.deepPurple.shade100;
                                    } else {
                                      return Colors.grey;
                                    }
                                  }(),
                                  borderRadius: BorderRadius.circular(12),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      8, 0, 6, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        Icons.notifications_rounded,
                                        color: widget.selectedNav == 4
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).primaryColor,
                                        size: 24,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12, 0, 0, 0),
                                          child: Text(
                                            'Page Four',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Align(
                                          alignment:
                                              const AlignmentDirectional(0, 0),
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(8, 4, 8, 4),
                                            child: Text(
                                              '12',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontFamily: 'Readex Pro',
                                                    color:
                                                        AppColors.kPrimaryColor,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer()
                      ]),
                ),
                Align(
                  alignment: const AlignmentDirectional(0, -1),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 16),
                    child: Container(
                      width: 250,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.kBorderColor.shade300,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (Get.isDarkMode) {
                                    Get.changeTheme(LightTheme.theme);
                                    Get.changeThemeMode(ThemeMode.light);
                                    Get.reloadAll();
                                  }
                                },
                                child: Container(
                                  width: 115,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Theme.of(context).cardColor
                                        : Theme.of(context)
                                            .scaffoldBackgroundColor, // Use primaryColorDark for dark theme
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey.shade300
                                          : Theme.of(context)
                                              .canvasColor, // Use canvasColor for light border in dark theme

                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.wb_sunny_rounded,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).indicatorColor,
                                        size: 16,
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(4, 0, 0, 0),
                                        child: Text(
                                          'Light Mode',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontFamily: 'Readex Pro',
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.light
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : Theme.of(context)
                                                        .indicatorColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (!Get.isDarkMode) {
                                    Get.changeTheme(DarkTheme.theme);
                                    Get.changeThemeMode(ThemeMode.dark);
                                    Get.reloadAll();
                                  }
                                },
                                child: Container(
                                  width: 115,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context).hoverColor
                                        : Theme.of(context)
                                            .canvasColor, // Use primaryColorDark for dark theme
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey.shade300
                                          : Theme.of(context)
                                              .scaffoldBackgroundColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.nightlight_round,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context).indicatorColor
                                            : Theme.of(context).primaryColor,
                                        size: 16,
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(4, 0, 0, 0),
                                        child: Text(
                                          'Dark Mode',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontFamily: 'Readex Pro',
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Theme.of(context)
                                                        .indicatorColor
                                                    : Theme.of(context)
                                                        .primaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 12,
                  thickness: 2,
                  color: AppColors.kBorderColor.shade300,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.kBorderColor.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 500),
                              fadeOutDuration:
                                  const Duration(milliseconds: 500),
                              imageUrl:
                                  'https://images.unsplash.com/photo-1624561172888-ac93c696e10c?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NjJ8fHVzZXJzfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=900&q=60',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Andrew D.',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 4, 0, 0),
                                child: Text(
                                  'admin@gmail.com',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
