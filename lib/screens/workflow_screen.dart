// ─────────────────────────────────────────────────────────
//  WRAPD — WORKFLOW AUTOMATION SCREENS
//  "Final Stop" workflow management - Feb 26 2026
//  Added by: AI Analysis for holding company valuation
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workflow_provider.dart';
import '../providers/session_provider.dart';
import '../models/workflow_model.dart';
import '../models/session_model.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';

/// Main workflow screen showing all pending automation actions
class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workflowProvider = context.watch<WorkflowProvider>();
    final sessionProvider = context.watch<SessionProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with statistics
        SliverAppBar(
          floating: true,
          backgroundColor: isDark ? WrapdColors.darkCanvas : WrapdColors.lightCanvas,
          surfaceTintColor: Colors.transparent,
          title: Text('Final Stop',
              style: theme.textTheme.headlineMedium),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_outlined),
              onPressed: () => _createNewWorkflow(context),
            ),
          ],
        ),

        // Workflow statistics
        SliverToBoxAdapter(
          child: workflowProvider.packages.isEmpty && sessionProvider.isLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: WrapdColors.cobalt),
                ))
              : Padding(
                  padding: const EdgeInsets.all(WrapdColors.p16),
                  child: _WorkflowStatsCard(
                    stats: workflowProvider.stats,
                    isDark: isDark,
                  ),
                ),
        ),

        // Today's workflows
        if (workflowProvider.getTodaysCompletedWorkflows().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WrapdColors.p16),
              child: _SectionHeader(
                label: 'COMPLETED TODAY',
                isDark: isDark,
              ),
            ),
          ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final todayCompleted = workflowProvider.getTodaysCompletedWorkflows()[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WrapdColors.p16, vertical: WrapdColors.p8),
                child: _WorkflowPackageCard(
                  package: todayCompleted,
                  isCompleted: true,
                  onTap: () => _openWorkflowDetails(context, todayCompleted),
                ),
              );
            },
            childCount: workflowProvider.getTodaysCompletedWorkflows().length,
          ),
        ),

        // Pending workflows for active sessions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(WrapdColors.p16),
            child: _SectionHeader(
              label: 'PENDING ACTIONS',
              isDark: isDark,
            ),
          ),
        ),

        if (sessionProvider.readySessions.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined,
                      size: 48,
                      color: isDark
                          ? WrapdColors.darkMuted
                          : WrapdColors.lightMuted),
                  const SizedBox(height: WrapdColors.p16),
                  Text(
                    'No workflows yet.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: WrapdColors.p8),
                  Text(
                    'Record a meeting to see automation suggestions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? WrapdColors.darkMuted
                            : WrapdColors.lightMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = sessionProvider.readySessions[index];
                final workflows = workflowProvider.getPendingWorkflows(session.id);
                
                if (workflows.isEmpty) {
                  // Show option to create workflow
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: WrapdColors.p16, vertical: WrapdColors.p8),
                    child: _CreateWorkflowCard(
                      session: session,
                      onCreate: () => _createWorkflowForSession(context, session.id),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(WrapdColors.p16, 0, WrapdColors.p16, WrapdColors.p8),
                  child: Column(
                    children: workflows.take(2).map((workflow) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: WrapdColors.p8),
                          child: _WorkflowPackageCard(
                            package: workflow,
                            isCompleted: false,
                            onTap: () => _openWorkflowDetails(context, workflow),
                          ),
                        )
                      ).toList(),
                  ),
                );
              },
              childCount: sessionProvider.readySessions.length,
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: WrapdColors.p48)),
      ],
    );
  }

  void _createNewWorkflow(BuildContext context) {
    _showCreateWorkflowDialog(context);
  }

  void _showCreateWorkflowDialog(BuildContext context) {
    final sessionProvider = context.read<SessionProvider>();
    final workflowProvider = context.read<WorkflowProvider>();
    final sessions = sessionProvider.readySessions;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? WrapdColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(WrapdColors.radiusHero)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Create Workflow for Session', style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No ready sessions found.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (ctx, i) {
                      final s = sessions[i];
                      return ListTile(
                        title: Text(s.title),
                        subtitle: Text('${s.duration.inMinutes}m · ${s.segments.length} segments'),
                        trailing: const Icon(Icons.add_circle_outline, color: WrapdColors.cobalt),
                        onTap: () {
                          final workflow = workflowProvider.createWorkflowFromSession(s);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Generated ${workflow.actions.length} actions for ${s.title}')),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _createWorkflowForSession(BuildContext context, String sessionId) {
    final sessionProvider = context.read<SessionProvider>();
    final workflowProvider = context.read<WorkflowProvider>();
    
    final session = sessionProvider.sessions.firstWhere((s) => s.id == sessionId);
    final workflow = workflowProvider.createWorkflowFromSession(session);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created workflow: ${workflow.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openWorkflowDetails(BuildContext context, WorkflowPackage package) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkflowDetailsScreen(packageId: package.id),
      ),
    );
  }
}

/// Workflow statistics card showing automation progress
class _WorkflowStatsCard extends StatelessWidget {
  final WorkflowStats stats;
  final bool isDark;

  const _WorkflowStatsCard({
    required this.stats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
        borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
        border: isDark
            ? Border.all(color: WrapdColors.darkBorder, width: 0.5)
            : null,
        boxShadow: isDark ? [] : WrapdColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(WrapdColors.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    size: 20, color: WrapdColors.cobalt),
                const SizedBox(width: WrapdColors.p8),
                Text('Automation Insights', 
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WrapdColors.cobalt,
                    )),
              ],
            ),
            const SizedBox(height: WrapdColors.p12),
            
            // Progress bars
            _ProgressRow(
              label: 'Overall Completion',
              value: stats.packageCompletionRate,
              subtext: '${stats.completedPackages}/${stats.totalPackages} workflows',
              isDark: isDark,
            ),
            const SizedBox(height: WrapdColors.p8),
            
            _ProgressRow(
              label: 'Action Completion',
              value: stats.actionCompletionRate,
              subtext: '${stats.completedActions}/${stats.totalActions} actions',
              isDark: isDark,
            ),
            const SizedBox(height: WrapdColors.p8),
            
            // Today's stat
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: WrapdColors.p12, vertical: WrapdColors.p4),
              decoration: BoxDecoration(
                color: WrapdColors.cobalt.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
              ),
              child: Text(
                'Today: ${stats.todayCompleted} completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: WrapdColors.cobalt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final String subtext;
  final bool isDark;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.subtext,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(subtext, style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: WrapdColors.p4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: isDark 
              ? WrapdColors.darkBorder.withValues(alpha: 0.3)
              : WrapdColors.lightBorder.withValues(alpha: 0.5),
          valueColor: AlwaysStoppedAnimation<Color>(WrapdColors.cobalt),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WrapdColors.p8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark 
              ? WrapdColors.darkMuted 
              : WrapdColors.lightMuted,
        ),
      ),
    );
  }
}

class _WorkflowPackageCard extends StatelessWidget {
  final WorkflowPackage package;
  final bool isCompleted;
  final VoidCallback onTap;

  const _WorkflowPackageCard({
    required this.package,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final completionText = isCompleted ? 'COMPLETED' : 'PENDING';
    final completionColor = isCompleted ? WrapdColors.success : WrapdColors.warning;
    final cardOpacity = isCompleted ? 0.7 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface)
                .withValues(alpha: cardOpacity),
            borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
            border: isDark
                ? Border.all(color: WrapdColors.darkBorder, width: 0.5)
                : null,
            boxShadow: isDark ? [] : WrapdColors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(WrapdColors.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with progress
                Row(
                  children: [
                    Icon(isCompleted ? Icons.check_circle_outlined : Icons.timer_outlined,
                        size: 18, color: completionColor),
                    const SizedBox(width: WrapdColors.p8),
                    Expanded(
                      child: Text(
                        package.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: WrapdColors.p8, vertical: 2),
                      decoration: BoxDecoration(
                        color: completionColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
                      ),
                      child: Text(
                        completionText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: completionColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WrapdColors.p8),
                
                // Progress indicator
                LinearProgressIndicator(
                  value: package.progress,
                  backgroundColor: isDark 
                      ? WrapdColors.darkBorder.withValues(alpha: 0.3)
                      : WrapdColors.lightBorder.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(completionColor),
                ),
                const SizedBox(height: WrapdColors.p4),
                
                // Action summary
                Text(
                  '${package.completedActionsCount}/${package.actions.length} actions completed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                  ),
                ),
                
                // Target types preview
                if (package.actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: WrapdColors.p8),
                    child: Wrap(
                      spacing: WrapdColors.p4,
                      runSpacing: WrapdColors.p4,
                      children: package.actions
                          .take(3)
                          .map((action) => 
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: WrapdColors.p6, vertical: WrapdColors.p2),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? WrapdColors.darkBorder.withValues(alpha: 0.3)
                                      : WrapdColors.lightBorder.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      action.targetTypeIcon,
                                      size: 12,
                                      color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                                    ),
                                    const SizedBox(width: WrapdColors.p2),
                                    Text(
                                      action.targetTypeDisplay,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          )
                          .toList(),
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

class _CreateWorkflowCard extends StatelessWidget {
  final WrapdSession session;
  final VoidCallback onCreate;

  const _CreateWorkflowCard({
    required this.session,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
        onTap: onCreate,
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface)
                .withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
            border: Border.all(
              color: WrapdColors.warning.withValues(alpha: 0.5),
              width: 1,
              style: BorderStyle.solid,
            ),
            boxShadow: [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(WrapdColors.p16),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, 
                    size: 18, 
                    color: WrapdColors.warning),
                const SizedBox(width: WrapdColors.p8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Workflow',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: WrapdColors.warning,
                        ),
                      ),
                      const SizedBox(height: WrapdColors.p4),
                      Text(
                        'Automate post-meeting tasks for "${session.title}"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkflowDetailsScreen extends StatelessWidget {
  final String packageId;

  const WorkflowDetailsScreen({
    super.key,
    required this.packageId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Details'),
      ),
      body: Consumer<WorkflowProvider>(
        builder: (context, provider, child) {
          final packages = provider.packages.where((p) => p.id == packageId).toList();
          
          if (packages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: WrapdColors.rose),
                  const SizedBox(height: 16),
                  const Text('Workflow not found'),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final package = packages.first;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: package.actions.length,
            itemBuilder: (context, index) {
              final action = package.actions[index];
              return _WorkflowActionCard(
                action: action,
                onToggle: () {
                  if (!action.isCompleted) {
                    provider.completeAction(package.id, action.id);
                  }
                },
                onAppChanged: (app) {
                  provider.setTargetApp(package.id, action.id, app);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkflowActionCard extends StatelessWidget {
  final WorkflowAction action;
  final VoidCallback onToggle;
  final Function(String) onAppChanged;

  const _WorkflowActionCard({
    required this.action,
    required this.onToggle,
    required this.onAppChanged,
  });

  List<String> _getAppOptions() {
    switch (action.targetType) {
      case ExportTargetType.email: return ['Gmail', 'Outlook', 'Apple Mail'];
      case ExportTargetType.calendar: return ['Google Calendar', 'Outlook', 'Apple Calendar'];
      case ExportTargetType.notion:
      case ExportTargetType.notion_page: return ['Notion', 'Obsidian', 'Anytype'];
      default: return ['Default App'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final apps = _getAppOptions();
    final selectedApp = action.targetApp ?? apps.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
        border: Border.all(color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder),
        boxShadow: isDark ? [] : WrapdColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(action.targetTypeIcon, color: action.isCompleted ? WrapdColors.success : WrapdColors.cobalt),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(action.title, style: theme.textTheme.titleSmall),
                ),
                if (action.isCompleted)
                  const Icon(Icons.check_circle, color: WrapdColors.success, size: 20)
                else
                  WrapdButton(
                    label: 'Execute',
                    variant: WrapdButtonVariant.primary,
                    height: 32,
                    onPressed: onToggle,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(action.description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('TARGET APP', style: theme.textTheme.titleSmall?.copyWith(fontSize: 10, color: WrapdColors.darkMuted)),
                const Spacer(),
                DropdownButton<String>(
                  value: selectedApp,
                  underline: const SizedBox(),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: WrapdColors.cobalt),
                  items: apps.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) onAppChanged(v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
