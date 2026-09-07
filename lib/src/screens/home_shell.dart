import 'package:flutter/material.dart';

import '../app.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';
import 'member_scanner_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionStore.session!;
    final api = ApiClient(session);
    final pages = [
      CustomersScreen(api: api),
      SessionScanScreen(api: api),
      ClassesScreen(api: api),
      ProfileScreen(api: api, sessionStore: widget.sessionStore),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppPalette.navy,
          boxShadow: [
            BoxShadow(
              color: Color(0x2A071A33),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppPalette.navy,
            indicatorColor: Colors.white.withValues(alpha: 0.14),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: Colors.white.withValues(
                  alpha: states.contains(WidgetState.selected) ? 1 : 0.62,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: Colors.white.withValues(
                  alpha: states.contains(WidgetState.selected) ? 1 : 0.6,
                ),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code_scanner_rounded),
                label: 'QR scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Classes',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Map<String, dynamic>>> _customers;

  @override
  void initState() {
    super.initState();
    _customers = widget.api.customers();
  }

  Future<void> _reload() async {
    setState(() => _customers = widget.api.customers());
    await _customers;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _customers,
      builder: (context, snapshot) {
        final customers = snapshot.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              const _PageIntro(
                eyebrow: 'TRAINER ROSTER',
                title: 'Your customers',
                subtitle:
                    'Members assigned to your personal training sessions.',
              ),
              const SizedBox(height: 22),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _LoadingList()
              else if (snapshot.hasError)
                _ErrorCard(
                  message: _errorText(snapshot.error),
                  onRetry: _reload,
                )
              else if (customers.isEmpty)
                const _EmptyCard(
                  icon: Icons.groups_outlined,
                  title: 'No customers assigned yet',
                  detail:
                      'Assigned personal-training customers will appear here.',
                )
              else ...[
                _RosterCount(count: customers.length),
                const SizedBox(height: 14),
                ...customers.map(
                  (customer) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CustomerCard(customer: customer),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RosterCount extends StatelessWidget {
  const _RosterCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: AppPalette.navy,
            ),
          ),
          const SizedBox(width: 13),
          Text('$count', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 7),
          Text(
            count == 1 ? 'active customer' : 'active customers',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final name = _text(customer['name'], fallback: 'Unnamed member');
    final memberId = _text(customer['member_id']);
    final userId = _text(customer['user_id']);
    return _WhiteCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppPalette.navy,
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  memberId.isEmpty ? 'User ID: $userId' : memberId,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppPalette.steel),
        ],
      ),
    );
  }
}

class SessionScanScreen extends StatefulWidget {
  const SessionScanScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SessionScanScreen> createState() => _SessionScanScreenState();
}

class _SessionScanScreenState extends State<SessionScanScreen> {
  var _isSubmitting = false;

  Future<void> _scanAndConsume() async {
    final member = await Navigator.of(context).push<MemberScan>(
      MaterialPageRoute(
        builder: (_) => const MemberScannerPage(
          title: 'Check in member',
          subtitle: 'Align the member QR code inside the frame',
        ),
      ),
    );
    if (member == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await widget.api.consumeSession(
        customerUserId: member.userId,
      );
      if (!mounted) return;
      await _showSuccess(
        context,
        title: 'Session consumed',
        member: member,
        detail: _resultDetail(
          result,
          fallback: 'The member session has been recorded.',
        ),
      );
    } on ApiFailure catch (error) {
      if (mounted) _showError(context, error.message);
    } catch (_) {
      if (mounted) {
        _showError(
          context,
          'The session could not be recorded. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const _PageIntro(
          eyebrow: 'SESSION CHECK-IN',
          title: 'Scan. Confirm. Train.',
          subtitle:
              'Use a member QR code to consume one personal-training session.',
        ),
        const SizedBox(height: 28),
        Container(
          height: 274,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.navy, AppPalette.navyBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -42,
                top: -32,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Ready for the next member?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The QR must contain both member_id and user_id.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _scanAndConsume,
          icon: _isSubmitting
              ? const SizedBox(
                  height: 19,
                  width: 19,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.center_focus_strong_rounded),
          label: Text(
            _isSubmitting ? 'Recording session...' : 'Start QR scanner',
          ),
        ),
        const SizedBox(height: 18),
        _WhiteCard(
          padding: const EdgeInsets.all(17),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppPalette.navy),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If a camera cannot read the code, use the manual entry option in the scanner. Confirm the member ID before continuing.',
                  style: TextStyle(color: Color(0xFF52657A), height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  late Future<List<Map<String, dynamic>>> _classes;

  @override
  void initState() {
    super.initState();
    _classes = widget.api.classes();
  }

  Future<void> _reload() async {
    setState(() => _classes = widget.api.classes());
    await _classes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _classes,
      builder: (context, snapshot) {
        final classes = snapshot.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              const _PageIntro(
                eyebrow: 'CLASS PROGRAMME',
                title: 'Your classes',
                subtitle:
                    'Open a class to review its schedule and take attendance.',
              ),
              const SizedBox(height: 22),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _LoadingList()
              else if (snapshot.hasError)
                _ErrorCard(
                  message: _errorText(snapshot.error),
                  onRetry: _reload,
                )
              else if (classes.isEmpty)
                const _EmptyCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'No classes found',
                  detail: 'Classes assigned to this trainer will appear here.',
                )
              else
                ...classes.map(
                  (gymClass) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ClassCard(
                      gymClass: gymClass,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClassDetailScreen(
                              api: widget.api,
                              gymClass: gymClass,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.gymClass, required this.onTap});

  final Map<String, dynamic> gymClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final schedule = _mapList(gymClass['schedule']);
    final classType = _text(
      gymClass['class_type'],
      fallback: 'class',
    ).toUpperCase();
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  classType == 'PAID'
                      ? Icons.workspace_premium_outlined
                      : Icons.fitness_center_outlined,
                  color: AppPalette.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _text(gymClass['name'], fallback: 'Untitled class'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _TypePill(label: classType),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${schedule.length} ${schedule.length == 1 ? 'schedule' : 'schedules'}  |  ${_text(gymClass['instructor_name'], fallback: 'Trainer')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: AppPalette.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({
    super.key,
    required this.api,
    required this.gymClass,
  });

  final ApiClient api;
  final Map<String, dynamic> gymClass;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late Future<List<Map<String, dynamic>>> _schedule;
  late List<Map<String, dynamic>> _scheduleLines;
  late DateTime _attendanceDate;
  int? _selectedScheduleId;
  var _isMarkingAttendance = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _attendanceDate = DateTime(now.year, now.month, now.day);
    _scheduleLines = _mapList(widget.gymClass['schedule']);
    _selectedScheduleId = _scheduleLines.isEmpty
        ? null
        : _int(_scheduleLines.first['id']);
    _schedule = _loadSchedule();
  }

  Future<List<Map<String, dynamic>>> _loadSchedule() async {
    final now = DateTime.now();
    final allSchedule = await widget.api.schedule(
      dateFrom: now.subtract(const Duration(days: 7)),
      dateTo: now.add(const Duration(days: 35)),
    );
    final classId = _int(widget.gymClass['id']);
    return allSchedule
        .where((slot) => _int(slot['gym_class_id']) == classId)
        .toList();
  }

  Future<void> _reloadSchedule() async {
    setState(() => _schedule = _loadSchedule());
    await _schedule;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT CLASS DATE',
    );
    if (selected != null && mounted) setState(() => _attendanceDate = selected);
  }

  Future<void> _scanAndMarkDone() async {
    final classId = _int(widget.gymClass['id']);
    if (classId == null) {
      _showError(context, 'This class does not have a valid class ID.');
      return;
    }

    final member = await Navigator.of(context).push<MemberScan>(
      MaterialPageRoute(
        builder: (_) => const MemberScannerPage(
          title: 'Class attendance',
          subtitle: 'Scan the member QR code to mark attendance',
        ),
      ),
    );
    if (member == null || !mounted) return;

    setState(() => _isMarkingAttendance = true);
    try {
      final result = await widget.api.markClassDone(
        customerUserId: member.userId,
        classId: classId,
        date: _attendanceDate,
        scheduleId: _selectedScheduleId,
      );
      if (!mounted) return;
      await _showSuccess(
        context,
        title: 'Attendance marked',
        member: member,
        detail: _resultDetail(
          result,
          fallback: 'Class attendance has been recorded.',
        ),
      );
      if (mounted) {
        _reloadSchedule();
      }
    } on ApiFailure catch (error) {
      if (mounted) _showError(context, error.message);
    } catch (_) {
      if (mounted) {
        _showError(
          context,
          'Attendance could not be recorded. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymClass = widget.gymClass;
    final classType = _text(
      gymClass['class_type'],
      fallback: 'class',
    ).toUpperCase();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.mist,
        foregroundColor: AppPalette.navy,
        elevation: 0,
        title: const Text(
          'Class details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadSchedule,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.navy, AppPalette.navyBright],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypePill(label: classType, dark: true),
                  const SizedBox(height: 16),
                  Text(
                    _text(gymClass['name'], fallback: 'Untitled class'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instructor: ${_text(gymClass['instructor_name'], fallback: 'Trainer')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  if (_text(gymClass['capacity']).isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Capacity: ${_text(gymClass['capacity'])}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upcoming schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _schedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingList(compact: true);
                }
                if (snapshot.hasError) {
                  return _ErrorCard(
                    message: _errorText(snapshot.error),
                    onRetry: _reloadSchedule,
                  );
                }
                final slots = snapshot.data ?? const <Map<String, dynamic>>[];
                if (slots.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.event_busy_outlined,
                    title: 'No upcoming sessions',
                    detail: 'Pull down to refresh the trainer schedule.',
                    compact: true,
                  );
                }
                return Column(
                  children: slots
                      .map(
                        (slot) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _ScheduleCard(slot: slot),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Take attendance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _WhiteCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose the session date before scanning a member.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _longDate(_attendanceDate),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  if (_scheduleLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedScheduleId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Class schedule',
                      ),
                      items: _scheduleLines
                          .map(
                            (line) => DropdownMenuItem<int>(
                              value: _int(line['id']),
                              child: Text(
                                _text(
                                  line['display_name'],
                                  fallback: _scheduleLineLabel(line),
                                ),
                              ),
                            ),
                          )
                          .where((item) => item.value != null)
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedScheduleId = value),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _isMarkingAttendance ? null : _scanAndMarkDone,
                    icon: _isMarkingAttendance
                        ? const SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      _isMarkingAttendance
                          ? 'Recording attendance...'
                          : 'Scan member and mark done',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.slot});

  final Map<String, dynamic> slot;

  @override
  Widget build(BuildContext context) {
    final date = _text(slot['date']);
    final time = [
      _text(slot['start_time']),
      _text(slot['end_time']),
    ].where((item) => item.isNotEmpty).join(' - ');
    final bookingCount = _text(slot['booking_count']);
    final capacity = _text(slot['capacity']);
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_rounded, color: AppPalette.navy),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayDate(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(time, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (bookingCount.isNotEmpty || capacity.isNotEmpty)
            Text(
              '${bookingCount.isEmpty ? '0' : bookingCount}/${capacity.isEmpty ? '-' : capacity}',
              style: const TextStyle(
                color: AppPalette.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.api,
    required this.sessionStore,
  });

  final ApiClient api;
  final SessionStore sessionStore;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.api.profile();
  }

  Future<void> _reload() async {
    setState(() => _profile = widget.api.profile());
    await _profile;
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your saved trainer session will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.sessionStore.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.api.session;
    return FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const <String, dynamic>{};
        final name = _text(profile['name'], fallback: session.name);
        final memberId = _text(
          profile['member_id'],
          fallback: session.memberId,
        );
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              const _PageIntro(
                eyebrow: 'ACCOUNT',
                title: 'Your profile',
                subtitle: 'Trainer account and connection details.',
              ),
              const SizedBox(height: 22),
              _ProfileHero(
                name: name,
                memberId: memberId,
                login: session.login,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _LoadingList(compact: true)
              else if (snapshot.hasError)
                _ErrorCard(
                  message: _errorText(snapshot.error),
                  onRetry: _reload,
                )
              else
                _ProfileDetails(profile: profile, session: session),
              const SizedBox(height: 20),
              _WhiteCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _signOut,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFB73535)),
                        SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            'Sign out',
                            style: TextStyle(
                              color: Color(0xFFB73535),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFB73535),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.memberId,
    required this.login,
  });

  final String name;
  final String memberId;
  final String login;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.navy, AppPalette.navyBright],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: AppPalette.navy,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  memberId.isEmpty ? login : memberId,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.76)),
                ),
                const SizedBox(height: 10),
                const _TypePill(label: 'TRAINER', dark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile, required this.session});

  final Map<String, dynamic> profile;
  final TrainerSession session;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ProfileRowData(
        Icons.badge_outlined,
        'Member ID',
        _text(profile['member_id'], fallback: session.memberId),
      ),
      _ProfileRowData(
        Icons.alternate_email_rounded,
        'Email',
        _text(profile['email'], fallback: session.login),
      ),
      _ProfileRowData(
        Icons.phone_outlined,
        'Phone',
        _text(profile['phone'], fallback: 'Not provided'),
      ),
      _ProfileRowData(Icons.numbers_rounded, 'User ID', '${session.userId}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _WhiteCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                _ProfileRow(data: rows[index]),
                if (index != rows.length - 1)
                  const Divider(height: 1, indent: 58),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Connection', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _WhiteCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileRow(
                data: _ProfileRowData(
                  Icons.language_rounded,
                  'Base URL',
                  session.baseUrl,
                ),
              ),
              const Divider(height: 1, indent: 58),
              _ProfileRow(
                data: _ProfileRowData(
                  Icons.storage_outlined,
                  'Database',
                  session.database,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRowData {
  const _ProfileRowData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.data});

  final _ProfileRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(
        children: [
          Icon(data.icon, color: AppPalette.navy),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              data.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              data.value.isEmpty ? 'Not provided' : data.value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppPalette.navyBright,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 7),
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12071A33),
            blurRadius: 13,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFEAF2FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : AppPalette.navy,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 96 : 220,
      child: const Center(
        child: CircularProgressIndicator(color: AppPalette.navy),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 20 : 36,
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppPalette.navy),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: AppPalette.navy,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load this page',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showSuccess(
  BuildContext context, {
  required String title,
  required MemberScan member,
  required String detail,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.check_circle_rounded,
        color: AppPalette.success,
        size: 42,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            member.memberId,
            style: const TextStyle(
              color: AppPalette.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _resultDetail(Map<String, dynamic> result, {required String fallback}) {
  for (final key in ['message', 'detail', 'package_name']) {
    final value = _text(result[key]);
    if (value.isNotEmpty) return value;
  }
  final remaining = _text(result['remaining_sessions']);
  return remaining.isEmpty
      ? fallback
      : '$fallback Remaining sessions: $remaining.';
}

String _errorText(Object? error) => error is ApiFailure
    ? error.message
    : 'Check your internet connection and try again.';

String _text(dynamic value, {String fallback = ''}) {
  if (value == null || value == false) return fallback;
  return value.toString();
}

int? _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _scheduleLineLabel(Map<String, dynamic> line) {
  final day = _text(line['day_of_week'], fallback: 'Schedule');
  final start = _text(line['start_time']);
  final end = _text(line['end_time']);
  return [day, if (start.isNotEmpty) start, if (end.isNotEmpty) end].join(' ');
}

String _displayDate(String value) {
  final date = DateTime.tryParse(value);
  return date == null
      ? (value.isEmpty ? 'Scheduled session' : value)
      : _longDate(date);
}

String _longDate(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
