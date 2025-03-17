import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatsGrid(),
              const SizedBox(height: 24),
              const Text(
                '鎴戠殑鍒楄〃',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const TodoLists(),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: '浠婂ぉ',
          count: '2',
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
        StatCard(
          title: '璁″垝',
          count: '6',
          icon: Icons.list_alt,
          color: Colors.red,
        ),
        StatCard(
          title: '鍏ㄩ儴',
          count: '6',
          icon: Icons.folder,
          color: Colors.black87,
        ),
        StatCard(
          title: '瀹屾垚',
          count: '',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => title == '今天'
                ? const TodayTasksPage()
                : TaskDetailPage(
                    title: title,
                    icon: icon,
                    color: color,
                    type: 'stat',
                  ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (count.isNotEmpty)
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TodoLists extends StatelessWidget {
  const TodoLists({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_none, color: Colors.blue),
          title: const Text('鎻愰啋浜嬮」'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '4',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskDetailPage(
                  title: '鎻愰啋浜嬮」',
                  icon: Icons.notifications_none,
                  color: Colors.blue,
                  type: 'list',
                ),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_month, color: Colors.red),
          title: const Text('鏈?鏉ヨ?″垝'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '2',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskDetailPage(
                  title: '鏈?鏉ヨ?″垝',
                  icon: Icons.calendar_month,
                  color: Colors.red,
                  type: 'list',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TaskDetailPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String type;

  const TaskDetailPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add task functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type == 'stat' ? '绋嬭?惧ぇ浣滀笟' : '鍐欎綔涓?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: 0, // TODO: Replace with actual task count
                itemBuilder: (context, index) {
                  return const SizedBox(); // TODO: Replace with actual task item
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add task functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodayTasksPage extends StatelessWidget {
  const TodayTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('今天'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTimeSection('上午', '09:00', [
            _buildTaskItem('写作业', '09:00'),
          ]),
          const SizedBox(height: 24),
          _buildTimeSection('下午', '15:00', [
            _buildTaskItem('开会', '15:00'),
          ]),
          const SizedBox(height: 24),
          _buildTimeSection('今晚', '18:00', [
            _buildTaskItem('跑步', '18:00'),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add task functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimeSection(String title, String time, List<Widget> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks,
      ],
    );
  }

  Widget _buildTaskItem(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.radio_button_unchecked, color: Colors.blue),
        title: Text(title),
        subtitle: Text(
          time,
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () {
          // TODO: Implement task toggle
        },
      ),
    );
  }
}
