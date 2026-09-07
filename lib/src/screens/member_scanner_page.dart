import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app.dart';

class MemberScan {
  const MemberScan({required this.memberId, required this.userId});

  final String memberId;
  final int userId;

  static MemberScan? tryParse(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final direct = _fromMap(decoded);
        if (direct != null) return direct;
        final nested = decoded['data'];
        if (nested is Map) return _fromMap(nested);
      }
    } on FormatException {
      // Non-JSON QR codes are supported below as key/value text.
    }

    final userMatch = RegExp(
      r'user[_-]?id\s*[:=]\s*["\x27]?([0-9]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    final memberMatch = RegExp(
      r'member[_-]?id\s*[:=]\s*["\x27]?([A-Za-z0-9._-]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (userMatch == null || memberMatch == null) return null;

    return MemberScan(
      memberId: memberMatch.group(1)!,
      userId: int.parse(userMatch.group(1)!),
    );
  }

  static MemberScan? _fromMap(Map<dynamic, dynamic> data) {
    final memberValue = data['member_id'] ?? data['memberId'];
    final userValue = data['user_id'] ?? data['userId'];
    final memberId = memberValue?.toString().trim() ?? '';
    final userId = userValue is int
        ? userValue
        : int.tryParse(userValue?.toString() ?? '');
    if (memberId.isEmpty || userId == null) return null;
    return MemberScan(memberId: memberId, userId: userId);
  }
}

class MemberScannerPage extends StatefulWidget {
  const MemberScannerPage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<MemberScannerPage> createState() => _MemberScannerPageState();
}

class _MemberScannerPageState extends State<MemberScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  var _handled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || capture.barcodes.isEmpty) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    _handled = true;
    final member = MemberScan.tryParse(rawValue);
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This QR code must include member_id and user_id.'),
          ),
        );
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) _handled = false;
      return;
    }

    if (mounted) Navigator.of(context).pop(member);
  }

  Future<void> _manualEntry() async {
    final result = await showModalBottomSheet<MemberScan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ManualMemberSheet(),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.45),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _scannerController.toggleTorch,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.45),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.flashlight_on_outlined),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 238,
                  height: 238,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2.5),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.navyBright.withValues(alpha: 0.65),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: FilledButton.tonalIcon(
                    onPressed: _manualEntry,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppPalette.navy,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Enter member details manually'),
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

class _ManualMemberSheet extends StatefulWidget {
  const _ManualMemberSheet();

  @override
  State<_ManualMemberSheet> createState() => _ManualMemberSheetState();
}

class _ManualMemberSheetState extends State<_ManualMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _memberIdController = TextEditingController();
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _memberIdController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      MemberScan(
        memberId: _memberIdController.text.trim(),
        userId: int.parse(_userIdController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Member details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  'Use this only when a QR code cannot be read.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _memberIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Member ID'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a member ID.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _userIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  validator: (value) =>
                      int.tryParse(value?.trim() ?? '') == null
                      ? 'Enter a numeric user ID.'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Use member details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
