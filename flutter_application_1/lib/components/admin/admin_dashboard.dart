import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<User> _users = [];
  String _searchQuery = '';

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await getUsers();
    if (mounted) {
      setState(() {
        _users = users;
      });
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      return user.username.toLowerCase().contains(query) ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, int> get _stats {
    return {
      'admin': _users.where((u) => u.role == 'admin').length,
      'teacher': _users.where((u) => u.role == 'teacher').length,
      'student': _users.where((u) => u.role == 'student').length,
    };
  }

  String _roleLabel(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return context.t('admin');
      case 'teacher':
        return context.t('teacher');
      case 'student':
        return context.t('student');
      default:
        return role;
    }
  }

  void _showUserDialog({User? user}) {
    final isEditing = user != null;

    if (isEditing) {
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _passwordController.clear();
      _selectedRole = user.role;
    } else {
      _fullNameController.clear();
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = 'student';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? context.t('edit_account') : context.t('add_account_new')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(labelText: context.t('full_name')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: context.t('username')),
                    enabled: !isEditing,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: isEditing ? context.t('password_optional_unchanged') : context.t('password'),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.t('role'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'student', child: Text(context.t('student'))),
                          DropdownMenuItem(value: 'teacher', child: Text(context.t('teacher'))),
                          DropdownMenuItem(value: 'admin', child: Text(context.t('admin'))),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => _selectedRole = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.t('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _handleSubmit(user);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(isEditing ? context.t('update') : context.t('add_new')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit(User? editingUser) async {
    if (editingUser != null) {
      final updates = {
        'email': _emailController.text,
        'fullName': _fullNameController.text,
        'role': _selectedRole,
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
      };
      await updateUser(editingUser.id, updates);
    } else {
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: _usernameController.text,
        password: _passwordController.text,
        email: _emailController.text,
        fullName: _fullNameController.text,
        role: _selectedRole,
        createdAt: DateTime.now().toIso8601String(),
      );
      await addUser(newUser);
    }
    await _loadUsers();
  }

  Future<void> _handleDelete(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('confirm')),
        content: Text(context.t('delete_account_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteUser(user.id);
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color getRoleColor(String role) {
      switch (role) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('manage_accounts'),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('manage_accounts_desc'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchField(context),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showUserDialog(),
                                icon: const Icon(Icons.person_add),
                                label: Text(context.t('add_account')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(child: _buildSearchField(context)),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showUserDialog(),
                                icon: const Icon(Icons.person_add),
                                label: Text(context.t('add_account')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        if (isMobile)
                          Column(
                            children: [
                              _buildStatCard(context.t('admin'), _stats['admin']!, Colors.purple, Icons.admin_panel_settings),
                              const SizedBox(height: 16),
                              _buildStatCard(context.t('teacher'), _stats['teacher']!, Colors.blue, Icons.school),
                              const SizedBox(height: 16),
                              _buildStatCard(context.t('student'), _stats['student']!, Colors.green, Icons.people),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(context.t('admin'), _stats['admin']!, Colors.purple, Icons.admin_panel_settings)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(context.t('teacher'), _stats['teacher']!, Colors.blue, Icons.school)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(context.t('student'), _stats['student']!, Colors.green, Icons.people)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: isMobile ? 600 : constraints.maxWidth - 48),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                        columns: [
                          DataColumn(label: Text(context.t('full_name').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('USERNAME', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.t('role').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.t('action').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredUsers.map((user) {
                          final roleColor = getRoleColor(user.role);
                          return DataRow(cells: [
                            DataCell(Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(user.username)),
                            DataCell(Text(user.email)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _roleLabel(context, user.role),
                                  style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                    onPressed: () => _showUserDialog(user: user),
                                    tooltip: context.t('edit'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _handleDelete(user),
                                    tooltip: context.t('delete'),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: context.t('search'),
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(count.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: color, size: 32),
        ],
      ),
    );
  }
}
