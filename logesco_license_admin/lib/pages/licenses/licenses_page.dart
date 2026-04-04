import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/license.dart';
import '../../models/client.dart';
import '../../core/services/database_service.dart';

class LicensesPage extends ConsumerStatefulWidget {
  const LicensesPage({super.key});

  @override
  ConsumerState<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends ConsumerState<LicensesPage> with SingleTickerProviderStateMixin {
  List<License> _licenses = [];
  Map<String, Client> _clientsMap = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final licenses = await DatabaseService.instance.getLicenses();
      final clients = await DatabaseService.instance.getClients();
      setState(() {
        _licenses = licenses;
        _clientsMap = {for (final c in clients) c.id: c};
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Erreur: $e'),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<License> get _filteredLicenses {
    if (_searchQuery.isEmpty) return _licenses;
    final q = _searchQuery.toLowerCase();
    return _licenses.where((l) {
      final client = _clientsMap[l.clientId];
      final clientName = client?.name.toLowerCase() ?? '';
      final company = client?.company.toLowerCase() ?? '';
      return clientName.contains(q) || company.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(License license, Client? client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer la licence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Voulez-vous vraiment supprimer la licence de ${client?.name ?? license.clientId} ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                'Cette action est irréversible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseService.instance.deleteLicense(license.id);
      setState(() => _licenses.removeWhere((l) => l.id == license.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Licence supprimée avec succès'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLicenses;
    final colorScheme = Theme.of(context).colorScheme;

    // Stats summary
    final activeCount = _licenses.where((l) => l.status == LicenseStatus.active).length;
    final expiredCount = _licenses.where((l) => l.status == LicenseStatus.expired).length;
    final revokedCount = _licenses.where((l) => l.status == LicenseStatus.revoked).length;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: const Text(
          'Licences',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Actualiser',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Chargement...', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : Column(
              children: [
                // Stats row
                if (_licenses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        _StatChip(count: activeCount, label: 'Actives', color: Colors.green),
                        const SizedBox(width: 8),
                        _StatChip(count: expiredCount, label: 'Expirées', color: Colors.orange),
                        const SizedBox(width: 8),
                        _StatChip(count: revokedCount, label: 'Révoquées', color: Colors.red),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            '${_licenses.length} licence${_licenses.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par client ou entreprise...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(
                          hasSearch: _searchQuery.isNotEmpty,
                          onGenerate: () => context.go('/licenses/new'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final license = filtered[index];
                            final client = _clientsMap[license.clientId];
                            return _LicenseCard(
                              license: license,
                              client: client,
                              index: index,
                              animController: _animController,
                              onView: () => _viewLicense(license, client),
                              onDelete: () => _confirmDelete(license, client),
                              getStatusColor: _getStatusColor,
                              getStatusIcon: _getStatusIcon,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/licenses/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle licence', style: TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Color _getStatusColor(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return Colors.green;
      case LicenseStatus.expired:
        return Colors.orange;
      case LicenseStatus.revoked:
        return Colors.red;
      case LicenseStatus.suspended:
        return Colors.yellow;
    }
  }

  IconData _getStatusIcon(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return Icons.check_circle_rounded;
      case LicenseStatus.expired:
        return Icons.warning_rounded;
      case LicenseStatus.revoked:
        return Icons.block_rounded;
      case LicenseStatus.suspended:
        return Icons.pause_circle_rounded;
    }
  }

  void _viewLicense(License license, Client? client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LicenseDetailSheet(
        license: license,
        client: client,
        getStatusColor: _getStatusColor,
        getStatusIcon: _getStatusIcon,
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(license, client);
        },
      ),
    );
  }
}

// ─── Stat Chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── License Card ─────────────────────────────────────────────────────────────

class _LicenseCard extends StatefulWidget {
  final License license;
  final Client? client;
  final int index;
  final AnimationController animController;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final Color Function(LicenseStatus) getStatusColor;
  final IconData Function(LicenseStatus) getStatusIcon;

  const _LicenseCard({
    required this.license,
    required this.client,
    required this.index,
    required this.animController,
    required this.onView,
    required this.onDelete,
    required this.getStatusColor,
    required this.getStatusIcon,
  });

  @override
  State<_LicenseCard> createState() => _LicenseCardState();
}

class _LicenseCardState extends State<_LicenseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.getStatusColor(widget.license.status);
    final statusIcon = widget.getStatusIcon(widget.license.status);
    final colorScheme = Theme.of(context).colorScheme;

    final delay = (widget.index * 0.06).clamp(0.0, 0.5);
    final animation = CurvedAnimation(
      parent: widget.animController,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - animation.value)),
        child: Opacity(opacity: animation.value, child: child),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? statusColor.withOpacity(0.15) : Colors.black.withOpacity(0.05),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.client?.name ?? widget.license.clientId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: widget.license.statusLabel,
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.client?.company ?? '—',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.key_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.license.typeLabel,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Expire le ${widget.license.expiresAt.day}/${widget.license.expiresAt.month}/${widget.license.expiresAt.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.license.status == LicenseStatus.expired ? Colors.orange[600] : Colors.grey[500],
                              fontWeight: widget.license.status == LicenseStatus.expired ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    _ActionButton(
                      icon: Icons.open_in_new_rounded,
                      tooltip: 'Voir les détails',
                      color: colorScheme.primary,
                      onTap: widget.onView,
                    ),
                    const SizedBox(height: 6),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Supprimer',
                      color: Colors.red,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _pressed ? widget.color.withOpacity(0.15) : widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 16, color: widget.color),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onGenerate;

  const _EmptyState({required this.hasSearch, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.key_off_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasSearch ? 'Aucun résultat' : 'Aucune licence',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch ? 'Essayez un autre terme de recherche' : 'Commencez par générer votre première licence',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Générer une licence'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── License Detail Bottom Sheet ─────────────────────────────────────────────

class _LicenseDetailSheet extends StatelessWidget {
  final License license;
  final Client? client;
  final Color Function(LicenseStatus) getStatusColor;
  final IconData Function(LicenseStatus) getStatusIcon;
  final VoidCallback onDelete;

  const _LicenseDetailSheet({
    required this.license,
    required this.client,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(license.status);
    final statusIcon = getStatusIcon(license.status);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client != null ? '${client!.name} (${client!.company})' : license.clientId,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _StatusBadge(label: license.statusLabel, color: statusColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey[100]),

          // Details
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info grid
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _SheetDetailRow(icon: Icons.key_rounded, label: 'Type', value: license.typeLabel),
                        _SheetDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Émise le',
                          value: '${license.issuedAt.day}/${license.issuedAt.month}/${license.issuedAt.year}',
                        ),
                        _SheetDetailRow(
                          icon: Icons.event_rounded,
                          label: 'Expire le',
                          value: '${license.expiresAt.day}/${license.expiresAt.month}/${license.expiresAt.year}',
                          isLast: license.price == null,
                        ),
                        if (license.price != null)
                          _SheetDetailRow(
                            icon: Icons.attach_money_rounded,
                            label: 'Prix',
                            value: '${license.price!.toStringAsFixed(2)} ${license.currency}',
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _CopyableBlock(label: 'Clé de licence', value: license.licenseKey),
                  const SizedBox(height: 14),
                  _CopyableBlock(label: 'Empreinte appareil', value: license.deviceFingerprint),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _SheetDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
      ],
    );
  }
}

class _CopyableBlock extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copié'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copier', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1923),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey[800]!, width: 1),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              color: Color(0xFF7ECBA1),
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
