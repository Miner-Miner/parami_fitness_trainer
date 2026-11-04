import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../theme/theme_picker.dart';
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
  static const destinations = [
    ('Customers', Icons.groups_outlined),
    ('QR scan', Icons.qr_code_scanner),
    ('Classes', Icons.calendar_month_outlined),
    ('Profile', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final style = AppPalette.of(context);
    final theme = style.variant;
    final session = widget.sessionStore.session!;
    final api = ApiClient(session);
    final pages = [
      CustomersScreen(api: api),
      SessionScanScreen(api: api),
      ClassesScreen(api: api),
      ProfileScreen(api: api, sessionStore: widget.sessionStore),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        title: const BrandHeader(),
        actions: [
          ThemePickerButton(sessionStore: widget.sessionStore, onDark: true),
        ],
      ),
      drawer: theme != TrainerTheme.roseGold
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Trainer workspace'),
                    ),
                    for (final (index, label, icon) in [
                      (0, 'Customers', Icons.groups_outlined),
                      (1, 'QR scan', Icons.qr_code_scanner),
                      (2, 'Classes', Icons.calendar_month_outlined),
                      (3, 'Profile', Icons.person_outline),
                    ])
                      ListTile(
                        leading: Icon(icon),
                        title: Text(label),
                        selected: _index == index,
                        onTap: () {
                          setState(() => _index = index);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: theme == TrainerTheme.monochrome
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(icon: Icon(item.$2), label: item.$1),
              ],
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (theme == TrainerTheme.gold)
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        minWidth: 64,
                        extended: MediaQuery.sizeOf(context).width >= 900,
                        labelType: MediaQuery.sizeOf(context).width >= 900
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.selected,
                        selectedIndex: _index,
                        onDestinationSelected: (index) =>
                            setState(() => _index = index),
                        destinations: [
                          for (final item in destinations)
                            NavigationRailDestination(
                              icon: Icon(item.$2),
                              label: Text(item.$1),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              key: const ValueKey('workspace-pages'),
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
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
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              _PageIntro(
                eyebrow: 'TRAINER ROSTER',
                title: 'Your customers',
                subtitle:
                    'Members assigned to your personal training sessions.',
              ),
              SizedBox(height: 22),
              if (snapshot.connectionState == ConnectionState.waiting)
                _LoadingList()
              else if (snapshot.hasError)
                _ErrorCard(
                  message: _errorText(snapshot.error),
                  onRetry: _reload,
                )
              else if (customers.isEmpty)
                _EmptyCard(
                  icon: Icons.groups_outlined,
                  title: 'No customers assigned yet',
                  detail:
                      'Assigned personal-training customers will appear here.',
                )
              else ...[
                _RosterCount(count: customers.length),
                SizedBox(height: 14),
                ...customers.map(
                  (customer) => Padding(
                    padding: EdgeInsets.only(bottom: 10),
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
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppPalette.of(context).mist,
              borderRadius: BorderRadius.circular(
                AppPalette.of(context).radius,
              ),
            ),
            child: Icon(
              Icons.people_alt_outlined,
              color: AppPalette.of(context).foregroundAccent,
            ),
          ),
          SizedBox(width: 13),
          Text('$count', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(width: 7),
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
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppPalette.of(context).navyBright,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 3),
                Text(
                  memberId.isEmpty ? 'User ID: $userId' : memberId,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppPalette.of(context).steel,
          ),
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
        builder: (_) => MemberScannerPage(
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
      padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        _PageIntro(
          eyebrow: 'SESSION CHECK-IN',
          title: 'Scan. Confirm. Train.',
          subtitle:
              'Use a member QR code to consume one personal-training session.',
        ),
        SizedBox(height: 28),
        Container(
          height: 274,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.of(context).navy,
                AppPalette.of(context).navyBright,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
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
                padding: EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(
                          AppPalette.of(context).radius,
                        ),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Ready for the next member?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    // Text(
                    //   'The QR must contain both member_id and user_id.',
                    //   style: TextStyle(
                    //     color: Colors.white.withValues(alpha: 0.72),
                    //     height: 1.4,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _scanAndConsume,
          icon: _isSubmitting
              ? SizedBox(
                  height: 19,
                  width: 19,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.center_focus_strong_rounded),
          label: Text(
            _isSubmitting ? 'Recording session...' : 'Start QR scanner',
          ),
        ),
        SizedBox(height: 18),
        _WhiteCard(
          padding: EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppPalette.of(context).foregroundAccent,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If a camera cannot read the code, use the manual entry option in the scanner. Confirm the member ID before continuing.',
                  style: TextStyle(
                    color: AppPalette.of(context).muted,
                    height: 1.45,
                  ),
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
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              _PageIntro(
                eyebrow: 'CLASS PROGRAMME',
                title: 'Your classes',
                subtitle:
                    'Open a class to review its schedule and take attendance.',
              ),
              SizedBox(height: 22),
              if (snapshot.connectionState == ConnectionState.waiting)
                _LoadingList()
              else if (snapshot.hasError)
                _ErrorCard(
                  message: _errorText(snapshot.error),
                  onRetry: _reload,
                )
              else if (classes.isEmpty)
                _EmptyCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'No classes found',
                  detail: 'Classes assigned to this trainer will appear here.',
                )
              else
                ...classes.map(
                  (gymClass) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
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
        borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppPalette.of(context).mist,
                  borderRadius: BorderRadius.circular(
                    AppPalette.of(context).radius,
                  ),
                ),
                child: Icon(
                  classType == 'PAID'
                      ? Icons.workspace_premium_outlined
                      : Icons.fitness_center_outlined,
                  color: AppPalette.of(context).foregroundAccent,
                ),
              ),
              SizedBox(width: 14),
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
                    SizedBox(height: 7),
                    Text(
                      '${schedule.length} ${schedule.length == 1 ? 'schedule' : 'schedules'}  |  ${_text(gymClass['instructor_name'], fallback: 'Trainer')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppPalette.of(context).foregroundAccent,
              ),
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
      dateFrom: now.subtract(Duration(days: 7)),
      dateTo: now.add(Duration(days: 35)),
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
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
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
        builder: (_) => MemberScannerPage(
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
        backgroundColor: AppPalette.of(context).navyBright,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Class details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadSchedule,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppPalette.of(context).navy,
                    AppPalette.of(context).navyBright,
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  AppPalette.of(context).radius,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypePill(label: classType, dark: true),
                  SizedBox(height: 16),
                  Text(
                    _text(gymClass['name'], fallback: 'Untitled class'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Instructor: ${_text(gymClass['instructor_name'], fallback: 'Trainer')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  if (_text(gymClass['capacity']).isNotEmpty) ...[
                    SizedBox(height: 5),
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
            SizedBox(height: 24),
            Text(
              'Upcoming schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _schedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _LoadingList(compact: true);
                }
                if (snapshot.hasError) {
                  return _ErrorCard(
                    message: _errorText(snapshot.error),
                    onRetry: _reloadSchedule,
                  );
                }
                final slots = snapshot.data ?? const <Map<String, dynamic>>[];
                if (slots.isEmpty) {
                  return _EmptyCard(
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
                          padding: EdgeInsets.only(bottom: 9),
                          child: _ScheduleCard(slot: slot),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              'Take attendance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            _WhiteCard(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose the session date before scanning a member.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: Icon(Icons.calendar_today_outlined),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _longDate(_attendanceDate),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.of(context).navyBright,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppPalette.of(context).radius,
                        ),
                      ),
                    ),
                  ),
                  if (_scheduleLines.isNotEmpty) ...[
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedScheduleId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'Class schedule'),
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
                  SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _isMarkingAttendance ? null : _scanAndMarkDone,
                    icon: _isMarkingAttendance
                        ? SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.qr_code_scanner_rounded),
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
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppPalette.of(context).mist,
              borderRadius: BorderRadius.circular(
                AppPalette.of(context).radius,
              ),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: AppPalette.of(context).foregroundAccent,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayDate(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (time.isNotEmpty) ...[
                  SizedBox(height: 3),
                  Text(time, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (bookingCount.isNotEmpty || capacity.isNotEmpty)
            Text(
              '${bookingCount.isEmpty ? '0' : bookingCount}/${capacity.isEmpty ? '-' : capacity}',
              style: TextStyle(
                color: AppPalette.of(context).foregroundAccent,
                fontWeight: FontWeight.w700,
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
        title: Text('Sign out?'),
        content: Text(
          'Your saved trainer session will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign out'),
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
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              _PageIntro(
                eyebrow: 'ACCOUNT',
                title: 'Your profile',
                subtitle: 'Trainer account and connection details.',
              ),
              SizedBox(height: 22),
              _ProfileHero(name: name, login: session.login),
              SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                _LoadingList(compact: true)
              else if (snapshot.hasError)
                _ErrorCard(
                  message: _errorText(snapshot.error),
                  onRetry: _reload,
                )
              else
                _ProfileDetails(profile: profile, session: session),
              SizedBox(height: 20),
              _WhiteCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _signOut,
                  borderRadius: BorderRadius.circular(
                    AppPalette.of(context).radius,
                  ),
                  child: Padding(
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
                              fontWeight: FontWeight.w700,
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
  const _ProfileHero({required this.name, required this.login});

  final String name;
  final String login;

  @override
  Widget build(BuildContext context) {
    final stacked = AppPalette.of(context).rounded;
    return Container(
      padding: EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.of(context).navy,
            AppPalette.of(context).navyBright,
          ],
        ),
        borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
      ),
      child: Flex(
        direction: stacked ? Axis.vertical : Axis.horizontal,
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: AppPalette.of(context).card,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: AppPalette.of(context).foregroundAccent,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
          ),
          SizedBox(width: 15, height: stacked ? 18 : 0),
          Flexible(
            flex: stacked ? 0 : 1,
            child: Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  login,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.76)),
                ),
                SizedBox(height: 10),
                _TypePill(label: 'TRAINER', dark: true),
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
        Icons.alternate_email_rounded,
        'Email',
        _text(profile['email'], fallback: session.login),
      ),
      _ProfileRowData(
        Icons.phone_outlined,
        'Phone',
        _text(profile['phone'], fallback: 'Not provided'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile details', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 10),
        _WhiteCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                _ProfileRow(data: rows[index]),
                if (index != rows.length - 1) Divider(height: 1, indent: 58),
              ],
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
      padding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(
        children: [
          Icon(data.icon, color: AppPalette.of(context).foregroundAccent),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              data.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              data.value.isEmpty ? 'Not provided' : data.value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppPalette.of(context).foregroundAccent,
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
    final style = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [style.ink, style.navyBright],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(style.radius),
      ),
      child: Column(
        crossAxisAlignment: style.rounded
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.7,
            ),
          ),
          SizedBox(height: 7),
          Text(
            title,
            textAlign: style.rounded ? TextAlign.center : TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: style.rounded ? TextAlign.center : TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
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
        color: AppPalette.of(context).card,
        borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
        border: Border.all(color: AppPalette.of(context).line),
        boxShadow: AppPalette.of(context).rounded
            ? const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 13,
                  offset: Offset(0, 5),
                ),
              ]
            : const [],
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.16)
            : AppPalette.of(context).mist,
        borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : AppPalette.of(context).foregroundAccent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
      child: Center(
        child: CircularProgressIndicator(
          color: AppPalette.of(context).foregroundAccent,
        ),
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
          Icon(icon, size: 34, color: AppPalette.of(context).foregroundAccent),
          SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 6),
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
      padding: EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: AppPalette.of(context).foregroundAccent,
          ),
          SizedBox(height: 12),
          Text(
            'Could not load this page',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Try again'),
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
      icon: Icon(
        Icons.check_circle_rounded,
        color: AppPalette.of(context).success,
        size: 42,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            member.memberId,
            style: TextStyle(
              color: AppPalette.of(context).foregroundAccent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 9),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Done'),
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
