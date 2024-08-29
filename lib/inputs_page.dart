import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_app_bar.dart';
import 'app_nav_bar.dart';
import 'firestore_service.dart';
import 'beziehungsinput_page.dart';

class InputsPage extends StatefulWidget {
  final String userId;

  const InputsPage({required this.userId});

  @override
  _InputsPageState createState() => _InputsPageState();
}

class _InputCardState {
  bool isExpanded = false;
}

class _InputsPageState extends State<InputsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _inputHistory = [];
  bool _isLoading = true;
  final Map<int, _InputCardState> _cardStates = {};

  @override
  void initState() {
    super.initState();
    _loadInputHistory();
  }

  Future<void> _loadInputHistory() async {
    try {
      final history = await _firestoreService.getUserInputHistory(widget.userId);
      setState(() {
        _inputHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading input history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildBeziehungsinputButton(),
        Expanded(
          child: _inputHistory.isEmpty
              ? _buildEmptyState()
              : _buildInputHistoryList(),
        ),
      ],
    );
  }

  Widget _buildBeziehungsinputButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BeziehungsInputPage(userId: widget.userId),
            ),
          );
        },
        child: Text('Beziehungsinput geben'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFF7D4666),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Noch keine Inputs vorhanden',
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFF414254),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildInputHistoryList() {
    return ListView.builder(
      itemCount: _inputHistory.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final input = _inputHistory[index];
        return _buildInputCard(input, index);
      },
    );
  }

  Widget _buildInputCard(Map<String, dynamic> input, int index) {
    final textInput = input['textInput'] ?? '';
    final lines = textInput.split('\n');
    final truncatedText = lines.length > 8
        ? lines.sublist(0, 8).join('\n') + '\n...'
        : textInput;

    _cardStates.putIfAbsent(index, () => _InputCardState());
    final isExpanded = _cardStates[index]!.isExpanded;

    return GestureDetector(
      onTap: () {
        setState(() {
          _cardStates[index]!.isExpanded = !isExpanded;
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
              Text(
                isExpanded ? textInput : truncatedText,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF414254),
                  fontFamily: 'Inter',
                ),
                maxLines: isExpanded ? null : 8,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.mood, color: Color(0xFF7FCCB1)),
                  SizedBox(width: 8),
                  Text(
                    'Stimmung: ${input['moodValue'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF98999D),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Datum: ${_formatTimestamp(input['timestamp'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF98999D),
                  fontFamily: 'Inter',
                ),
              ),
              if (lines.length > 8)
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
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}