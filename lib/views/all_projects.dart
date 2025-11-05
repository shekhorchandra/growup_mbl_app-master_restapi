import 'package:flutter/material.dart';
import 'package:growup_agro/views/Total_projects.dart';
import 'package:growup_agro/views/long_duration.dart';
import 'package:growup_agro/views/live.dart';
import 'package:growup_agro/views/short_duration.dart';
import 'package:growup_agro/views/completed_projects.dart';

class AllProjectsPage extends StatefulWidget {
  const AllProjectsPage({Key? key}) : super(key: key);

  @override
  _AllProjectsPageState createState() => _AllProjectsPageState();
}

class _AllProjectsPageState extends State<AllProjectsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        title: const Text(
          'All Projects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 15),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Long'),
            Tab(text: 'Short'),
            Tab(text: 'Matured'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LiveProjectsPage(hideAppBar: true),
          LongProjectsPage(hideAppBar: true),
          ShortProjectsPage(hideAppBar: true),
          CompletedProjectsPage(hideAppBar: true),
          TotalProjectsPage(hideAppBar: true),
        ],
      ),
    );
  }
}
