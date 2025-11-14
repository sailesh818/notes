import 'package:flutter/material.dart';
import 'package:notes_todo/payment/page/payment_page.dart';

class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  bool _isDiscountUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> gifts = [
      {
        'name': 'Flower Bouquet',
        'price': 19.99,
        'image': 'https://cdn-icons-png.flaticon.com/512/2943/2943392.png'
      },
      {
        'name': 'Chocolate Box',
        'price': 24.99,
        'image': 'https://cdn-icons-png.flaticon.com/512/3081/3081933.png'
      },
      {
        'name': 'Teddy Bear',
        'price': 29.99,
        'image': 'https://cdn-icons-png.flaticon.com/512/869/869869.png'
      },
      {
        'name': 'Surprise Gift Box',
        'price': 49.99,
        'image': 'https://cdn-icons-png.flaticon.com/512/869/869869.png'
      },
      {
        'name': 'Greeting Card',
        'price': 9.99,
        'image': 'https://cdn-icons-png.flaticon.com/512/2484/2484660.png'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Gifts'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Remove ad button — replaced with a simple discount button (optional)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isDiscountUnlocked = true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("10% Discount Unlocked!")),
                );
              },
              icon: const Icon(Icons.card_giftcard),
              label: const Text("Unlock 10% Discount"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            if (_isDiscountUnlocked)
              const Text(
                "✅ 10% Discount Unlocked!",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                itemCount: gifts.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return GestureDetector(
                    onTap: () => _showGiftDetails(context, gift),
                    child: _giftItem(gift),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _giftItem(Map<String, dynamic> gift) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(gift['image'], height: 80, width: 80),
          const SizedBox(height: 10),
          Text(
            gift['name'],
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${gift['price']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showGiftDetails(BuildContext context, Map<String, dynamic> gift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(gift['image'], height: 100, width: 100),
              const SizedBox(height: 10),
              Text(gift['name'],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '\$${gift['price']}',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _goToPayment(context, gift);
                },
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToPayment(BuildContext context, Map<String, dynamic> gift) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          giftName: gift['name'],
          giftPrice: gift['price'],
          hasDiscount: _isDiscountUnlocked,
        ),
      ),
    );
  }
}
