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
      'message':
          'Zeit für eure wöchentliche Deeskalationssitzung! Jetzt starten und eure Beziehung stärken.'
    },
    {
      'title': 'Erinnerung2',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Zeit für eure wöchentliche Deeskalationssitzung! Jetzt starten und eure Beziehung stärken.'
    },
    {
      'title': 'Erinnerung3',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Zeit für eure wöchentliche Deeskalationssitzung! Jetzt starten und eure Beziehung stärken.'
    },
    {
      'title': 'Test',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message': 'Easter Egg: Hallo Linus :)'
    },
    {
      'title': 'Tipp des Tages',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Hört einander zu, ohne zu unterbrechen. Verständnis ist der Schlüssel zu einer harmonischen Beziehung.'
    },
    {
      'title': 'Hallo!',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Vergiss nicht, heute Abend unsere Love-Session zu machen. Ich freue mich darauf! 💖'
    },
    {
      'title': 'Super gemacht!',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Ihr habt diese Woche 3 Deeskalationsübungen abgeschlossen. Weiter so!'
    },
    {
      'title': 'Hey',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Wir sollten die neue Übung in der App ausprobieren. Es könnte uns wirklich helfen.'
    },
    {
      'title': 'Neue Funktion',
      'icon': 'assets/graphics/logo_circle_icon.png',
      'message':
          'Probiert unsere neuesten geführten Sitzungen aus, um Konflikte noch besser zu bewältigen!'
    },
  ];
  final Map<int, bool> _expandedStates = {};

  void _removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF414254)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Mitteilungen',
          style: TextStyle(
            color: Color(0xFF414254),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        actions: [
          // Padding(
          //   padding: const EdgeInsets.only(right: 20.0),
          //   child: IconButton(
          //     icon: SvgPicture.asset('assets/graphics/trash_icon.svg'),
          //     onPressed: () {
          //       // Handle global delete action
          //     },
          //   ),
          // ),
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
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'Keine Mitteilungen vorhanden',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF414254),
                  fontFamily: 'Inter',
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification, index);
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, String> notification, int index) {
    final isExpanded = _expandedStates[index] ?? false;
    final message = notification['message']!;
    final lines = message.split('\n');
    final truncatedText =
        lines.length > 3 ? lines.sublist(0, 3).join('\n') + '\n...' : message;

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
        color: Color(0xFFF44949),
        child: SvgPicture.asset(
          'assets/graphics/trash_icon.svg',
          color: Colors.white,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedStates[index] = !isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      notification['icon']!,
                      width: 40,
                      height: 40,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        notification['title']!,
                        style: TextStyle(
                          color: Color(0xFF414254),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  isExpanded ? message : truncatedText,
                  style: TextStyle(
                    color: Color(0xFF98999D),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  maxLines: isExpanded ? null : 3,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                if (lines.length > 3)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                      style: TextStyle(
                        color: Color(0xFF7D4666),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
