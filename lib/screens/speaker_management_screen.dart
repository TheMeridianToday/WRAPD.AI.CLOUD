// Speaker Management Screen
// UI for managing speaker profiles and voice diarization

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/voice_diarization_service.dart';
import '../models/speaker_profile_model.dart';
import '../widgets/shared_components.dart';

class SpeakerManagementScreen extends StatefulWidget {
  const SpeakerManagementScreen({super.key});

  @override
  State<SpeakerManagementScreen> createState() => _SpeakerManagementScreenState();
}

class _SpeakerManagementScreenState extends State<SpeakerManagementScreen> {
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final TextEditingController _newSpeakerNameController = TextEditingController();
  final Uuid _uuid = const Uuid();
  
  bool _isDiarizationActive = false;
  List<VoiceProfile> _speakers = [];
  List<SpeakerDiarizationResult> _currentSegments = [];
  StreamSubscription<List<VoiceProfile>>? _speakersSubscription;
  StreamSubscription<SpeakerDiarizationResult>? _diarizationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _voiceService.initialize();
    setState(() {
      _speakers = _voiceService.speakerProfiles;
    });
    
    // Listen for speaker updates
    _speakersSubscription = _voiceService.speakersStream.listen((speakers) {
      if (mounted) {
        setState(() {
          _speakers = speakers;
        });
      }
    });
    
    // Listen for diarization results
    _diarizationSubscription = _voiceService.diarizationStream.listen((result) {
      if (mounted) {
        setState(() {
          _currentSegments.add(result);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker Management'),
        actions: [
          IconButton(
            icon: Icon(_isDiarizationActive ? Icons.stop : Icons.mic),
            onPressed: _toggleDiarization,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Profiles'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Profiles'),
              ),
            ],
            onSelected: _handleMenuSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          // Diarization Status
          _buildDiarizationStatus(),
          
          // Current Segments
          if (_isDiarizationActive) _buildCurrentSegments(),
          
          // Speaker Profiles
          Expanded(
            child: _buildSpeakerList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSpeakerDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildDiarizationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _isDiarizationActive ? Colors.green.shade100 : Colors.grey.shade200,
      child: Row(
        children: [
          Icon(
            _isDiarizationActive ? Icons.mic : Icons.mic_off,
            color: _isDiarizationActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isDiarizationActive 
                  ? 'Speaker Diarization Active - Detecting ${_speakers.length} speakers'
                  : 'Speaker Diarization Inactive',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isDiarizationActive ? Colors.green : Colors.grey,
              ),
            ),
          ),
          Text(_currentSegments.length.toString()),
        ],
      ),
    );
  }

  Widget _buildCurrentSegments() {
    if (_currentSegments.isEmpty) {
      return Container();
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _currentSegments.length,
        itemBuilder: (context, index) {
          final segment = _currentSegments[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  segment.speakerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${segment.duration.inSeconds}s',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeakerList() {
    return _speakers.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.record_voice_over,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No speaker profiles yet',
                  style: TextStyle(fontSize: 18),
                ),
                const Text(
                  'Add speakers to start voice recognition',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _speakers.length,
            itemBuilder: (context, index) {
              final speaker = _speakers[index];
              return _buildSpeakerCard(speaker);
            },
          );
  }

  Widget _buildSpeakerCard(VoiceProfile speaker) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(speaker.colorTag),
          child: Text(
            speaker.displayName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(speaker.displayName),
        subtitle: Text(
          'Used ${speaker.usageCount} times • ${speaker.gender.name}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditSpeakerDialog(speaker),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(speaker),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.green; // Default color
    }
  }

  Future<void> _toggleDiarization() async {
    if (_isDiarizationActive) {
      await _voiceService.stopDiarization();
      setState(() {
        _isDiarizationActive = false;
        _currentSegments.clear();
      });
    } else {
      final success = await _voiceService.startDiarization();
      if (success) {
        setState(() {
          _isDiarizationActive = true;
          _currentSegments.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start diarization')),
        );
      }
    }
  }

  void _showAddSpeakerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Speaker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newSpeakerNameController,
              decoration: const InputDecoration(
                labelText: 'Speaker Name',
                hintText: 'Enter speaker name',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SpeakerGender>(
              value: SpeakerGender.nonBinary,
              items: SpeakerGender.values.map((gender) => 
                DropdownMenuItem(
                  value: gender,
                  child: Text(gender.name),
                )
              ).toList(),
              onChanged: (_) {},
              decoration: const InputDecoration(
                labelText: 'Gender',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _newSpeakerNameController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addSpeaker,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSpeakerDialog(VoiceProfile speaker) {
    final controller = TextEditingController(text: speaker.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Speaker'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Speaker Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _voiceService.renameSpeaker(speaker.id, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(VoiceProfile speaker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Speaker'),
        content: Text('Are you sure you want to delete "${speaker.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _voiceService.removeSpeakerProfile(speaker.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addSpeaker() {
    final name = _newSpeakerNameController.text.trim();
    if (name.isNotEmpty) {
      final newProfile = VoiceProfile(
        id: _uuid.v4(),
        name: name,
        gender: SpeakerGender.nonBinary,
      );
      
      _voiceService.addSpeakerProfile(newProfile);
      _newSpeakerNameController.clear();
      Navigator.of(context).pop();
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'export':
        _exportProfiles();
        break;
      case 'import':
        _importProfiles();
        break;
    }
  }

  Future<void> _exportProfiles() async {
    final jsonData = await _voiceService.exportSpeakerProfiles();
    // TODO: Implement actual export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${_speakers.length} profiles')),
    );
  }

  Future<void> _importProfiles() async {
    // TODO: Implement actual import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon')),
    );
  }

  @override
  void dispose() {
    _speakersSubscription?.cancel();
    _diarizationSubscription?.cancel();
    _newSpeakerNameController.dispose();
    // Do NOT call _voiceService.dispose() — it is a global singleton.
    // Disposing it would permanently close its stream controllers and
    // break every future use of VoiceRecognitionService in the app.
    super.dispose();
  }
}
