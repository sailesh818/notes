import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_todo/payment/page/payment_page.dart';

class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  bool _isDiscountUnlocked = false;
  int _userPoints = 0; // ⭐ User points for watching ads

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedInterstitialAd();
  }

  // -----------------------------
  // Load Rewarded Interstitial Ad
  // -----------------------------
  void _loadRewardedInterstitialAd() {
    setState(() => _isAdLoading = true);

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-6704136477020125/1325699739',
      //adUnitId: 'ca-app-pub-3940256099942544/1033173712', //testInterstitialAdUnitId
      // interstellier test adunit here const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          setState(() => _isAdLoading = false);
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          setState(() => _isAdLoading = false);
        },
      ),
    );
  }

  // -----------------------------
  // Show Rewarded Interstitial Ad (Used for BOTH discount + points)
  // -----------------------------
  void _showAdForPoints() {
    if (_rewardedInterstitialAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad not ready yet, try again")),
      );
      _loadRewardedInterstitialAd();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedInterstitialAd();
      },
    );

    _rewardedInterstitialAd!.show(onUserEarnedReward: (ad, reward) {
      setState(() {
        _userPoints += 10; // ⭐ Earn 10 points per ad
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎉 You earned 10 points! Total: $_userPoints")),
      );
    });

    _rewardedInterstitialAd = null;
  }

  // Discount ad
  void _showRewardedInterstitialAd() {
    if (_rewardedInterstitialAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad not loaded yet, try again")),
      );
      _loadRewardedInterstitialAd();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedInterstitialAd();
      },
    );

    _rewardedInterstitialAd!.show(onUserEarnedReward: (ad, reward) {
      setState(() => _isDiscountUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎁 10% Discount Unlocked!")),
      );
    });

    _rewardedInterstitialAd = null;
  }

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
            // ⭐ Unlock Discount Button
            ElevatedButton.icon(
              onPressed: _isDiscountUnlocked || _isAdLoading
                  ? null
                  : _showRewardedInterstitialAd,
              icon: const Icon(Icons.card_giftcard),
              label: Text(_isDiscountUnlocked
                  ? "Discount Unlocked"
                  : (_isAdLoading ? "Loading Ad..." : "Unlock 10% Discount")),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            if (_isDiscountUnlocked)
              const Text("🎁 10% Discount Unlocked!",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),

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
          Text(gift['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // -----------------------------
  // BOTTOM SHEET WITH WATCH AD BUTTON
  // -----------------------------
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
              Text(gift['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '\$${gift['price']}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ WATCH AD BUTTON FOR POINTS
              ElevatedButton.icon(
                onPressed: _isAdLoading ? null : _showAdForPoints,
                icon: const Icon(Icons.ondemand_video),
                label: const Text('Watch Ad & Earn 10 Points'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // 🟣 Proceed to payment
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
