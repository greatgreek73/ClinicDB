import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/dashboard/dashboard_controller.dart';
import '../../domain/models/patient.dart';

/// Canvas layout (Variant B) — tablet portrait approximation
class ClinicHomeV2 extends StatelessWidget {
  const ClinicHomeV2({super.key});

  static const double _leftWidthFraction = 0.35; // ~35%
  static const double _imageWidthFactor = 0.46; // controls image scale
  static const Offset _imageTranslate = Offset(0, 0); // controls image offset

  @override
  Widget build(BuildContext context) {
    // Local page-only theme: Noto Sans for the WHOLE page
    final base = Theme.of(context);
    const scale = 1.00; // set 1.10 for +10% text size across this page

    final notoSansTextTheme =
        GoogleFonts.notoSansTextTheme(base.textTheme).apply(fontSizeFactor: scale);

    final pageTheme = base.copyWith(
      textTheme: notoSansTextTheme,
      // (optional) for AppBar/primary surfaces if used in the future:
      primaryTextTheme:
          GoogleFonts.notoSansTextTheme(base.primaryTextTheme).apply(fontSizeFactor: scale),
    );

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final leftWidth = constraints.maxWidth * _leftWidthFraction;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left column ~35%
                SizedBox(
                  width: leftWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading uses page theme (Noto Sans)
                        Text(
                          'Lorem ipsum dolor sit amet.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                height: 1.1,
                                color: const Color(0xFF475569),
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Row 1 (card #1)
                        const Expanded(flex: 145, child: _WidgetBox(n: 1)),
                        const SizedBox(height: 8),
                        // Row 2 (card #2)
                        const Expanded(
                          flex: 555,
                          child: _WidgetBox(
                            n: 2,
                            child: _TodayProcedures(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Row 3 (card #3)
                        const Expanded(flex: 200, child: _WidgetBox(n: 3)),
                      ],
                    ),
                  ),
                ),

                // Right panel — gradient with feathered image (#4)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Soft light gradient background
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF8FAFC), // slate-50
                                  Color(0xFFEFF6FF), // blue-50
                                  Color(0xFFF1F5F9), // slate-100
                                ],
                              ),
                            ),
                          ),
                          // Action buttons: Add + Search
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => context.push('/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => context.push('/search'),
                                  icon: const Icon(Icons.search),
                                  label: const Text('Search'),
                                ),
                              ],
                            ),
                          ),
                          // Numeric badge intentionally removed
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WidgetBox extends StatelessWidget {
  final int n;
  final Widget? child;
  const _WidgetBox({required this.n, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1), // gray-200
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // light inner plane
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // slate-100
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (child != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          // Numeric badge removed per request
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int n;
  const _Badge({required this.n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF111827), // gray-900
      ),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FeatheredImage extends StatelessWidget {
  final String asset;
  final double stop; // where the mask starts fading
  const _FeatheredImage({required this.asset, this.stop = 0.70});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: const [
            Colors.white,
            Colors.transparent,
          ],
          stops: [stop, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
      ),
    );
  }
}

enum _ProceduresRange { today, week }

/// Today/Week procedures by type (sum of teeth) used inside box #2
class _TodayProcedures extends ConsumerStatefulWidget {
  const _TodayProcedures({super.key});

  @override
  ConsumerState<_TodayProcedures> createState() => _TodayProceduresState();
}

class _TodayProceduresState extends ConsumerState<_TodayProcedures> {
  _ProceduresRange _range = _ProceduresRange.today;

  void _toggleRange() {
    setState(() {
      _range = _range == _ProceduresRange.today
          ? _ProceduresRange.week
          : _ProceduresRange.today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardControllerProvider);
    final isWeek = _range == _ProceduresRange.week;

    final proceduresAsync = isWeek
        ? dashState.proceduresWeekByType
        : dashState.proceduresTodayByType;

    final Map<String, int> patientsByType = (isWeek
            ? dashState.patientsWeekByType
            : dashState.patientsTodayByType)
        .maybeWhen(
      data: (m) => m,
      orElse: () => const <String, int>{},
    );

    final Map<String, List<String>> patientIdsByType = (isWeek
            ? dashState.patientIdsWeekByType
            : dashState.patientIdsTodayByType)
        .maybeWhen(
      data: (m) => m,
      orElse: () => const <String, List<String>>{},
    );

    return proceduresAsync.when(
      loading: () => const Center(
        child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(
        'Loading error',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
      ),
      data: (map) {
        if (map.isEmpty) {
          return Text(
            isWeek ? 'No data for this week' : 'No data for today',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black45),
          );
        }

        // Sort by count desc, then by name asc
        final entries = map.entries.toList()
          ..sort((a, b) {
            final byVal = b.value.compareTo(a.value);
            if (byVal != 0) return byVal;
            return a.key.compareTo(b.key);
          });

        final titleStyle = Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _toggleRange,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(isWeek ? 'Week' : 'Today', style: titleStyle),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            const SizedBox(height: 8),

            // --- Timeline list ---
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final isFirst = i == 0;
                  final isLast = i == entries.length - 1;
                  final total = e.value;
                  final patientCount = patientsByType[e.key];

                  final displaySubtitle = patientCount == null
                      ? ''
                      : '$patientCount ${patientCount == 1 ? "patient" : "patients"}';

                  final patientIds = patientIdsByType[e.key] ?? const <String>[];

                  return _TimelineTile(
                    isFirst: isFirst,
                    isLast: isLast,
                    title: e.key,
                    subtitle: displaySubtitle,
                    totalChipText: '$total',
                    onTap: () => _showProcedurePatientsDialog(
                      context,
                      e.key,
                      patientIds,
                      isWeek,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            // Blue summary subwidget with total count
            Builder(
              builder: (context) {
                final total = entries.fold<int>(0, (sum, e) => sum + e.value);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB), // blue-600
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isWeek ? 'Total this week' : 'Total today',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$total',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showProcedurePatientsDialog(
    BuildContext outerContext,
    String procedureName,
    List<String> patientIds,
    bool isWeek,
  ) {
    showDialog<void>(
      context: outerContext,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final patientsState = ref.watch(
              dashboardControllerProvider.select((s) => s.patients),
            );

            Widget content;
            if (patientIds.isEmpty) {
              content = const Text('No patients recorded for this procedure.');
            } else {
              content = patientsState.when(
                loading: () => const SizedBox(
                  height: 80,
                  width: 80,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text('Unable to load patient details.'),
                data: (patientList) {
                  final lookup = {
                    for (final patient in patientList) patient.id: patient,
                  };
                  final resolvedPatients = <Patient>[];
                  final missingIds = <String>[];

                  for (final id in patientIds) {
                    final patient = lookup[id];
                    if (patient != null) {
                      resolvedPatients.add(patient);
                    } else {
                      missingIds.add(id);
                    }
                  }

                  resolvedPatients.sort(
                    (a, b) => (a.name ?? a.id).compareTo(b.name ?? b.id),
                  );

                  if (resolvedPatients.isEmpty && missingIds.isEmpty) {
                    return const Text('No patients recorded for this procedure.');
                  }

                  final tiles = <Widget>[];
                  for (final patient in resolvedPatients) {
                    final displayName =
                        (patient.name != null && patient.name!.isNotEmpty) ? patient.name! : 'Patient ${patient.id}';
                    tiles.add(
                      ListTile(
                        title: Text(displayName),
                        subtitle: Text('ID: ${patient.id}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          outerContext.push('/patient/${patient.id}');
                        },
                      ),
                    );
                  }
                  for (final id in missingIds) {
                    tiles.add(
                      ListTile(
                        title: Text('Unknown patient ($id)'),
                        enabled: false,
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360, maxHeight: 320),
                    child: ListView(
                      shrinkWrap: true,
                      children: tiles,
                    ),
                  );
                },
              );
            }

            return AlertDialog(
              title: Text('$procedureName • ${isWeek ? 'This week' : 'Today'}'),
              content: SizedBox(width: 360, child: content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Timeline list tile: dot marker + content
class _TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final String title;
  final String subtitle;
  final String totalChipText;
  final VoidCallback? onTap;

  const _TimelineTile({
    required this.isFirst,
    required this.isLast,
    required this.title,
    required this.subtitle,
    required this.totalChipText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: IntrinsicHeight( // ensures the rail stretches to content height
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left rail now only keeps centered dot marker
                SizedBox(
                  width: 26, // gutter width for the marker
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB), // blue-600 to match summary chip
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Content block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + chip with total
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(totalChipText, style: theme.textTheme.titleMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Thin subtitle
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54, height: 1.2),
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
