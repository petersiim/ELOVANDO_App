import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MitteilungenPage extends StatefulWidget {
  final String userId;

  MitteilungenPage({required this.userId});

  @override
  _MitteilungenPageState createState() => _MitteilungenPageState();
}

class _MitteilungenPageState extends State<MitteilungenPage> {
  List<Map<String, String>> notifications = [
    {
      'title': 'Erinnerung',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Zeit für eure wöchentliche Deeskalationssitzung! Jetzt starten und eure Beziehung stärken.'
    },
    {
      'title': 'Tipp des Tages',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Hört einander zu, ohne zu unterbrechen. Verständnis ist der Schlüssel zu einer harmonischen Beziehung.'
    },
    {
      'title': 'Hallo!',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Vergiss nicht, heute Abend unsere Love-Session zu machen. Ich freue mich darauf! 💖'
    },
    {
      'title': 'Super gemacht!',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Ihr habt diese Woche 3 Deeskalationsübungen abgeschlossen. Weiter so!'
    },
    {
      'title': 'Hey',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Wir sollten die neue Übung in der App ausprobieren. Es könnte uns wirklich helfen.'
    },
    {
      'title': 'Neue Funktion',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Probiert unsere neuesten geführten Sitzungen aus, um Konflikte noch besser zu bewältigen!'
    },
  ];

  void _removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7), // General background color
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF414254)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 0), // Adjust top and bottom padding
          child: Text(
            'Mitteilungen',
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0), // Add padding here
            child: IconButton(
              icon: SvgPicture.asset('assets/graphics/trash_icon.svg'),
              onPressed: () {
                // Handle global delete action
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.2),
          child: Divider(
            color: Color(0xFFDEDEDE),
            thickness: 1,
            height: 1,
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key(notification['title']!),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _removeNotification(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${notification['title']} dismissed')),
              );
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              color: Colors.transparent,
              child: Container(
                width: 75,
                color: Color(0xFFF44949),
                child: Center(
                  child: IconButton(
                    icon: SvgPicture.asset('assets/graphics/trash_icon.svg', color: Colors.white),
                    onPressed: () {
                      _removeNotification(index);
                    },
                  ),
                ),
              ),
            ),
            child: _buildNotificationItem(notification['title']!, notification['icon']!, notification['message']!),
          );
        },
        separatorBuilder: (context, index) => Divider(color: Color(0xFFDEDEDE), thickness: 1),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String iconPath, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            iconPath,
            width: 40,
            height: 40,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF414254),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Color(0xFF98999D),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
