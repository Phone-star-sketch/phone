import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SoundSelectionSheet extends StatefulWidget {
  final Function(String) onSoundSelected;

  const SoundSelectionSheet({super.key, required this.onSoundSelected});

  @override
  State<SoundSelectionSheet> createState() => _SoundSelectionSheetState();
}

class _SoundSelectionSheetState extends State<SoundSelectionSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedSound;

  final List<Map<String, dynamic>> _sounds = [
    {
      'name': 'صوت تسديد 1',
      'path': 'sounds/payment.mp3',
      'icon': FontAwesomeIcons.music,
      'color': Colors.blue,
    },
    {
      'name': 'صوت تسديد 2',
      'path': 'sounds/payment.wav',
      'icon': FontAwesomeIcons.volumeHigh,
      'color': Colors.green,
    },
    {
      'name': 'صوت تسديد 3',
      'path': 'sounds/payment3.wav',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تسديد 4',
      'path': 'sounds/payment4.mp3',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تسديد 5',
      'path': 'sounds/payment5.mp3',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تسديد 6',
      'path': 'sounds/payment6.mp3',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تسديد 7',
      'path': 'sounds/payment7.mp3',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تسديد 8',
      'path': 'sounds/payment8.mp3',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تسديد 9',
      'path': 'sounds/payment9.mp3',
      'icon': FontAwesomeIcons.creditCard,
      'color': Colors.purple,
    },
    {
      'name': 'صوت تنبيه',
      'path': 'sounds/new-notification-7-210334.mp3',
      'icon': FontAwesomeIcons.bell,
      'color': Colors.orange,
    },
  ];

  Future<void> _previewSound(String soundPath) async {
    await _audioPlayer.play(AssetSource(soundPath));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.music,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر صوت التسديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'اضغط للاستماع ثم اختر',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Sound options
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...List.generate(_sounds.length, (index) {
                    final sound = _sounds[index];
                    final isSelected = _selectedSound == sound['path'];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected ? sound['color'] : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? sound['color'].withOpacity(0.1)
                            : Colors.grey[50],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sound['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            sound['icon'],
                            color: sound['color'],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          sound['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? sound['color'] : Colors.black87,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _previewSound(sound['path']),
                              icon: Icon(
                                FontAwesomeIcons.play,
                                color: sound['color'],
                                size: 16,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    sound['color'].withOpacity(0.1),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                FontAwesomeIcons.check,
                                color: sound['color'],
                                size: 20,
                              ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedSound = sound['path'];
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedSound != null
                        ? () {
                            widget.onSoundSelected(_selectedSound!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
