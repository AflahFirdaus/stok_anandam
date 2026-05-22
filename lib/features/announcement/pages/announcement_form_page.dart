import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/injection.dart';
import '../../../data/models/announcement.dart';
import '../../../data/repositories/announcement_repository.dart';

class AnnouncementFormPage extends StatefulWidget {
  final Announcement? announcement;

  const AnnouncementFormPage({super.key, this.announcement});

  @override
  State<AnnouncementFormPage> createState() => _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends State<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final AnnouncementRepository _repository = getIt<AnnouncementRepository>();

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;

  DateTime? _startDate;
  DateTime? _expiredDate;

  bool _isLoading = false;

  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.announcement?.title ?? '');
    _subtitleController =
        TextEditingController(text: widget.announcement?.subtitle ?? '');
    _startDate = widget.announcement?.startDate;
    _expiredDate = widget.announcement?.expiredDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final theme = Theme.of(context);
    final initialDate = (isStart ? _startDate : _expiredDate) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: theme.colorScheme.primary,
            onPrimary: theme.colorScheme.onPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) => Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null && mounted) {
        final finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStart) {
            _startDate = finalDateTime;
          } else {
            _expiredDate = finalDateTime;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date logic
    if (_startDate != null &&
        _expiredDate != null &&
        _expiredDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Tanggal berakhir harus setelah tanggal mulai.')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final announcement = Announcement(
      id: widget.announcement?.id,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      startDate: _startDate,
      expiredDate: _expiredDate,
    );

    try {
      if (_isEditing) {
        await _repository.updateAnnouncement(
            widget.announcement!.id!, announcement);
      } else {
        await _repository.createAnnouncement(announcement);
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengumuman: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');

    // Input field decoration factory
    InputDecoration inputDec(String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          prefixIcon:
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
          ),
        );

    Widget datePickerRow({
      required bool isStart,
      required IconData icon,
      required String fieldLabel,
      required DateTime? value,
      required String emptyHint,
    }) {
      return InkWell(
        onTap: () => _pickDateTime(isStart),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value != null
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: value != null
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value != null ? dateFormat.format(value) : emptyHint,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            value != null ? FontWeight.w600 : FontWeight.normal,
                        color: value != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                  ),
                  onPressed: () => setState(() {
                    if (isStart) {
                      _startDate = null;
                    } else {
                      _expiredDate = null;
                    }
                  }),
                  tooltip: 'Hapus jadwal',
                  visualDensity: VisualDensity.compact,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'Pilih',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Pengumuman' : 'Tambah Pengumuman',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(
                  _isEditing ? Icons.save_rounded : Icons.send_rounded,
                  size: 16,
                ),
                label: Text(_isEditing ? 'Simpan' : 'Publikasikan'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _isEditing
                        ? 'Menyimpan perubahan...'
                        : 'Mempublikasikan pengumuman...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── Form Card ─────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow
                                    .withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.edit_note_rounded,
                                      size: 18,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Konten Pengumuman',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Judul dan isi yang akan dilihat pengguna',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Title field
                              TextFormField(
                                controller: _titleController,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                decoration: inputDec(
                                    'Judul Pengumuman', Icons.title_rounded),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Judul wajib diisi'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Subtitle/content field
                              TextFormField(
                                controller: _subtitleController,
                                maxLines: 6,
                                minLines: 4,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  height: 1.55,
                                ),
                                decoration: inputDec(
                                  'Isi Pengumuman',
                                  Icons.description_rounded,
                                ).copyWith(
                                  alignLabelWithHint: true,
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 80),
                                    child: Icon(Icons.description_rounded,
                                        size: 20),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Isi pengumuman wajib diisi'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ─── Schedule Card ──────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow
                                    .withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jadwal Publikasi',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Opsional — kosongkan untuk langsung aktif selamanya',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Start date picker
                              datePickerRow(
                                isStart: true,
                                icon: Icons.play_arrow_rounded,
                                fieldLabel: 'MULAI DITAMPILKAN',
                                value: _startDate,
                                emptyHint: 'Langsung dipublikasikan',
                              ),
                              const SizedBox(height: 12),

                              // End date picker
                              datePickerRow(
                                isStart: false,
                                icon: Icons.stop_rounded,
                                fieldLabel: 'BERAKHIR / KEDALUWARSA',
                                value: _expiredDate,
                                emptyHint: 'Aktif selamanya (tanpa batas)',
                              ),

                              // Validation warning if dates conflict
                              if (_startDate != null &&
                                  _expiredDate != null &&
                                  _expiredDate!.isBefore(_startDate!)) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          size: 16,
                                          color: theme.colorScheme.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Tanggal berakhir harus setelah tanggal mulai.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── Save Button ────────────────────────────────────
                        SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _save,
                            icon: Icon(
                              _isEditing
                                  ? Icons.save_rounded
                                  : Icons.send_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _isEditing
                                  ? 'Simpan Perubahan'
                                  : 'Publikasikan Pengumuman',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        // Cancel button
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
