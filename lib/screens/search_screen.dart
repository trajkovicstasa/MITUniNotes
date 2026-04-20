import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  static const routName = "/skripte";
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController searchTextController;
  late final Stream<List<ProductModel>> _productsStream;

  @override
  void initState() {
    super.initState();
    searchTextController = TextEditingController();
    searchTextController.addListener(_onSearchChanged);
    _productsStream =
        Provider.of<ProductsProvider>(context, listen: false).fetchProductsStream();
  }

  @override
  void dispose() {
    searchTextController.removeListener(_onSearchChanged);
    searchTextController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final passedCategory =
        ModalRoute.of(context)?.settings.arguments as String?;
    final pageTitle = passedCategory ?? "Sve skripte";

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                )
              : const Padding(
                  padding: EdgeInsets.all(10),
                  child: UniNotesLogo(size: 34),
                ),
          title: Text(pageTitle),
        ),
        body: StreamBuilder<List<ProductModel>>(
          stream: _productsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: SelectableText(snapshot.error.toString()));
            }
            if (snapshot.data == null) {
              return const Center(
                child: SelectableText("Jos nema dodatih skripti"),
              );
            }

            final allNotes = snapshot.data!;
            final categoryFiltered = passedCategory == null
                ? allNotes
                : allNotes
                    .where((note) => note.productCategory
                        .toLowerCase()
                        .contains(passedCategory.toLowerCase()))
                    .toList();

            final query = searchTextController.text.trim();
            final visibleNotes = query.isEmpty
                ? categoryFiltered
                : productsProvider.searchQuery(
                    searchText: query,
                    passedList: categoryFiltered,
                  );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ListingHero(
                          title: pageTitle,
                          notesCount: categoryFiltered.length,
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TitelesTextWidget(
                                label: "Pretraga kroz skripte",
                              ),
                              const SizedBox(height: 6),
                              const SubtitleTextWidget(
                                label:
                                    "Pronadji skripte po naslovu, predmetu ili kljucnim recima.",
                                color: AppColors.muted,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: searchTextController,
                                decoration: InputDecoration(
                                  hintText: "Naslov skripte, predmet ili oblast",
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: searchTextController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            searchTextController.clear();
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: AppColors.lightPrimary,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(
                              label: pageTitle,
                              highlighted: true,
                            ),
                            const _FilterChip(label: "PDF"),
                            const _FilterChip(label: "Najnovije"),
                            const _FilterChip(label: "Premium"),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TitelesTextWidget(
                              label: "Skripte",
                              fontSize: 18,
                            ),
                            SubtitleTextWidget(
                              label: "${visibleNotes.length} rezultata",
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                if (visibleNotes.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _EmptySearchState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: visibleNotes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListingNoteCard(note: visibleNotes[index]),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListingHero extends StatelessWidget {
  const _ListingHero({
    required this.title,
    required this.notesCount,
  });

  final String title;
  final int notesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F6FEB),
            Color(0xFF7C3AED),
          ],
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
            child: Text(
              "$notesCount dostupnih skripti",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TitelesTextWidget(
            label: title,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const SubtitleTextWidget(
            label:
                "Pregled svih skripti za izabrani predmet ili kolekciju. Odavde korisnik bira konkretnu skriptu i prelazi na detalje.",
            color: Colors.white70,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _ListingNoteCard extends StatelessWidget {
  const _ListingNoteCard({required this.note});

  final ProductModel note;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.pushNamed(
            context,
            ProductDetailsScreen.routName,
            arguments: note.productId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  note.productImage,
                  width: 92,
                  height: 116,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 92,
                      height: 116,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                      child: const Icon(Icons.description_outlined),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(label: note.productCategory),
                        const _MetaPill(label: "PDF"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label: note.productDescription,
                      color: AppColors.muted,
                      fontSize: 14,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MetaPill(label: note.isFree ? "Besplatna" : "Premium"),
                        const Spacer(),
                        SubtitleTextWidget(
                          label: "${note.productPrice} RSD",
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.lightPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.lightPrimary : AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: AppColors.lightPrimary,
          ),
          SizedBox(height: 12),
          TitelesTextWidget(label: "Nema rezultata"),
          SizedBox(height: 6),
          SubtitleTextWidget(
            label: "Probaj drugi pojam, predmet ili kategoriju beleski.",
            color: AppColors.muted,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
