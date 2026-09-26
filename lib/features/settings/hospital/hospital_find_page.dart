import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/api/hospital_api.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/models/my_hospital.dart';

/// Searches hospitals on Google Maps; tapping one adds it straight away.
/// Pops `true` once a hospital was added.
class HospitalFindPage extends StatefulWidget {
  const HospitalFindPage({super.key});

  @override
  State<HospitalFindPage> createState() => _HospitalFindPageState();
}

class _HospitalFindPageState extends State<HospitalFindPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<HospitalPlace> _results = [];
  bool _isLoading = false;
  bool _isAdding = false;
  String? _error;
  int _requestId = 0;

  Color get _ink => context.palette.textPrimary;
  Color get _inkSoft => context.palette.textSecondary;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await HospitalApi.searchHospitals(query);
    // Ignore stale responses from earlier keystrokes.
    if (!mounted || requestId != _requestId) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.items is List) {
        _results = (res.items as List)
            .map((e) => HospitalPlace.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _results = [];
        _error = res.detail.isNotEmpty
            ? res.detail
            : 'Failed to search hospitals';
      }
    });
  }

  Future<void> _add(HospitalPlace place) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    final res = await HospitalApi.addHospital(place.raw);
    if (!mounted) return;
    setState(() => _isAdding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'Hospital added' : res.detail),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (res.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: context.palette.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Find Hospital',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _search,
              style: TextStyle(color: _ink),
              decoration: InputDecoration(
                hintText: 'Search hospitals...',
                hintStyle: TextStyle(color: context.palette.textMuted),
                prefixIcon: Icon(Icons.search, color: _inkSoft),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: Icon(Icons.clear, color: _inkSoft),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        ),
                ),
                filled: true,
                fillColor: context.palette.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading || _isAdding)
            const LinearProgressIndicator(minHeight: 2, color: primaryColor),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) return _message(Icons.error_outline, _error!);
    if (_results.isEmpty) {
      return _message(
        Icons.travel_explore,
        _searchController.text.trim().length < 2
            ? 'Search for your hospital on Google Maps'
            : (_isLoading ? '' : 'No hospitals found'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _results.length,
      itemBuilder: (_, i) => _placeCard(_results[i]),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: context.palette.textMuted),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: _inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeCard(HospitalPlace place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isAdding ? null : () => _add(place),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.palette.tint(primaryColor, accentLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (place.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.category!,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: _inkSoft,
                          ),
                        ),
                      ],
                      if (place.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          place.address!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (place.rating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: warningAmber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${place.rating!.toStringAsFixed(1)}'
                              '${place.ratingCount != null ? ' (${place.ratingCount})' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline_rounded, color: primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
