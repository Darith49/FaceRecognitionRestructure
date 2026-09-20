import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _TeamMember {
  final String name;
  final String role;
  final Color avatarColor;
  final bool pinned;

  const _TeamMember(
    this.name,
    this.role,
    this.avatarColor, {
    this.pinned = false,
  });
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

  final _manager = const _TeamMember(
    'Larry Ellison',
    'Manager',
    RequestColors.primary,
    pinned: true,
  );

  final List<_TeamMember> _members = const [
    _TeamMember('Ava Thompson', 'UX UI', RequestColors.approvedStatus),
    _TeamMember('Ben Carter', 'Mobile App', RequestColors.gold),
    _TeamMember('Chloe Nguyen', 'Backend', RequestColors.teal),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_TeamMember> get _filteredMembers {
    if (_query.isEmpty) return _members;
    return _members
        .where(
          (m) =>
              m.name.toLowerCase().contains(_query.toLowerCase()) ||
              m.role.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  bool get _managerVisible =>
      _query.isEmpty ||
      _manager.name.toLowerCase().contains(_query.toLowerCase()) ||
      _manager.role.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (_managerVisible) ...[
                  _buildMemberCard(_manager),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                ],
                ..._filteredMembers.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMemberCard(m),
                  ),
                ),
                if (!_managerVisible && _filteredMembers.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 14, color: RequestColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search',
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(_TeamMember member) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: member.avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  member.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              if (member.pinned)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.push_pin_rounded,
                      size: 12,
                      color: RequestColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RequestColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: RequestColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.call_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: RequestColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No team members found',
            style: TextStyle(color: RequestColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
