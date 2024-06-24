import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bestaetigung_page.dart';

class BeziehungsInputPage extends StatefulWidget {
  final String userId;

  BeziehungsInputPage({required this.userId});

  @override
  _BeziehungsInputPageState createState() => _BeziehungsInputPageState();
}

class _BeziehungsInputPageState extends State<BeziehungsInputPage> {
  double sliderValue = 6.0;

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
          padding: const EdgeInsets.only(
              top: 0, bottom: 0), // Adjust top and bottom padding
          child: Text(
            'Beziehungsinput',
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.2),
          child: Divider(
            color: Color(0xFFDEDEDE),
            thickness: 1,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFDEDEDE)), // Border color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deine Beziehungsinputs',
                      style: TextStyle(
                        color: Color(0xFF414254),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eure Inputs sind der Schlüssel zu personalisierten und effektiven Love-Sessions. Je mehr ihr hier über eure Gefühle und darüber, wie es in eurer Beziehung läuft, sprecht, desto besser kann das System die Love-Sessions gestalten. Erzähle hier, wie es dir allgemein und in deiner Beziehung geht. Was läuft gut? Was könnte besser sein? Sei ehrlich und offen, erzähle von deinen täglichen Erfahrungen und spezifischen Situationen. Diese Daten werden ausschließlich zur Gestaltung eurer Love Sessions verwendet, werden verschlüsselt übermittelt und sind für niemanden einsehbar.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF98999D),
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Dein Input hier...',
                              hintStyle: TextStyle(color: Color(0xFF98999D)),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Color(0xFFF7F7F7),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.transparent),
                              ),
                            ),
                            maxLines: 4,
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: SvgPicture.asset(
                                    'assets/graphics/voice_input_icon.svg'),
                                onPressed: () {
                                  // Handle voice input action
                                },
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                    'assets/graphics/send_message_icon.svg'),
                                onPressed: () {
                                  // Handle send message action
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFDEDEDE)), // Border color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stimmungstracker',
                      style: TextStyle(
                        color: Color(0xFF414254),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 8.0,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 12.0,
                                pressedElevation: 8.0,
                              ),
                              thumbColor: Colors.white,
                              overlayColor: Color(0xFFDEDEDE),
                              activeTrackColor: Color(0xFF7FCCB1),
                              inactiveTrackColor: Color(0xFFF7F7F7),
                              overlayShape: RoundSliderOverlayShape(
                                overlayRadius: 20.0,
                              ),
                              tickMarkShape: RoundSliderTickMarkShape(),
                              activeTickMarkColor: Colors.transparent,
                              inactiveTickMarkColor: Colors.transparent,
                              valueIndicatorShape:
                                  PaddleSliderValueIndicatorShape(),
                              valueIndicatorColor: Color(0xFF7FCCB1),
                              valueIndicatorTextStyle: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 12,
                              ),
                            ),
                            child: Slider(
                              value: sliderValue,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (value) {
                                setState(() {
                                  sliderValue = value;
                                });
                              },
                              label: sliderValue.round().toString(),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(10, (index) {
                                return Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF414254),
                                    fontFamily: 'Inter',
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Container(
                  width: double.infinity, // Make the button full width
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7D4666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BestaetigungPage(userId: widget.userId),
                        ),
                      );
                    },
                    child: Text(
                      'Senden',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
