import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import '../../../../enums/stakeholders/manufacturer_status.dart';
import 'vendor_detail_cubit.dart';
import 'vendor_detail_state.dart';
import '../vendor_edit/vendor_edit_view.dart';
import 'package:gizmoglobe_client/screens/stakeholder/vendors/permissions/vendor_permissions.dart';

class VendorDetailScreen extends StatefulWidget {
  final Manufacturer manufacturer;
  final bool readOnly;

  const VendorDetailScreen({
    super.key,
    required this.manufacturer,
    this.readOnly = false,
  });

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VendorDetailCubit(widget.manufacturer),
      child: BlocBuilder<VendorDetailCubit, VendorDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: GradientIconButton(
                icon: Icons.chevron_left,
                onPressed: () {
                  Navigator.pop(context);
                },
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.business,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              state.manufacturer.manufacturerName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Manufacturer Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Name', state.manufacturer.manufacturerName),
                          _buildInfoRow('Status', state.manufacturer.status.getName()),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: (widget.readOnly || !VendorPermissions.canManageVendors(state.userRole)) 
                    ? null 
                    : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final updatedManufacturer = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VendorEditScreen(
                                    manufacturer: state.manufacturer,
                                  ),
                                ),
                              );

                              if (updatedManufacturer != null) {
                                final cubit = context.read<VendorDetailCubit>();
                                cubit.updateManufacturer(updatedManufacturer);
                              }
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text('Edit', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final cubit = context.read<VendorDetailCubit>();
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    state.manufacturer.status == ManufacturerStatus.active 
                                      ? 'Deactivate Manufacturer' 
                                      : 'Activate Manufacturer'
                                  ),
                                  content: Text(
                                    'Are you sure you want to ${state.manufacturer.status == ManufacturerStatus.active ? "deactivate" : "activate"} this manufacturer?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogContext);
                                        await cubit.toggleManufacturerStatus();
                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text(
                                        state.manufacturer.status == ManufacturerStatus.active 
                                          ? 'Deactivate' 
                                          : 'Activate',
                                        style: TextStyle(
                                          color: state.manufacturer.status == ManufacturerStatus.active
                                            ? Colors.red
                                            : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              state.manufacturer.status == ManufacturerStatus.active 
                                ? Icons.block 
                                : Icons.check_circle,
                              color: Colors.white
                            ),
                            label: Text(
                              state.manufacturer.status == ManufacturerStatus.active 
                                ? 'Deactivate' 
                                : 'Activate',
                              style: const TextStyle(color: Colors.white)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state.manufacturer.status == ManufacturerStatus.active 
                                ? Colors.red 
                                : Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 