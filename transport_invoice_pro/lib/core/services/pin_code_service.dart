import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';

class PinCodeDetails {
  final String name;
  final String block;
  final String city;
  final String district;
  final String state;
  final String pinCode;

  PinCodeDetails({
    required this.name,
    required this.block,
    required this.city,
    required this.district,
    required this.state,
    required this.pinCode,
  });

  String get address {
    final List<String> rawParts = [
      if (name.isNotEmpty) name,
      if (block.isNotEmpty && block != 'NA' && block.toLowerCase() != name.toLowerCase()) block,
      if (district.isNotEmpty && district != 'NA' && district.toLowerCase() != block.toLowerCase() && district.toLowerCase() != name.toLowerCase()) district,
      if (state.isNotEmpty) state,
    ];
    final List<String> uniqueParts = [];
    for (final p in rawParts) {
      if (uniqueParts.isEmpty || uniqueParts.last.toLowerCase() != p.toLowerCase()) {
        uniqueParts.add(p);
      }
    }
    return '${uniqueParts.join(', ')} - $pinCode';
  }
}

class PinCodeService {
  static final Map<String, List<PinCodeDetails>> _cache = {};

  static Future<List<PinCodeDetails>> fetchAllDetails(String pinCode) async {
    if (pinCode.length != 6) return [];
    if (_cache.containsKey(pinCode)) return _cache[pinCode]!;

    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pinCode'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final List<dynamic> postOffices = data[0]['PostOffice'] ?? [];
          final List<PinCodeDetails> list = [];

          for (final po in postOffices) {
            final name = (po['Name'] ?? '').toString().trim();
            final block = (po['Block'] ?? '').toString().trim();
            final district = (po['District'] ?? '').toString().trim();
            final state = (po['State'] ?? '').toString().trim();
            final city = (district.isNotEmpty && district != 'NA')
                ? district
                : ((block.isNotEmpty && block != 'NA') ? block : name);

            list.add(PinCodeDetails(
              name: name,
              block: block,
              city: city,
              district: district,
              state: state,
              pinCode: pinCode,
            ));
          }
          _cache[pinCode] = list;
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<PinCodeDetails?> fetchDetails(String pinCode) async {
    final list = await fetchAllDetails(pinCode);
    return list.isNotEmpty ? list.first : null;
  }

  static Future<PinCodeDetails?> selectLocation(BuildContext context, String pinCode) async {
    final locations = await fetchAllDetails(pinCode);
    if (locations.isEmpty) return null;
    if (locations.length == 1) return locations.first;

    if (!context.mounted) return null;

    return showModalBottomSheet<PinCodeDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PinCodeSelectionSheet(pinCode: pinCode, locations: locations),
    );
  }
}

class _PinCodeSelectionSheet extends StatefulWidget {
  final String pinCode;
  final List<PinCodeDetails> locations;

  const _PinCodeSelectionSheet({
    required this.pinCode,
    required this.locations,
  });

  @override
  State<_PinCodeSelectionSheet> createState() => _PinCodeSelectionSheetState();
}

class _PinCodeSelectionSheetState extends State<_PinCodeSelectionSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.locations.where((loc) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return loc.name.toLowerCase().contains(q) ||
          loc.district.toLowerCase().contains(q) ||
          loc.city.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Select Area (PIN: ${widget.pinCode})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (widget.locations.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search area...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No matching location found'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          item.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
