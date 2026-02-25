import 'package:flutter/material.dart';
import '../types/index.dart';
import '../l10n/app_text.dart';

class Layout extends StatelessWidget {
  final User user;
  final Widget child;
  final String currentView;
  final Function(String) onViewChange;
  final VoidCallback onLogout;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChange;

  const Layout({
    super.key,
    required this.user,
    required this.child,
    required this.currentView,
    required this.onViewChange,
    required this.onLogout,
    required this.locale,
    required this.onLocaleChange,
  });

  List<Map<String, dynamic>> _menuItems(BuildContext context) {
    switch (user.role) {
      case 'admin':
        return [
          {'id': 'accounts', 'label': context.t('manage_accounts'), 'icon': Icons.people},
        ];
      case 'teacher':
        return [
          {'id': 'classes', 'label': context.t('manage_classes'), 'icon': Icons.dashboard},
          {'id': 'questions', 'label': context.t('question_bank'), 'icon': Icons.book},
          {'id': 'exams', 'label': context.t('manage_exams'), 'icon': Icons.description},
          {'id': 'statistics', 'label': context.t('statistics_report'), 'icon': Icons.bar_chart},
        ];
      case 'student':
        return [
          {'id': 'exam-list', 'label': context.t('exam_list'), 'icon': Icons.assignment},
          {'id': 'history', 'label': context.t('exam_history'), 'icon': Icons.history},
        ];
      default:
        return [];
    }
  }

  String _roleName(BuildContext context) {
    switch (user.role) {
      case 'admin':
        return context.t('admin');
      case 'teacher':
        return context.t('teacher');
      case 'student':
        return context.t('student');
      default:
        return '';
    }
  }

  Color get _roleColor {
    switch (user.role) {
      case 'admin':
        return Colors.purple;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('logout')),
        content: Text(context.t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onLogout();
    }
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(context.t('group_info')),
          ],
        ),
        content: const SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Pham Hong Duc',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text('23010338@st.phenikaa-uni.edu.vn'),
              SizedBox(height: 12),
              Text(
                '2. Nguyen Thanh Long',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text('23010xxx@st.phenikaa-uni.edu.vn'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Row(
          children: [
            SizedBox(
              width: 280,
              child: _buildSidebarContent(context, isMobile: false),
            ),
            Expanded(child: child),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showDeveloperInfo(context),
          child: const Icon(Icons.info_outline),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ExamSystem',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: Drawer(
        child: _buildSidebarContent(context, isMobile: true),
      ),
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeveloperInfo(context),
        child: const Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildLanguagePicker(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.language, size: 18, color: Colors.indigo),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.t('language'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DropdownButton<Locale>(
          value: locale,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(
              value: const Locale('vi'),
              child: Text(context.t('vietnamese')),
            ),
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(context.t('english')),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onLocaleChange(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isMobile}) {
    final menuItems = _menuItems(context);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ExamSystem',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  Text(
                    context.t('system_subtitle'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Center(
                child: Text(
                  'ExamSystem',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roleName(context),
                          style: TextStyle(fontSize: 10, color: _roleColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: menuItems.map((item) {
                final isSelected = currentView == item['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: isSelected ? Colors.indigo : Colors.transparent,
                      onTap: () {
                        onViewChange(item['id'] as String);
                        if (isMobile) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: _buildLanguagePicker(context),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: TextButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(
                context.t('logout'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
