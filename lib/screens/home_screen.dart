import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/consts/app_constants.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/screens/search_screen.dart';
import 'package:notes_hub/widgets/products/ctg_rounded_widget.dart';
import 'package:notes_hub/widgets/products/latest_arrival.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final productProvider = Provider.of<ProductsProvider>(context);
    final latestNotes = productProvider.getProducts.take(6).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: UniNotesLogo(size: 34),
        ),
        title: const Text("UniNotes"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, SearchScreen.routName);
            },
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroSection(size: size),
              const SizedBox(height: 20),
              _QuickSearchCard(
                onTap: () {
                  Navigator.pushNamed(context, SearchScreen.routName);
                },
              ),
              const SizedBox(height: 24),
              const _SectionHeader(
                title: "Izdvojene kolekcije",
                subtitle: "Privremene sekcije bez starih slika skriptarnice.",
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _CollectionCard(
                      title: "Javne beleske",
                      subtitle:
                          "Otvorene kolekcije za brz pregled i pretragu po predmetima.",
                      colors: [Color(0xFF1F6FEB), Color(0xFF0EA5E9)],
                      icon: Icons.public_rounded,
                    ),
                    SizedBox(width: 12),
                    _CollectionCard(
                      title: "Premium sadrzaj",
                      subtitle:
                          "Kolekcije za kupovinu, organizovane po predmetima i oblastima.",
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      icon: Icons.workspace_premium_rounded,
                    ),
                    SizedBox(width: 12),
                    _CollectionCard(
                      title: "Moje beleznice",
                      subtitle:
                          "Prostor za sacuvane, kupljene i nedavno pregledane materijale.",
                      colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                      icon: Icons.menu_book_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(
                title: "Predmeti",
                subtitle: "Brzi ulaz u najtrazenije oblasti i kategorije beleski.",
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
                children:
                    List.generate(AppConstants.categoriesList.length, (index) {
                  return CategoryRoundedWidget(
                    image: AppConstants.categoriesList[index].image,
                    name: AppConstants.categoriesList[index].name,
                  );
                }),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(
                title: "Koje slike da mi posaljes",
                subtitle:
                    "Kad posaljes nove assete, odmah ih menjam na home ekranu.",
              ),
              const SizedBox(height: 14),
              const _ImageRequestCard(
                title: "Hero / banner slike",
                subtitle:
                    "1-3 horizontalne slike ili ilustracije aplikacije, idealno 1600x900 ili slican 16:9 odnos.",
              ),
              const SizedBox(height: 10),
              const _ImageRequestCard(
                title: "Predmetne ikonice",
                subtitle:
                    "Male slike za Matematiku, Programiranje, Elektroniku i ostale predmete koje budes imao.",
              ),
              const SizedBox(height: 10),
              const _ImageRequestCard(
                title: "Promo sekcije",
                subtitle:
                    "Slike za javne beleske, premium beleske i moje kolekcije ako zelis bogatiji home.",
              ),
              const SizedBox(height: 28),
              Visibility(
                visible: latestNotes.isNotEmpty,
                child: const _SectionHeader(
                  title: "Najnovije beleske",
                  subtitle:
                      "Dinamicki prikazane stavke iz baze koje studenti trenutno najvise pregledaju.",
                ),
              ),
              const SizedBox(height: 14),
              Visibility(
                visible: latestNotes.isNotEmpty,
                child: SizedBox(
                  height: size.height * 0.24,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: latestNotes.length,
                    itemBuilder: (context, index) {
                      return ChangeNotifierProvider.value(
                        value: latestNotes[index],
                        child: const LatestArrivalProductsWidget(),
                      );
                    },
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF17305A), Color(0xFF0F1B31)]
              : const [Color(0xFF1F6FEB), Color(0xFF14B8A6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.16),
            ),
            child: const Text(
              "Studentski hub za beleske",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Pregledaj, kupi i organizuj beleske po predmetima.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "UniNotes spaja javne skripte, licne beleske i premium sadrzaj u jednoj mobilnoj aplikaciji.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(label: "Javne beleske"),
              _HeroBadge(label: "Moje kolekcije"),
              _HeroBadge(label: "PayPal kupovina"),
            ],
          ),
          SizedBox(height: size.height * 0.02),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TitelesTextWidget(
                  label: title,
                  color: Colors.white,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                SubtitleTextWidget(
                  label: subtitle,
                  color: Colors.white70,
                  fontSize: 14,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageRequestCard extends StatelessWidget {
  const _ImageRequestCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.lightPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitelesTextWidget(label: title, fontSize: 17),
                const SizedBox(height: 6),
                SubtitleTextWidget(
                  label: subtitle,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSearchCard extends StatelessWidget {
  const _QuickSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.lightPrimary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Pretrazi beleske, predmete ili autore",
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitelesTextWidget(label: title),
        const SizedBox(height: 4),
        SubtitleTextWidget(
          label: subtitle,
          color: AppColors.muted,
        ),
      ],
    );
  }
}
