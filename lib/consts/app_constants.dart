import 'package:notes_hub/models/categories_model.dart';
import 'package:notes_hub/services/assets_manager.dart';

class AppConstants {
  static const String imageUrl =
      'https://m.media-amazon.com/images/I/71nj3JM-igL._AC_UF894,1000_QL80_.jpg';

  static List<CategoriesModel> categoriesList = [
    CategoriesModel(
        id: "${AssetsManager.imagePath}/categories/book.png",
        name: "Matematika",
        image: "${AssetsManager.imagePath}/categories/book.png"),
    CategoriesModel(
        id: "${AssetsManager.imagePath}/categories/stationery.png",
        name: "Programiranje",
        image: "${AssetsManager.imagePath}/categories/stationery.png"),
    CategoriesModel(
        id: "${AssetsManager.imagePath}/categories/t-shirt.png",
        name: "Elektronika",
        image: "${AssetsManager.imagePath}/categories/t-shirt.png"),
  ];
}
