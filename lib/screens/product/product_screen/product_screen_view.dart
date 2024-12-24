import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/screens/home/product_list_search/product_list_search_state.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/checkbox_button.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../../enums/processing/sort_enum.dart';
import '../../../widgets/filter/advanced_filter_search/advanced_filter_search_view.dart';
import '../../../widgets/general/app_text_style.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  static Widget newInstance() =>
      BlocProvider(
        create: (context) => ProductScreenCubit(),
        child: const ProductScreen(),
      );

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  ProductScreenCubit get cubit => context.read<ProductScreenCubit>();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    cubit.initialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: GradientIconButton(
            icon: Icons.menu_outlined,
            onPressed: () {
            },
            fillColor: Colors.transparent,
          ),

          title: FieldWithIcon(
            height: 40,
            controller: searchController,
            focusNode: searchFocusNode,
            hintText: 'Find your item',
            fillColor: Theme.of(context).colorScheme.surface,
            suffixIcon: Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onSuffixIconPressed: () {
              cubit.updateSearchText(searchController.text);
              cubit.applyFilters();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              BlocBuilder<ProductScreenCubit, ProductScreenState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      // CheckboxButton(
                      //   text: SortEnum.bestSeller.toString(),
                      //   onSelected: () {
                      //     cubit.updateSortOption(SortEnum.bestSeller);
                      //     cubit.applyFilters();
                      //   },
                      //   padding: const EdgeInsets.all(8),
                      //   textStyle: AppTextStyle.smallText,
                      //   isSelected: state.selectedOption == SortEnum.bestSeller,
                      // ),
                      // const SizedBox(width: 8),
                      //
                      // CheckboxButton(
                      //   text: SortEnum.lowestPrice.toString(),
                      //   onSelected: () {
                      //     cubit.updateSortOption(SortEnum.lowestPrice);
                      //     cubit.applyFilters();
                      //   },
                      //   padding: const EdgeInsets.all(8),
                      //   textStyle: AppTextStyle.smallText,
                      //   isSelected: state.selectedOption == SortEnum.lowestPrice,
                      // ),
                      // const SizedBox(width: 8),
                      //
                      // CheckboxButton(
                      //   text: SortEnum.highestPrice.toString(),
                      //   onSelected: () {
                      //     cubit.updateSortOption(SortEnum.highestPrice);
                      //     cubit.applyFilters();
                      //   },
                      //   padding: const EdgeInsets.all(8),
                      //   textStyle: AppTextStyle.smallText,
                      //   isSelected: state.selectedOption == SortEnum.highestPrice,
                      // ),

                      const Text('Sort by: '),

                      DropdownButton<SortEnum>(
                        value: state.selectedSortOption,
                        icon: const Icon(Icons.arrow_downward),
                        onChanged: (SortEnum? newValue) {
                          setState(() {
                            state.selectedSortOption = newValue!;
                            cubit.updateSortOption(state.selectedSortOption);
                            cubit.applyFilters();
                          });
                        },
                        items: SortEnum.values.map<DropdownMenuItem<SortEnum>>((SortEnum value) {
                          return DropdownMenuItem<SortEnum>(
                            value: value,
                            child: Row(
                              children: [
                                if (value == selectedSortOption) Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                                Text(value.toString()),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      Expanded(
                        child: Center(
                          child: GradientIconButton(
                            icon: Icons.filter_list_alt,
                            iconSize: 28,
                            onPressed: () async {
                              final FilterSearchArguments arguments = FilterSearchArguments(
                                selectedCategories: state.selectedCategoryList,
                                selectedManufacturers: state.selectedManufacturerList,
                                minPrice: state.minPrice,
                                maxPrice: state.maxPrice,
                              );

                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdvancedFilterSearchScreen.newInstance(
                                        arguments: arguments,
                                      ),
                                ),
                              );

                              if (result is FilterSearchArguments) {
                                cubit.updateFilter(
                                  selectedCategoryList: result.selectedCategories,
                                  selectedManufacturerList: result.selectedManufacturers,
                                  minPrice: result.minPrice,
                                  maxPrice: result.maxPrice,
                                );
                                cubit.applyFilters();
                              }
                            },
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Expanded(
                child: BlocBuilder<ProductScreenCubit, ProductScreenState>(
                  builder: (context, state) {
                    if (state.productList.isEmpty) {
                      return const Center(
                        child: Text('No products found'),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.productList.length,
                      itemBuilder: (context, index) {
                        final product = state.productList[index];
                        return ListTile(
                          title: Text(product.productName),
                          subtitle: Text('đ${product.price}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}