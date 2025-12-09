import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmpTotalVM {
  final String? employeeId;
  final String displayName;
  final Duration duration;
  EmpTotalVM({
    required this.employeeId,
    required this.displayName,
    required this.duration,
  });
}

class OrgWorkingTimeCard extends StatefulWidget {
  final String orgLabel;
  final String dateLabel;
  final bool loading;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> rows;
  final List<dynamic> totals;
  final VoidCallback? onPickOrg;
  final VoidCallback? onClearOrRefresh;
  final void Function(String? employeeId)? onEmployeeTap;

  const OrgWorkingTimeCard({
    super.key,
    required this.orgLabel,
    required this.dateLabel,
    required this.loading,
    required this.rows,
    required this.totals,
    this.onPickOrg,
    this.onClearOrRefresh,
    this.onEmployeeTap,
  });

  @override
  State<OrgWorkingTimeCard> createState() => _OrgWorkingTimeCardState();
}

class _OrgWorkingTimeCardState extends State<OrgWorkingTimeCard>
    with TickerProviderStateMixin {
  bool _showBreakdown = true;

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header Section with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  // Organization selector button
                  Material(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: widget.onPickOrg,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.apartment_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Organization info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ORGANIZATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.orgLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.dateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action button
                  Material(
                    color: widget.orgLabel == 'All'
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: widget.onClearOrRefresh,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          widget.orgLabel == 'All'
                              ? Icons.refresh
                              : Icons.close,
                          color: widget.orgLabel == 'All'
                              ? Colors.blue
                              : Colors.red,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          Builder(
            builder: (context) {
              if (widget.loading && widget.rows.isEmpty) {
                return Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading work time...',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (widget.totals.isEmpty) {
                return Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_off_outlined,
                        size: 32,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No work time recorded',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'for this day',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  if (widget.totals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Employee Breakdown',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: _showBreakdown
                                ? 'Collapse breakdown'
                                : 'Expand breakdown',
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: AnimatedRotation(
                                duration: const Duration(milliseconds: 200),
                                turns: _showBreakdown
                                    ? 0.0
                                    : 0.5, // chevron flips
                                child: Icon(
                                  _showBreakdown
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onPressed: () {
                                setState(
                                  () => _showBreakdown = !_showBreakdown,
                                );
                              },
                              tooltip: _showBreakdown ? 'Hide' : 'Show',
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Employees list (collapsible)
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _showBreakdown
                          ? Column(
                              children: [
                                ...widget.totals.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final t = entry.value as dynamic;
                                  final isLast =
                                      index == widget.totals.length - 1;

                                  return Container(
                                    margin: EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      isLast ? 12 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(
                                          0.1,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => widget.onEmployeeTap?.call(
                                          t.employeeId as String?,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Employee avatar
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    (t.displayName as String)
                                                            .isNotEmpty
                                                        ? (t.displayName
                                                                  as String)[0]
                                                              .toUpperCase()
                                                        : '?',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),

                                              // Employee info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      t.displayName,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    if (t.employeeId != null)
                                                      Text(
                                                        t.employeeId as String,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              // Duration
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _fmtDur(
                                                    t.duration as Duration,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
