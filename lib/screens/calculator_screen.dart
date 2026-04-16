// screens/calculator_screen.dart
// AppBar: logo + Expanded title only — no badge crowding the row

import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/cosmo_logo.dart';
import 'tabs/leak_rate_tab.dart';
import 'tabs/volume_tab.dart';
import 'tabs/pressure_tab.dart';
import 'tabs/time_tab.dart';
import 'tabs/temperature_tab.dart';
import 'tabs/leak_master_tab.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;

  static const _tabs = [
    _T('Leak Rate', Icons.water_drop_outlined,             Icons.water_drop),
    _T('Volume',    Icons.view_in_ar_outlined,              Icons.view_in_ar),
    _T('Pressure',  Icons.compress_outlined,                Icons.compress),
    _T('Time',      Icons.timer_outlined,                   Icons.timer),
    _T('Temp ΔP',   Icons.thermostat_outlined,              Icons.thermostat),
    _T('LM Select', Icons.precision_manufacturing_outlined, Icons.precision_manufacturing),
  ];

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: _tabs.length, vsync: this);
    _tc.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tc,
        children: const [
          LeakRateTab(), VolumeTab(), PressureDropTab(),
          TimeTab(), TemperatureTab(), LeakMasterTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(116),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header row — logo + title, logo sized for legibility
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const CosmoAppBarLogo(height: 38),   // wide rectangle, text legible
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Calculator',
                          style: TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text('Industrial Leak Testing',
                          style: TextStyle(color: Colors.white.withOpacity(0.75),
                              fontSize: 11, letterSpacing: 0.6),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
              ]),
            ),

            // Scrollable tab bar
            TabBar(
              controller:     _tc,
              isScrollable:   true,
              tabAlignment:   TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize:  TabBarIndicatorSize.label,
              labelColor:     Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.55),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final active = _tc.index == i;
                return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(active ? t.activeIcon : t.icon, size: 15),
                  const SizedBox(width: 5),
                  Text(t.label),
                ]));
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

class _T {
  final String label;
  final IconData icon, activeIcon;
  const _T(this.label, this.icon, this.activeIcon);
}
