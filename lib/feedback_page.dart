import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double rating = 3.0;
  int selectedOption = 0;

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
            'Feedback zur Love Session',
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
              SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Feedback zu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF414254),
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'deiner letzten Love Session:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF414254),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Center(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(5, (index) {
      return IconButton(
        iconSize: 36, // Increase the size of the star icons
        icon: Icon(
          index < rating ? Icons.star : Icons.star,
          color: index < rating ? Color(0xFF7FCCB1) : Color(0xFFDEDEDE),
        ),
        onPressed: () {
          setState(() {
            rating = index + 1.0;
          });
        },
      );
    }),
  ),
),

              SizedBox(height: 16),
              _buildFeedbackInput('Das hat mir gefallen:'),
              SizedBox(height: 16),
              _buildFeedbackInput('Das war weniger gut:'),
              SizedBox(height: 16),
              /* Container(
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
                      'Ich möchte:',
                      style: TextStyle(
                        color: Color(0xFF414254),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildOption(0, 'Eine neue Stimme ausprobieren'),
                    _buildOption(1, 'Ein neues Sound-Design ausprobieren'),
                  ],
                ),
              ), */
              SizedBox(height: 20),
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
                      // Handle send action
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

  Widget _buildFeedbackInput(String label) {
    return Container(
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
            label,
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Geben Sie Feedback ein',
              hintStyle: TextStyle(color: Color(0xFF98999D)),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF7F7F7),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.transparent),
              ),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: SvgPicture.asset('assets/graphics/voice_input_icon.svg'),
                onPressed: () {
                  // Handle voice input action
                },
              ),
              IconButton(
                icon: SvgPicture.asset('assets/graphics/send_message_icon.svg'),
                onPressed: () {
                  // Handle send message action
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String text) {
    bool isSelected = selectedOption == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = index;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Color(0xFFDEDEDE),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Color(0xFF7FCCB1), width: 2)
              : Border.all(color: Color(0xFFDEDEDE), width: 1),
        ),
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF414254),
                  fontFamily: 'Inter',
                ),
              ),
            ),
            SvgPicture.asset(
              isSelected
                  ? 'assets/graphics/profil_erstellen_MC_item_selected.svg'
                  : 'assets/graphics/profil_erstellen_MC_item_not_selected.svg',
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
