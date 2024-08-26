import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bestaetigung_page.dart';
import 'speech_to_text_service.dart';
import 'elovando_love_session_service.dart';
import 'env/env.dart';

class BeziehungsInputPage extends StatefulWidget {
  final String userId;

  BeziehungsInputPage({required this.userId});

  @override
  _BeziehungsInputPageState createState() => _BeziehungsInputPageState();
}

class _BeziehungsInputPageState extends State<BeziehungsInputPage> {
  double sliderValue = 6.0;
  final TextEditingController _inputController = TextEditingController();
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  bool _isProcessingSpeech = false;
  late ElovandoLoveSessionService _loveSessionService;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loveSessionService = ElovandoLoveSessionService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
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
        title: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 0),
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
                  border: Border.all(color: Color(0xFFDEDEDE)),
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
                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
                                controller: _inputController,
                                decoration: InputDecoration(
                                  hintText: _isProcessingSpeech ? '' : 'Dein Input hier...',
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
                              if (_isProcessingSpeech)
                                Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7D4666)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onLongPressStart: (_) => _startRecording(_inputController),
                                onLongPressEnd: (_) => _stopRecording(_inputController),
                                child: IconButton(
                                  icon: SvgPicture.asset(
                                    'assets/graphics/voice_input_icon.svg',
                                    color: _speechToTextService.isRecording && _speechToTextService.currentController == _inputController
                                        ? Colors.red
                                        : null,
                                  ),
                                  onPressed: () {}, // Disable normal press
                                ),
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
                  border: Border.all(color: Color(0xFFDEDEDE)),
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
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7D4666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSending ? null : () async {
                      setState(() {
                        _isSending = true;
                      });
                      try {
                        // Share user input
                        await _loveSessionService.shareUserInput(
                          widget.userId,
                          "Text Input: ${_inputController.text}\nStimmungstracker: ${sliderValue.round()}",
                        );
                        // Navigate to BestaetigungPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BestaetigungPage(userId: widget.userId),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Senden des Inputs: ${e.toString()}'),
                            duration: Duration(seconds: 10),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      } finally {
                        setState(() {
                          _isSending = false;
                        });
                      }
                    },
                    child: _isSending
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
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

  void _startRecording(TextEditingController controller) async {
    await _speechToTextService.startRecording(controller);
    setState(() {
      _isProcessingSpeech = true;
    });
  }

  void _stopRecording(TextEditingController controller) async {
    await _speechToTextService.stopRecording();
    String? transcription = await _speechToTextService.transcribeAudio();
    if (transcription != null) {
      setState(() {
        controller.text = transcription;
      });
    }
    setState(() {
      _isProcessingSpeech = false;
    });
  }
}