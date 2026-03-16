import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/session_model.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import 'session_detail_screen.dart';
import 'record_screen.dart';

// ─────────────────────────────────────────────────────────
//  LibraryScreen — Full session list with search/filter
// ─────────────────────────────────────────────────────────

class LibraryScreen extends StatefulWidget {
  final bool assignedToMe;
  const LibraryScreen({super.key, this.assignedToMe = false});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  SessionStatus? _filterStatus;
  bool _showArchived = false;
  bool _sortAscending = false;
  late bool _assignedToMe;

  @override
  void initState() {
    super.initState();
    _assignedToMe = widget.assignedToMe;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<SessionProvider>();

    var sessions = provider.sessions.where((s) {
      final matchesQuery =
          s.title.toLowerCase().contains(_query.toLowerCase()) ||
          s.segments.any((seg) => seg.text.toLowerCase().contains(_query.toLowerCase()));
      final matchesStatus =
          _filterStatus == null || s.status == _filterStatus;
      final matchesArchive = s.isArchived == _showArchived;

      // assignedToMe: show sessions where the current user's display name
      // appears as a speaker. Falls back to showing all if no name match found.
      final currentUserName = provider.userName.toLowerCase();
      final matchesAssigned = !_assignedToMe ||
          s.segments.any((seg) =>
              seg.speakerName.toLowerCase().contains(currentUserName));

      return matchesQuery && matchesStatus && matchesArchive && matchesAssigned;
    }).toList();

    // Sort by date
    sessions.sort((a, b) => _sortAscending 
        ? a.createdAt.compareTo(b.createdAt) 
        : b.createdAt.compareTo(a.createdAt));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          title: Text(_showArchived ? 'Archive' : 'Library'),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_mode_outlined, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mass Export started for all sessions...')),
                );
              },
              tooltip: 'Mass Export',
            ),
            IconButton(
              icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
              onPressed: () => setState(() => _sortAscending = !_sortAscending),
              tooltip: 'Sort by Date',
            ),
            IconButton(
              icon: Icon(_showArchived ? Icons.library_books : Icons.archive_outlined, size: 20),
              onPressed: () => setState(() => _showArchived = !_showArchived),
              tooltip: _showArchived ? 'Show Library' : 'Show Archive',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WrapdColors.p16, 0, WrapdColors.p16, WrapdColors.p12),
              child: Column(
                children: [
                  // Search
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search title or content...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: WrapdColors.p8),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _filterStatus == null,
                          onTap: () =>
                              setState(() => _filterStatus = null),
                        ),
                        const SizedBox(width: WrapdColors.p8),
                        _FilterChip(
                          label: 'Ready',
                          isSelected:
                              _filterStatus == SessionStatus.ready,
                          onTap: () => setState(
                              () => _filterStatus = SessionStatus.ready),
                        ),
                        const SizedBox(width: WrapdColors.p8),
                        _FilterChip(
                          label: 'Processing',
                          isSelected: _filterStatus ==
                              SessionStatus.processing,
                          onTap: () => setState(() =>
                              _filterStatus = SessionStatus.processing),
                        ),
                        const SizedBox(width: WrapdColors.p8),
                        _FilterChip(
                          label: 'Draft',
                          isSelected:
                              _filterStatus == SessionStatus.draft,
                          onTap: () => setState(
                              () => _filterStatus = SessionStatus.draft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        provider.isLoading
            ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: WrapdColors.cobalt),
                ),
              )
            : sessions.isEmpty
                ? SliverFillRemaining(
                child: EmptyState(
                  icon: _showArchived ? Icons.archive_outlined : Icons.library_books_outlined,
                  title: _showArchived ? 'Archive is empty' : 'No sessions yet',
                  message: _showArchived 
                    ? 'Archived meetings will appear here.'
                    : 'Your recorded meetings will be listed here.',
                  actionLabel: _showArchived ? null : 'Start First Session',
                  onAction: _showArchived ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecordScreen()),
                    );
                  },
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final session = sessions[i];
                    return SessionCard(
                      session: session,
                      onTap: () {
                        provider.setActiveSession(session.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionDetailScreen(
                                sessionId: session.id),
                          ),
                        );
                      },
                      onLongPress: () {
                        _showSessionActions(context, session, provider);
                      },
                    );
                  },
                  childCount: sessions.length,
                ),
              ),

        const SliverPadding(
            padding: EdgeInsets.only(bottom: WrapdColors.p48)),
      ],
    );
  }

  void _showSessionActions(BuildContext context, WrapdSession session, SessionProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(session.isArchived ? Icons.unarchive : Icons.archive),
            title: Text(session.isArchived ? 'Unarchive' : 'Archive'),
            onTap: () {
              provider.toggleArchive(session.id);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: WrapdColors.danger),
            title: const Text('Delete Permanently', style: TextStyle(color: WrapdColors.danger)),
            onTap: () {
              final deletedSession = session;
              provider.deleteSession(session.id);
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${deletedSession.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => provider.undoDelete(deletedSession),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Filter: $label',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
          child: AnimatedContainer(
            duration: WrapdColors.fast,
            padding: const EdgeInsets.symmetric(
                horizontal: WrapdColors.p12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? WrapdColors.cobalt
                  : isDark
                      ? WrapdColors.darkSurface
                      : WrapdColors.lightSurface,
              borderRadius:
                  BorderRadius.circular(WrapdColors.radiusPill),
              border: Border.all(
                color: isSelected
                    ? WrapdColors.cobalt
                    : isDark
                        ? WrapdColors.darkBorder
                        : WrapdColors.lightBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? WrapdColors.darkMuted
                        : WrapdColors.lightMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
