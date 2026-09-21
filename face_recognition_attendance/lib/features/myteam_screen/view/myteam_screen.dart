import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Local design tokens (only used by this screen)
// ---------------------------------------------------------------------------

const Color _primaryDark = Color(0xFF2456C7);

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0F1B2437), blurRadius: 14, offset: Offset(0, 4)),
];

/// The most profiles a user can pin at the same time.
const int _maxPins = 3;

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _TeamMember {
  final String name;
  final String role;
  final Color avatarColor;
  final bool isManager;

  /// Only the starting value. The live pin state is kept in the screen state.
  final bool pinnedByDefault;

  const _TeamMember(
    this.name,
    this.role,
    this.avatarColor, {
    this.isManager = false,
    this.pinnedByDefault = false,
  });
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MyteamScreen extends StatefulWidget {
  const MyteamScreen({super.key});

  @override
  State<MyteamScreen> createState() => _MyteamScreenState();
}

class _MyteamScreenState extends State<MyteamScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<_TeamMember> _people = const [
    _TeamMember(
      'Larry Ellison',
      'Manager',
      RequestColors.primary,
      isManager: true,
      pinnedByDefault: true,
    ),
    _TeamMember('Ava Thompson', 'UX UI', RequestColors.approvedStatus),
    _TeamMember('Ben Carter', 'Mobile App', RequestColors.gold),
    _TeamMember('Chloe Nguyen', 'Backend', RequestColors.teal),
  ];

  /// Names of the pinned profiles (at most [_maxPins]).
  /// TODO: save this per user (for example in Firestore) so the pins are
  /// still there after the app is restarted.
  late final Set<String> _pinned = {
    for (final p in _people)
      if (p.pinnedByDefault) p.name,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(_TeamMember m) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return m.name.toLowerCase().contains(q) || m.role.toLowerCase().contains(q);
  }

  void _togglePin(_TeamMember member) {
    if (_pinned.contains(member.name)) {
      setState(() => _pinned.remove(member.name));
    } else if (_pinned.length >= _maxPins) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'You can pin up to $_maxPins profiles. Unpin one first.',
      );
    } else {
      setState(() => _pinned.add(member.name));
    }
  }

  void _onCall(_TeamMember member) {
    // TODO: open the phone dialer once phone numbers are stored for members.
    RequestSnack.show(
      ScaffoldMessenger.of(context),
      'Calling ${member.name} is coming soon.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _people.where(_matches).toList();
    final pinned = visible.where((m) => _pinned.contains(m.name)).toList();
    final others = visible.where((m) => !_pinned.contains(m.name)).toList();

    return RequestScaffold(
      title: 'My Team',
      showBackButton: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // Extra space at the bottom so the floating bar does not cover the last card.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                if (pinned.isNotEmpty) ...[
                  _SectionHeader(
                    'Pinned',
                    badge: '${_pinned.length}/$_maxPins',
                    badgeColor: _pinned.length >= _maxPins
                        ? RequestColors.gold
                        : RequestColors.primary,
                  ),
                  ...pinned.map(_buildPersonItem),
                  const SizedBox(height: 12),
                ],
                if (others.isNotEmpty) ...[
                  _SectionHeader('Team Members', badge: '${others.length}'),
                  ...others.map(_buildPersonItem),
                ],
                if (visible.isEmpty) _buildEmptyState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonItem(_TeamMember member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: member.isManager
          ? _buildManagerCard(member)
          : _buildMemberCard(member),
    );
  }

  // ------------------------------- search bar ------------------------------

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: _softShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: RequestColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search by name or role',
          hintStyle: const TextStyle(
            color: RequestColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: RequestColors.primary,
            size: 22,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: RequestColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 4,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: RequestColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------ manager card -----------------------------

  Widget _buildManagerCard(_TeamMember member) {
    final avatar = Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 3,
        ),
      ),
      child: Text(
        _initials(member.name),
        style: const TextStyle(
          color: RequestColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 19,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RequestColors.primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: RequestColors.primary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _withPinBadge(avatar, _pinned.contains(member.name)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildActions(member, onDark: true),
        ],
      ),
    );
  }

  // ------------------------------ member card ------------------------------

  Widget _buildMemberCard(_TeamMember member) {
    final color = member.avatarColor;

    final avatar = Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
      ),
      child: Text(
        _initials(member.name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: _softShadow,
      ),
      child: Row(
        children: [
          _withPinBadge(avatar, _pinned.contains(member.name)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildActions(member, onDark: false),
        ],
      ),
    );
  }

  // ------------------------- pin badge + action buttons --------------------

  /// Small red pin in the corner of the avatar of every pinned profile.
  Widget _withPinBadge(Widget avatar, bool pinned) {
    if (!pinned) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _softShadow,
            ),
            child: const Icon(
              Icons.push_pin_rounded,
              size: 12,
              color: RequestColors.danger,
            ),
          ),
        ),
      ],
    );
  }

  /// Pin / unpin button + call button shown on the right of every card.
  Widget _buildActions(_TeamMember member, {required bool onDark}) {
    final pinned = _pinned.contains(member.name);

    final Color pinBackground = onDark
        ? Colors.white.withValues(alpha: pinned ? 0.32 : 0.16)
        : (pinned
              ? RequestColors.primary.withValues(alpha: 0.12)
              : RequestColors.background.withValues(alpha: 0.6));
    final Color pinIconColor = onDark
        ? Colors.white
        : (pinned ? RequestColors.primary : RequestColors.textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleButton(
          icon: pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          tooltip: pinned ? 'Unpin' : 'Pin',
          background: pinBackground,
          iconColor: pinIconColor,
          onTap: () => _togglePin(member),
        ),
        const SizedBox(width: 8),
        _circleButton(
          icon: Icons.call_rounded,
          tooltip: 'Call',
          background: onDark
              ? Colors.white
              : RequestColors.primary.withValues(alpha: 0.10),
          iconColor: RequestColors.primary,
          onTap: () => _onCall(member),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }

  // ------------------------------ empty state ------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _softShadow,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: RequestColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No team members found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try searching by a different name or role.',
            style: TextStyle(fontSize: 13, color: RequestColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small private widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
    this.title, {
    this.badge,
    this.badgeColor = RequestColors.primary,
  });

  final String title;
  final String? badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: RequestColors.textPrimary,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}