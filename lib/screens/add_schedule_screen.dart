import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _selectedIcon = "💊";
  String _selectedType = "Tablet";
  bool _remindMe = true;
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _icons = ["💊", "🧪", "🍎", "🏃", "💼", "💧"];
  final List<String> _types = ["Tablet", "Capsule", "Syrup", "Injection", "Activity"];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Schedule", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 24),
            const Text("Choose icon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField("Name of task", _nameController, "Type here..."),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildTextField("Dosage / Info", _dosageController, "e.g. 1 task")),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Type", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _types.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Icon(Icons.access_time, color: AppTheme.primaryTeal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Remind me", style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _remindMe,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) => setState(() => _remindMe = val),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) return;
                
                final now = DateTime.now();
                final scheduledDateTime = DateTime(
                  now.year, now.month, now.day,
                  _selectedTime.hour, _selectedTime.minute,
                );

                final newSchedule = Schedule(
                  id: const Uuid().v4(),
                  name: _nameController.text,
                  time: scheduledDateTime,
                  icon: _selectedIcon,
                  isEnabled: _remindMe,
                  type: _selectedType,
                  dosage: _dosageController.text,
                );

                await Provider.of<ScheduleProvider>(context, listen: false).addSchedule(newSchedule);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Add schedule"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
