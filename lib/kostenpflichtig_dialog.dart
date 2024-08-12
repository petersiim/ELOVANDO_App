import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KostenpflichtigDialog extends StatefulWidget {
  @override
  _KostenpflichtigDialogState createState() => _KostenpflichtigDialogState();
}

class _KostenpflichtigDialogState extends State<KostenpflichtigDialog> {
  int selectedIndex = 1;
  String promoCode = '';
  bool isPromoCodeValid = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlanOption(0, 'Monatliche Harmonie', '18.- / Monat'),
                          _buildPlanOption(1, 'Jährliche Gelassenheit', '80.- / Jahr', isPopular: true),
                          _buildPlanOption(2, 'Lebenslange Glückseligkeit', '120.- / Lifetime-Access'),
                          _buildPlanOption(3, '4er Packet', '20.-'),
                          _buildPromoCodeOption(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
            Positioned(
              right: -25,
              top: -25,
              child: IconButton(
                icon: SvgPicture.asset('assets/graphics/pop_up_X_button.svg'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5),
          Text(
            'Ab jetzt kostenpflichtig',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 20),
          Text(
            'Deine fünf kostenlosen Love-Sessions sind nun abgelaufen. Wir hoffen, sehr, dass sie euch in eurer Beziehung weitergebracht haben und wir euch weiter auf eurem Weg begleiten dürfen. Mit unserem Premium-Plan könnt ihr weiterhin von personalisierten Love-Sessions profitieren und eure Beziehung stärken.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF98999D),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 20),
          Text(
            'Wähle deinen Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7FCCB1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: selectedIndex != -1 ? () {
              // Handle pay now action
            } : null,
            icon: SvgPicture.asset(
              'assets/graphics/credit_card_icon.svg',
              width: 24,
              height: 24,
            ),
            label: Text(
              'Pay now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption(int index, String title, String price, {bool isPopular = false}) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Color(0xFF7FCCB1), width: 2)
              : null,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black26, blurRadius: 6.0, offset: Offset(0, 2))]
              : [],
        ),
        padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF414254),
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF414254),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
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
            if (isPopular)
              Positioned(
                top: -17,
                right: -16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF7D4666),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.0),
                      bottomLeft: Radius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Most popular',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeOption() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gutscheincode einlösen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Code eingeben',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      promoCode = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Validate promo code
                  setState(() {
                    isPromoCodeValid = _validatePromoCode(promoCode);
                  });
                },
                child: Text('Einlösen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7FCCB1),
                ),
              ),
            ],
          ),
          if (isPromoCodeValid)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Gutscheincode erfolgreich eingelöst!',
                style: TextStyle(
                  color: Color(0xFF7FCCB1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _validatePromoCode(String code) {
    // Implement your promo code validation logic here
    // For this example, we'll consider any non-empty code as valid
    return code.isNotEmpty;
  }
}