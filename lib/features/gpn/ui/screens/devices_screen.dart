import 'package:flutter/material.dart';
import '../api/gpn_client.dart';
import '../widgets/gpn_card.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.client});

  final GpnClient client;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  GpnDevicesResponse? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.client.fetchDevices();
      if (!mounted) return;
      setState(() => _data = data);
    } on GpnApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось загрузить устройства');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDevice() async {
    final label = await _promptLabel(context, title: 'Новое устройство', initial: '');
    if (label == null || label.isEmpty) return;
    try {
      await widget.client.addDevice(label);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Устройство добавлено')),
      );
      await _reload();
    } on GpnApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _renameDevice(GpnDevice d) async {
    final label = await _promptLabel(context, title: 'Переименовать', initial: d.label);
    if (label == null || label.isEmpty || label == d.label) return;
    try {
      await widget.client.renameDevice(d.id, label);
      await _reload();
    } on GpnApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteDevice(GpnDevice d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить устройство?'),
        content: Text(d.label.isNotEmpty ? d.label : 'ID ${d.id}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.client.deleteDevice(d.id);
      await _reload();
    } on GpnApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final canAdd = data != null && data.slotsUsed < data.slotsMax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Устройства'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _addDevice,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GpnCard(
                        child: Text(
                          'Слоты: ${data!.slotsUsed} / ${data.slotsMax}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (data.devices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Нет устройств. Нажмите «Добавить», чтобы занять слот.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        ...data.devices.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GpnCard(
                              child: Row(
                                children: [
                                  const Icon(Icons.smartphone, color: Color(0xFF8B5CF6)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.label.isNotEmpty ? d.label : 'Устройство #${d.id}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (d.lastSeenAt.isNotEmpty)
                                          Text(
                                            'активность: ${d.lastSeenAt.substring(0, 10)}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _renameDevice(d),
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteDevice(d),
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

Future<String?> _promptLabel(
  BuildContext context, {
  required String title,
  required String initial,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Имя устройства',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
