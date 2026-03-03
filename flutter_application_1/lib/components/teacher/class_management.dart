import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class ClassManagement extends StatefulWidget {
  const ClassManagement({super.key});

  @override
  State<ClassManagement> createState() => _ClassManagementState();
}

class _ClassManagementState extends State<ClassManagement> {
  List<Class> _classes = [];
  List<User> _allStudents = [];
  User? _currentUser;
  final _classNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await getCurrentUser();
    final allClasses = await getClasses();
    final allUsers = await getUsers();

    if (mounted) {
      setState(() {
        _currentUser = user;
        if (user != null) {
          _classes = allClasses.where((c) => c.teacherId == user.id).toList();
        }
        _allStudents = allUsers.where((u) => u.role == 'student').toList();
      });
    }
  }

  void _handleOpenClassDialog({Class? cls}) {
    if (cls != null) {
      _classNameController.text = cls.name;
    } else {
      _classNameController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cls != null ? context.t('edit_class_name') : context.t('create_new_class')),
        content: TextField(
          controller: _classNameController,
          decoration: InputDecoration(
            labelText: context.t('class_name'),
            hintText: context.t('class_name_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_classNameController.text.isNotEmpty) {
                await _handleSubmitClass(cls);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: Text(cls != null ? context.t('update') : context.t('create_class')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitClass(Class? editingClass) async {
    if (_currentUser == null) return;

    if (editingClass != null) {
      await updateClass(editingClass.id, {'name': _classNameController.text});
    } else {
      final newClass = Class(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _classNameController.text,
        teacherId: _currentUser!.id,
        studentIds: [],
        createdAt: DateTime.now().toIso8601String(),
      );
      await addClass(newClass);
    }
    await _loadData();
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('confirm')),
        content: Text(context.t('delete_class_confirm')),
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
      await deleteClass(id);
      await _loadData();
    }
  }

  void _handleManageStudents(Class cls) {
    showDialog(
      context: context,
      builder: (context) => _StudentManagementDialog(
        currentClass: cls,
        allStudents: _allStudents,
        onUpdate: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('manage_classes'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(context.t('create_and_manage_classes'), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handleOpenClassDialog(),
              icon: const Icon(Icons.add),
              label: Text(context.t('create_new_class')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            if (_classes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(context.t('no_classes_yet'), style: const TextStyle(color: Colors.grey)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400.0,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: _classes.length,
                itemBuilder: (context, index) {
                  final cls = _classes[index];
                  return Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cls.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                context.t('students_count', args: {'value': cls.studentIds.length.toString()}),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleManageStudents(cls),
                                  icon: const Icon(Icons.person_add, size: 16),
                                  label: Text(context.t('manage_students_short'), style: const TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _handleOpenClassDialog(cls: cls),
                                tooltip: context.t('edit'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _handleDelete(cls.id),
                                tooltip: context.t('delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentManagementDialog extends StatefulWidget {
  final Class currentClass;
  final List<User> allStudents;
  final VoidCallback onUpdate;

  const _StudentManagementDialog({
    required this.currentClass,
    required this.allStudents,
    required this.onUpdate,
  });

  @override
  State<_StudentManagementDialog> createState() => _StudentManagementDialogState();
}

class _StudentManagementDialogState extends State<_StudentManagementDialog> {
  late Class _cls;

  @override
  void initState() {
    super.initState();
    _cls = widget.currentClass;
  }

  Future<void> _handleAddStudent(String studentId) async {
    if (!_cls.studentIds.contains(studentId)) {
      final newIds = [..._cls.studentIds, studentId];
      await updateClass(_cls.id, {'studentIds': newIds});

      if (mounted) {
        setState(() {
          _cls = _cls.copyWith(studentIds: newIds);
        });
        widget.onUpdate();
      }
    }
  }

  Future<void> _handleRemoveStudent(String studentId) async {
    final newIds = _cls.studentIds.where((id) => id != studentId).toList();
    await updateClass(_cls.id, {'studentIds': newIds});

    if (mounted) {
      setState(() {
        _cls = _cls.copyWith(studentIds: newIds);
      });
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStudents = widget.allStudents.where((s) => !_cls.studentIds.contains(s.id)).toList();
    final enrolledStudents = widget.allStudents.where((s) => _cls.studentIds.contains(s.id)).toList();

    return AlertDialog(
      title: Text(context.t('manage_students_title', args: {'name': _cls.name})),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(context.t('add_students_to_class'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: availableStudents.isEmpty
                    ? Center(child: Text(context.t('all_students_added'), style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: availableStudents.length,
                        itemBuilder: (ctx, idx) {
                          final s = availableStudents[idx];
                          return ListTile(
                            title: Text(s.fullName),
                            subtitle: Text(s.email),
                            trailing: ElevatedButton(
                              onPressed: () => _handleAddStudent(s.id),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: Text(context.t('add')),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('student_list_in_class', args: {'value': enrolledStudents.length.toString()}),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: enrolledStudents.isEmpty
                    ? Center(child: Text(context.t('no_students'), style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: enrolledStudents.length,
                        itemBuilder: (ctx, idx) {
                          final s = enrolledStudents[idx];
                          return ListTile(
                            title: Text(s.fullName),
                            subtitle: Text(s.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _handleRemoveStudent(s.id),
                              tooltip: context.t('remove_from_class'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('close'))),
      ],
    );
  }
}
