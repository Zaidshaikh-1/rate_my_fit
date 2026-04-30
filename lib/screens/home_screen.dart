import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/fit_card.dart';
import '../widgets/vibe_card_button.dart';

// Placeholder fit model — swap with Firestore model later
class _FitPost {
  final String id;
  final String username;
  final String timeAgo;
  final List<String> tags;
  final double avgScore;
  final int ratingCount;

  const _FitPost({
    required this.id,
    required this.username,
    required this.timeAgo,
    required this.tags,
    required this.avgScore,
    required this.ratingCount,
  });
}

// Sample data — replace with Firestore stream
final _sampleFits = [
  _FitPost(
    id: '1',
    username: '@zaidxo',
    timeAgo: '2h ago',
    tags: ['streetwear', 'grunge', 'oversized'],
    avgScore: 91,
    ratingCount: 34,
  ),
  _FitPost(
    id: '2',
    username: '@mia.fits',
    timeAgo: '4h ago',
    tags: ['y2k', 'denim', 'vintage'],
    avgScore: 74,
    ratingCount: 21,
  ),
  _FitPost(
    id: '3',
    username: '@kaito.drip',
    timeAgo: '6h ago',
    tags: ['minimal', 'monochrome'],
    avgScore: 52,
    ratingCount: 18,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // tracks which vibe the user picked per post id
  final Map<String, Vibe?> _selectedVibes = {};

  void _rate(String postId, Vibe vibe) {
    setState(() {
      _selectedVibes[postId] = vibe;
    });
    // TODO: write to Firestore here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'rate',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'myfit',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _sampleFits.length,
        itemBuilder: (context, index) {
          final fit = _sampleFits[index];
          final selected = _selectedVibes[fit.id];

          return Column(
            children: [
              FitCard(
                username: fit.username,
                timeAgo: fit.timeAgo,
                tags: fit.tags,
                avgScore: fit.avgScore,
                ratingCount: fit.ratingCount,
              ),

              // Vibe card row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: vibeCards.map((card) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: VibeCardButton(
                          card: card,
                          selected: selected == card.vibe,
                          onTap: () => _rate(fit.id, card.vibe),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 4),
              Divider(
                color: AppColors.border,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }
}
