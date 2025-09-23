import 'package:flutter/material.dart';
import 'package:jfl_app/offer_card.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JFL',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 223, 223, 217),
        centerTitle: true,
        actions: [
          // Optional: Add a help/support button that links to backend FAQ
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.pushNamed(context, '/faq'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Karibu kwenye Joint Financial Legacy!', // Swahili version
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              // Consider fetching offers from backend in future
              _buildOfferCards(),
              const SizedBox(height: 15),
              _buildAuthButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ofa za sasa:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        OfferCard(
          title: 'RIBA',
          description: 'Riba ni 0% kwa mwanachama hai',
          color: Colors.blueGrey,
        ),
        OfferCard(
          title: 'BIMA',
          description: 'Mwanachama HAI ndani ya miezi 6 ataweza kupata bima ya Afya kwa mwaka mzima.',
          color: Colors.grey,
        ),
        OfferCard(
          title: 'MILIONI 3',
          description: 'Mwanachama akipatwa na umauti, familia yake itapatiwa milioni 3 kama lambilambi.',
          color: Colors.black,
        ),
        OfferCard(
          title: 'VACATION',
          description: 'Mwanachama Hai ndani ya mwaka 1 ataweza kupata mapumziko Zanzibar.',
          color: Colors.brown,
        ),
      ],
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: Colors.teal,
            ),
            child: const Text(
              'Ingia',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.teal),
              minimumSize: const Size(200, 50),
            ),
            child: const Text(
              'Jisajili',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}