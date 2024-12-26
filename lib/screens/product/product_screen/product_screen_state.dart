import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../../enums/processing/sort_enum.dart';

class ProductScreenState extends Equatable {
  final String? searchText;
  final List<Product> productList;
  final int selectedTabIndex;
  final List<Manufacturer> manufacturerList;
  final SortEnum selectedSortOption;

  const ProductScreenState({
    this.searchText,
    this.productList = const [],
    this.selectedTabIndex = 0,
    this.manufacturerList = const [],
    this.selectedSortOption = SortEnum.releaseLatest,
  });

  @override
  List<Object?> get props => [
    searchText,
    productList,
    selectedTabIndex,
    manufacturerList,
    selectedSortOption,
  ];

  ProductScreenState copyWith({
    String? searchText,
    List<Product>? productList,
    List<Manufacturer>? manufacturerList,
    int? selectedTabIndex,
    SortEnum? selectedSortOption,
  }) {
    return ProductScreenState(
      searchText: searchText ?? this.searchText,
      productList: productList ?? this.productList,
      manufacturerList: manufacturerList ?? this.manufacturerList,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedSortOption: selectedSortOption ?? this.selectedSortOption,
    );
  }
}