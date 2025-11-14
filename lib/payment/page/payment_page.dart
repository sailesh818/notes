import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final String giftName;
  final double giftPrice;
  final bool hasDiscount;

  const PaymentPage({
    super.key,
    required this.giftName,
    required this.giftPrice,
    this.hasDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final discountAmount = hasDiscount ? giftPrice * 0.10 : 0;
    final finalPrice = giftPrice - discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gift: $giftName", style: const TextStyle(fontSize: 20)),

            const SizedBox(height: 12),
            Text("Original Price: \$${giftPrice.toStringAsFixed(2)}"),

            if (hasDiscount) ...[
              const SizedBox(height: 8),
              Text(
                "10% Discount: -\$${discountAmount.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.green),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              "Final Price: \$${finalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment Completed")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Pay Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
