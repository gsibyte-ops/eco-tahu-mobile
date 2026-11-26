import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'shimmer_skeletons.dart';

class SearchSuggestionItem {
  final String id;
  final String categoryKey;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final String imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const SearchSuggestionItem({
    required this.id,
    required this.categoryKey,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.onTap,
  });
}

/// Searchbar bergaya Google Search: mengetik memunculkan dropdown rekomendasi
/// mengambang langsung di bawah kolom pencarian tanpa mengubah/menghapus isi
/// halaman di belakangnya. Pencarian akurat khusus berdasarkan NAMA/JUDUL saja.
class GoogleSearchDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Color? accentColor;
  final List<SearchSuggestionItem> items;
  final List<String>? filterTabs;
  final BorderRadius? borderRadius;

  const GoogleSearchDropdown({
    super.key,
    required this.controller,
    required this.hintText,
    required this.items,
    this.accentColor,
    this.filterTabs,
    this.borderRadius,
  });

  @override
  State<GoogleSearchDropdown> createState() => _GoogleSearchDropdownState();
}

class _GoogleSearchDropdownState extends State<GoogleSearchDropdown> {
  final FocusNode _focusNode = FocusNode();
  String _selectedFilter = 'Semua';
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _dismissed = false;
      });
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<SearchSuggestionItem> get _matches {
    final q = widget.controller.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.items
        .where((item) {
          if (_selectedFilter != 'Semua' && item.categoryKey != _selectedFilter) {
            return false;
          }
          return item.title.toLowerCase().contains(q);
        })
        .take(7)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.text.trim();
    final bool showDropdown = query.isNotEmpty && !_dismissed;
    final Color accent = widget.accentColor ?? context.brandGreen;
    final BorderRadius radius = widget.borderRadius ?? BorderRadius.circular(18);
    final matches = _matches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: radius,
            border: Border.all(
              color: showDropdown ? accent.withValues(alpha: 0.55) : context.border,
              width: showDropdown ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textAlignVertical: TextAlignVertical.center,
            onTap: () {
              if (_dismissed) {
                setState(() => _dismissed = false);
              }
            },
            style: TextStyle(fontSize: 13.5, color: context.textPrimary),
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: accent, size: 21),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: context.textMuted, size: 18),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() => _dismissed = true);
                        _focusNode.unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
        ),

        if (showDropdown) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 330),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.42 : 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header info & optional category filter chips
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppTheme.darkSurfaceElevated.withValues(alpha: 0.7)
                        : const Color(0xFFF8FAFC),
                    border: Border(bottom: BorderSide(color: context.border, width: 0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 13, color: accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hasil pencarian nama (${matches.length})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.textMuted,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _dismissed = true);
                              _focusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'Tutup',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.filterTabs != null && widget.filterTabs!.length > 1) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.filterTabs!.map((tab) {
                              final active = _selectedFilter == tab;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedFilter = tab),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: active ? accent : context.cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: active ? accent : context.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tab,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: active ? Colors.white : context.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off_rounded, color: accent, size: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ditemukan untuk "$query"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pastikan kata kunci sesuai nama item yang dicari.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: context.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.8,
                        color: context.border,
                      ),
                      itemBuilder: (context, idx) {
                        final item = matches[idx];
                        return InkWell(
                          onTap: () {
                            _focusNode.unfocus();
                            item.onTap();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: EcoCachedImage(
                                    imageUrl: item.imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    fallbackIcon: item.fallbackIcon,
                                    fallbackColor: item.badgeColor,
                                    fallbackBgColor: item.badgeColor.withValues(alpha: 0.12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.badgeColor.withValues(alpha: 0.13),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.badge,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: item.badgeColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: context.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.north_west_rounded, size: 15, color: context.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
