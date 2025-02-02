import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_family.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_capacity.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_type.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_capacity.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_series.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_series.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_efficiency.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_capacity_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';
import '../../data/database/database.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/psu.dart';
import 'package:gizmoglobe_client/objects/product_related/ram.dart';

import '../../enums/invoice_related/payment_status.dart';
import '../../enums/invoice_related/sales_status.dart';
import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../../enums/stakeholders/employee_role.dart';
import '../../enums/stakeholders/manufacturer_status.dart';
import '../../objects/address_related/address.dart';
import '../../objects/address_related/district.dart';
import '../../objects/address_related/province.dart';
import '../../objects/address_related/ward.dart';
import '../../objects/customer.dart';
import '../../objects/employee.dart';
import '../../objects/invoice_related/incoming_invoice.dart';
import '../../objects/invoice_related/incoming_invoice_detail.dart';
import '../../objects/invoice_related/sales_invoice_detail.dart';
import '../../objects/invoice_related/warranty_invoice_detail.dart';
import '../../objects/manufacturer.dart';
import '../../objects/product_related/product.dart';
import '../../objects/product_related/product_factory.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/objects/invoice_related/warranty_invoice.dart';

Future<void> pushProductSamplesToFirebase() async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Database().generateSampleData();
    for (var manufacturer in Database().manufacturerList) {
      await firestore.collection('manufacturers').doc(manufacturer.manufacturerID).set({
        'manufacturerID': manufacturer.manufacturerID,
        'manufacturerName': manufacturer.manufacturerName,
      });
    }

    // Push products to Firestore
    for (var product in Database().productList) {
      Map<String, dynamic> productData = {
        'productName': product.productName,
        'importPrice': product.importPrice,
        'sellingPrice': product.sellingPrice,
        'discount': product.discount,
        'release': product.release,
        'sales': product.sales,
        'stock': product.stock,
        'status': product.status.getName(),
        'manufacturerID': product.manufacturer.manufacturerID,
        'category': product.category.getName(),
      };

      // Thêm các thuộc tính đặc thù cho từng loại sản phẩm
      switch (product.runtimeType) {
        case RAM:
          final ram = product as RAM;
          productData.addAll({
            'bus': ram.bus.getName(),
            'capacity': ram.capacity.getName(),
            'ramType': ram.ramType.getName(),
          });
          break;

        case CPU:
          final cpu = product as CPU;
          productData.addAll({
            'family': cpu.family.getName(),
            'core': cpu.core,
            'thread': cpu.thread,
            'clockSpeed': cpu.clockSpeed,
          });
          break;

        case GPU:
          final gpu = product as GPU;
          productData.addAll({
            'series': gpu.series.getName(),
            'capacity': gpu.capacity.getName(),
            'busWidth': gpu.bus.getName(),
            'clockSpeed': gpu.clockSpeed,
          });
          break;

        case Mainboard:
          final mainboard = product as Mainboard;
          productData.addAll({
            'formFactor': mainboard.formFactor.getName(),
            'series': mainboard.series.getName(),
            'compatibility': mainboard.compatibility.getName(),
          });
          break;

        case Drive:
          final drive = product as Drive;
          productData.addAll({
            'type': drive.type.getName(),
            'capacity': drive.capacity.getName(),
          });
          break;

        case PSU:
          final psu = product as PSU;
          productData.addAll({
            'wattage': psu.wattage,
            'efficiency': psu.efficiency.getName(),
            'modular': psu.modular.getName(),
          });
          break;
      }

      // Thêm sản phẩm vào Firestore và lấy document reference
      DocumentReference docRef = await firestore.collection('products').add(productData);

      // Cập nhật lại document với productID
      await docRef.update({
        'productID': docRef.id
      });
    }
  } catch (e) {
    print('Error pushing product samples to Firebase: $e');
  }
}

Future<void> pushAddressSamplesToFirebase() async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Database().generateSampleData();

    for (var address in Database().addressList) {
      DocumentReference docRef = await firestore.collection('addresses').add({
        'customerID': address.customerID,
        'receiverName': address.receiverName,
        'receiverPhone': address.receiverPhone,
        'provinceCode': address.province?.code,
        'districtCode': address.district?.code,
        'wardCode': address.ward?.code,
        'street': address.street ?? '',
        'isDefault': address.isDefault,
      });

      // Cập nhật lại document với addressID
      await docRef.update({'addressID': docRef.id});
    }
  } catch (e) {
    print('Error pushing address samples to Firebase: $e');
    rethrow;
  }
}

Future<void> pushSalesInvoiceSampleData() async {
  try {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final Database database = Database();

    // Khởi tạo dữ liệu mẫu trước khi upload
    database.generateSampleData();

    // Kiểm tra dữ liệu
    if (database.salesInvoiceList.isEmpty) {
      throw Exception('No sales invoice data to upload');
    }

    for (var invoice in database.salesInvoiceList) {
      if (invoice.customerID.isEmpty) {
        throw Exception('CustomerID cannot be empty');
      }
      for (var detail in invoice.details) {
        if (detail.productID.isEmpty) {
          throw Exception('ProductID cannot be empty');
        }
      }
    }

    // Tạo bảng nếu chưa tồn tại
    final salesInvoicesCollection = db.collection('sales_invoices');
    final salesInvoiceDetailsCollection = db.collection('sales_invoice_details');

    // Kiểm tra xem collection đã tồn tại chưa
    final salesInvoicesDoc = await salesInvoicesCollection.limit(1).get();
    if (salesInvoicesDoc.docs.isEmpty) {
      await salesInvoicesCollection.doc('placeholder').set({});
      await salesInvoicesCollection.doc('placeholder').delete();
    }

    final salesInvoiceDetailsDoc = await salesInvoiceDetailsCollection.limit(1).get();
    if (salesInvoiceDetailsDoc.docs.isEmpty) {
      await salesInvoiceDetailsCollection.doc('placeholder').set({});
      await salesInvoiceDetailsCollection.doc('placeholder').delete();
    }

    // Xóa dữ liệu cũ nếu có
    final existingInvoices = await salesInvoicesCollection.get();
    for (var doc in existingInvoices.docs) {
      batch.delete(doc.reference);
    }

    final existingDetails = await salesInvoiceDetailsCollection.get();
    for (var doc in existingDetails.docs) {
      batch.delete(doc.reference);
    }

    // Upload dữ liệu mới
    for (var invoice in database.salesInvoiceList) {
      final String invoiceID = db.collection('sales_invoices').doc().id;

      final invoiceData = invoice.toMap();
      invoiceData['salesInvoiceID'] = invoiceID;

      batch.set(db.collection('sales_invoices').doc(invoiceID), invoiceData);

      for (var detail in invoice.details) {
        final String detailID = db.collection('sales_invoice_details').doc().id;
        final detailData = detail.toMap();

        detailData['salesInvoiceDetailID'] = detailID;
        detailData['salesInvoiceID'] = invoiceID;

        batch.set(db.collection('sales_invoice_details').doc(detailID), detailData);
      }
    }

    // Thực thi batch
    await batch.commit();

    print('Successfully pushed sales invoice samples to Firestore');
  } catch (e) {
    print('Error in pushSalesInvoiceSampleData: $e');
    rethrow;
  }
}

class Firebase {
  static final Firebase _firebase = Firebase._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory Firebase() {
    return _firebase;
  }

  Firebase._internal();

  // Thêm getter để lấy current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> pushCustomerSampleData() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      Database().generateSampleData();

      for (var customer in Database().customerList) {
        DocumentReference docRef = await firestore.collection('customers').add(
          customer.toMap(),
        );
        
        customer.customerID = docRef.id;
        // Cập nhật lại document với ID
        await docRef.update({
          'customerID': docRef.id,
          ...customer.toMap()
        });
      }
      print('Successfully pushed customer data');
    } catch (e) {
      print('Error pushing sample data: $e');
      rethrow;
    }
  }

  Future<List<Customer>> getCustomers() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();

      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách khách hàng: $e');
      rethrow;
    }
  }

  Stream<List<Customer>> customersStream() {
    return FirebaseFirestore.instance
        .collection('customers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      if (customer.customerID == null) {
        throw Exception('Customer ID cannot be null');
      }

      // Update customer information
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customer.customerID)
          .update({
        'customerName': customer.customerName,
        'phoneNumber': customer.phoneNumber,
      });

      // Update corresponding user information
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userID', isEqualTo: customer.customerID)
          .get();

      for (var doc in userSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .update({
          'username': customer.customerName,
        });
      }

      // Fetch and update matched addresses
      QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .where('customerID', isEqualTo: customer.customerID)
          .get();

      for (var doc in addressSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('addresses')
            .doc(doc.id)
            .update({
          'receiverName': customer.customerName,
        });
      }
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      // Xóa khách hàng từ collection customers
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .delete();

      // Xóa tài khoản user tương ứng nếu có
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userID', isEqualTo: customerId)
          .get();

      for (var doc in userSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .delete();
      }

      // Có thể thêm logic để xóa các dữ liệu liên quan khác
      // như orders, cart items, etc.

    } catch (e) {
      print('Lỗi khi xóa khách hàng: $e');
      rethrow;
    }
  }

  Future<void> createCustomer(Customer customer) async {
    try {
      // Tạo customer trong collection customers
      DocumentReference customerRef = await FirebaseFirestore.instance
          .collection('customers')
          .add(customer.toMap());
      
      String customerId = customerRef.id;
      customer.customerID = customerId;
      
      // Cập nhật customerID trong document customer
      await customerRef.update({'customerID': customerId});

      // Tạo user với cùng ID như customer
      await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)  // Sử dụng customerId làm document ID
          .set({
        'email': customer.email,
        'username': customer.customerName,
        'role': 'customer',
        'userID': customerId
      });
    } catch (e) {
      print('Lỗi khi tạo khách hàng mới: $e');
      rethrow;
    }
  }

  Future<Customer?> getCustomerByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Customer.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    } catch (e) {
      print('Lỗi khi tìm khách hàng theo email: $e');
      rethrow;
    }
  }

  Future<void> createAddress(Address address) async {
    try {
      // Add address to collection addresses
      DocumentReference addressRef = await FirebaseFirestore.instance
          .collection('addresses')
          .add(address.toMap());

      String addressId = addressRef.id;
      address.addressID = addressId;

      // Update addressID in the document address
      await addressRef.update({'addressID': addressId});
      await FirebaseFirestore.instance
          .collection('addresses')
          .doc(addressId)
          .set({
        'addressID': addressId,
        'customerID': address.customerID,
        'receiverName': address.receiverName,
        'receiverPhone': address.receiverPhone,
        'provinceCode': address.province?.code,
        'districtCode': address.district?.code,
        'wardCode': address.ward?.code,
        'street': address.street ?? '',
        'isDefault': address.isDefault,
      });

      await Database().fetchAddress();
      Database().customerList = await getCustomers();
    } catch (e) {
      print('Error creating new address: $e');
      rethrow;
    }
  }

  // Employee-related functions
  Future<List<Employee>> getEmployees() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('employees')
          .get();

      return snapshot.docs.map((doc) {
        return Employee.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách nhân viên: $e');
      rethrow;
    }
  }

  Stream<List<Employee>> employeesStream() {
    return FirebaseFirestore.instance
        .collection('employees')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Employee.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> updateEmployee(Employee employee) async {
    try {
      if (employee.employeeID == null) {
        throw Exception('Employee ID cannot be null');
      }

      // Lấy thông tin employee cũ trước khi cập nhật
      DocumentSnapshot oldEmployeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employee.employeeID)
          .get();

      if (!oldEmployeeDoc.exists) {
        throw Exception('Employee not found');
      }

      Map<String, dynamic> oldEmployeeData = oldEmployeeDoc.data() as Map<String, dynamic>;
      String oldEmail = oldEmployeeData['email'];

      // Tạo map chứa thông tin cần cập nhật, không bao gồm email
      Map<String, dynamic> updateData = {
        'employeeName': employee.employeeName,
        'phoneNumber': employee.phoneNumber,
        'role': employee.role.getName(),
      };

      // Cập nhật thông tin employee
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employee.employeeID)
          .update(updateData);
      
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: oldEmail)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        await updateUserInformation(userSnapshot.docs.first.id, {
          'username': employee.employeeName,
          'role': employee.role == RoleEnum.owner ? 'admin' : employee.role.getName(),
        });
      }
    } catch (e) {
      print('Lỗi khi cập nhật nhân viên: $e');
      rethrow;
    }
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      // Lấy thông tin nhân viên trước khi xóa
      DocumentSnapshot employeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .get();

      if (employeeDoc.exists) {
        String employeeEmail = (employeeDoc.data() as Map<String, dynamic>)['email'];

        // Xóa nhân viên
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(employeeId)
            .delete();

        // Xóa tài khoản user tương ứng
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: employeeEmail)
            .get();

        for (var doc in userSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .delete();
        }
      }
    } catch (e) {
      print('Lỗi khi xóa nhân viên: $e');
      rethrow;
    }
  }

  Future<void> addEmployee(Employee employee) async {
    try {
      // Kiểm tra xem email đã tồn tại chưa
      QuerySnapshot existingEmployees = await FirebaseFirestore.instance
          .collection('employees')
          .where('email', isEqualTo: employee.email)
          .get();

      if (existingEmployees.docs.isNotEmpty) {
        throw Exception('Email has already been registered');
      }

      // Thêm nhân viên mới vào collection employees
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('employees')
          .add(employee.toMap());

      // Cập nhật ID cho nhân viên
      employee.employeeID = docRef.id;

      // Thêm tài khoản user tương ứng
      await FirebaseFirestore.instance.collection('users').doc(docRef.id).set({
        'email': employee.email,
        'username': employee.employeeName,
        'userID': docRef.id,
        'role': employee.role == RoleEnum.owner ? 'admin' : employee.role.getName(),
      });

    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  // Manufacturer-related functions
  Future<List<Manufacturer>> getManufacturers() async {
    try {
      final snapshot = await _firestore.collection('manufacturers').get();
      return snapshot.docs
          .map((doc) => _mapManufacturerFromJson(
                doc.data(),
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting manufacturers: $e');
      rethrow;
    }
  }

  Stream<List<Manufacturer>> manufacturersStream() {
    return _firestore
        .collection('manufacturers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapManufacturerFromJson(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  Future<void> updateManufacturer(Manufacturer manufacturer) async {
    try {
      final doc = _firestore.collection('manufacturers').doc(manufacturer.manufacturerID);
      await doc.update(_mapManufacturerToJson(manufacturer));
    } catch (e) {
      print('Error updating manufacturer: $e');
      rethrow;
    }
  }

  Future<void> deleteManufacturer(String manufacturerId) async {
    try {
      // Find document by manufacturerID field
      final querySnapshot = await FirebaseFirestore.instance
          .collection('manufacturers')
          .where('manufacturerID', isEqualTo: manufacturerId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Manufacturer not found');
      }

      await FirebaseFirestore.instance
          .collection('manufacturers')
          .doc(querySnapshot.docs.first.id)
          .delete();

      // Cập nhật trạng thái discontinued cho các sản phẩm liên quan
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('manufacturerID', isEqualTo: manufacturerId)
          .get();

      for (var doc in productsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(doc.id)
            .update({'status': 'discontinued'});
      }
    } catch (e) {
      print('Error deleting manufacturer: $e');
      rethrow;
    }
  }

  Future<void> createManufacturer(Manufacturer manufacturer) async {
    try {
      final doc = _firestore.collection('manufacturers').doc(manufacturer.manufacturerID);
      await doc.set(_mapManufacturerToJson(manufacturer));
    } catch (e) {
      print('Error creating manufacturer: $e');
      rethrow;
    }
  }

  Future<Manufacturer?> getManufacturerById(String manufacturerId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('manufacturers')
          .where('manufacturerID', isEqualTo: manufacturerId)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final data = querySnapshot.docs.first.data();
      return Manufacturer(
        manufacturerID: data['manufacturerID'] ?? '',
        manufacturerName: data['manufacturerName'] ?? '',
        status: _mapManufacturerStatus(data['status'] as String? ?? 'active'),
      );
    } catch (e) {
      print('Error finding manufacturer by ID: $e');
      rethrow;
    }
  }

  Future<void> updateUserInformation(String userId, Map<String, dynamic> userData) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(userData);
    } catch (e) {
      print('Lỗi khi cập nhật thông tin user: $e');
      rethrow;
    }
  }

  Future<bool> checkUserExistsInDatabase(String email) async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return userSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user exists in database: $e');
      rethrow;
    }
  }

  // Product-related functions
  Future<List<Product>> getProducts() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      List<Product> products = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Lấy manufacturer từ manufacturerID
        String manufacturerId = data['manufacturerID'];
        Manufacturer? manufacturer = await getManufacturerById(manufacturerId);
        if (manufacturer == null) continue;

        // Chuyển đổi category string thành enum
        CategoryEnum category = CategoryEnum.nonEmptyValues.firstWhere(
          (e) => e.getName() == data['category'],
          orElse: () => CategoryEnum.ram,
        );

        // Tạo product với các thuộc tính cơ bản
        Map<String, dynamic> productProps = {
          'productID': doc.id,
          'productName': data['productName'],
          'manufacturer': manufacturer,
          'importPrice': (data['importPrice'] as num).toDouble(),
          'sellingPrice': (data['sellingPrice'] as num).toDouble(),
          'discount': (data['discount'] as num).toDouble(),
          'release': (data['release'] as Timestamp).toDate(),
          'sales': data['sales'] as int,
          'stock': data['stock'] as int,
          'status': ProductStatusEnum.values.firstWhere(
            (e) => e.getName() == data['status'],
            orElse: () => ProductStatusEnum.active,
          ),
        };

        // Thêm các thuộc tính đặc thù theo category
        switch (category) {
          case CategoryEnum.ram:
            productProps.addAll({
              'bus': RAMBus.values.firstWhere(
                (e) => e.getName() == data['bus'],
                orElse: () => RAMBus.mhz3200,
              ),
              'capacity': RAMCapacity.values.firstWhere(
                (e) => e.getName() == data['capacity'],
                orElse: () => RAMCapacity.gb8,
              ),
              'ramType': RAMType.values.firstWhere(
                (e) => e.getName() == data['ramType'],
                orElse: () => RAMType.ddr4,
              ),
            });
            break;
          case CategoryEnum.cpu:
            productProps.addAll({
              'family': CPUFamily.values.firstWhere(
                (e) => e.getName() == data['family'],
                orElse: () => CPUFamily.corei3Ultra3,
              ),
              'core': data['core'] as int,
              'thread': data['thread'] as int,
              'clockSpeed': (data['clockSpeed'] as num).toDouble(),
            });
            break;
          case CategoryEnum.gpu:
            productProps.addAll({
              'series': GPUSeries.values.firstWhere(
                (e) => e.getName() == data['series'],
                orElse: () => GPUSeries.rtx,
              ),
              'capacity': GPUCapacity.values.firstWhere(
                (e) => e.getName() == data['capacity'],
                orElse: () => GPUCapacity.gb8,
              ),
              'busWidth': GPUBus.values.firstWhere(
                (e) => e.getName() == data['busWidth'],
                orElse: () => GPUBus.bit128,
              ),
              'clockSpeed': (data['clockSpeed'] as num).toDouble(),
            });
            break;
          case CategoryEnum.mainboard:
            productProps.addAll({
              'formFactor': MainboardFormFactor.values.firstWhere(
                (e) => e.getName() == data['formFactor'],
                orElse: () => MainboardFormFactor.atx,
              ),
              'series': MainboardSeries.values.firstWhere(
                (e) => e.getName() == data['series'],
                orElse: () => MainboardSeries.h,
              ),
              'compatibility': MainboardCompatibility.values.firstWhere(
                (e) => e.getName() == data['compatibility'],
                orElse: () => MainboardCompatibility.intel,
              ),
            });
            break;
          case CategoryEnum.drive:
            productProps.addAll({
              'type': DriveType.values.firstWhere(
                (e) => e.getName() == data['type'],
                orElse: () => DriveType.sataSSD,
              ),
              'capacity': DriveCapacity.values.firstWhere(
                (e) => e.getName() == data['capacity'],
                orElse: () => DriveCapacity.gb256,
              ),
            });
            break;
          case CategoryEnum.psu:
            productProps.addAll({
              'wattage': data['wattage'] as int,
              'efficiency': PSUEfficiency.values.firstWhere(
                (e) => e.getName() == data['efficiency'],
                orElse: () => PSUEfficiency.gold,
              ),
              'modular': PSUModular.values.firstWhere(
                (e) => e.getName() == data['modular'],
                orElse: () => PSUModular.fullModular,
              ),
            });
            break;
          default:
            print('Unknown category: ${data['category']}');
        }

        // Tạo product instance thông qua factory
        Product product = ProductFactory.createProduct(category, productProps);
        products.add(product);
      }

      return products;
    } catch (e) {
      print('Error getting products: $e');
      rethrow;
    }
  }

  Stream<List<Product>> productsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Product> products = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data();
          
          String manufacturerId = data['manufacturerID'];
          Manufacturer? manufacturer = await getManufacturerById(manufacturerId);
          if (manufacturer == null) continue;

          CategoryEnum category = CategoryEnum.nonEmptyValues.firstWhere(
            (e) => e.getName() == data['category'],
            orElse: () => CategoryEnum.ram,
          );

          Map<String, dynamic> productProps = {
            'productID': doc.id,
            'productName': data['productName'],
            'manufacturer': manufacturer,
            'importPrice': (data['importPrice'] as num).toDouble(),
            'sellingPrice': (data['sellingPrice'] as num).toDouble(),
            'discount': (data['discount'] as num).toDouble(),
            'release': (data['release'] as Timestamp).toDate(),
            'sales': data['sales'] as int,
            'stock': data['stock'] as int,
            'status': ProductStatusEnum.values.firstWhere(
              (e) => e.getName() == data['status'],
              orElse: () => ProductStatusEnum.active,
            ),
          };

          switch (category) {
            case CategoryEnum.ram:
              productProps.addAll({
                'bus': RAMBus.values.firstWhere(
                  (e) => e.getName() == data['bus'],
                  orElse: () => RAMBus.mhz3200,
                ),
                'capacity': RAMCapacity.values.firstWhere(
                  (e) => e.getName() == data['capacity'],
                  orElse: () => RAMCapacity.gb8,
                ),
                'ramType': RAMType.values.firstWhere(
                  (e) => e.getName() == data['ramType'],
                  orElse: () => RAMType.ddr4,
                ),
              });
              break;

            case CategoryEnum.cpu:
              productProps.addAll({
                'family': CPUFamily.values.firstWhere(
                  (e) => e.getName() == data['family'],
                  orElse: () => CPUFamily.corei3Ultra3,
                ),
                'core': data['core'],
                'thread': data['thread'],
                'clockSpeed': (data['clockSpeed'] as num).toDouble(),
              });
              break;

            case CategoryEnum.gpu:
              productProps.addAll({
                'series': GPUSeries.values.firstWhere(
                  (e) => e.getName() == data['series'],
                  orElse: () => GPUSeries.rtx,
                ),
                'capacity': GPUCapacity.values.firstWhere(
                  (e) => e.getName() == data['capacity'],
                  orElse: () => GPUCapacity.gb4,
                ),
                'busWidth': GPUBus.values.firstWhere(
                  (e) => e.getName() == data['busWidth'],
                  orElse: () => GPUBus.bit128,
                ),
                'clockSpeed': (data['clockSpeed'] as num).toDouble(),
              });
              break;

            case CategoryEnum.mainboard:
              productProps.addAll({
                'formFactor': MainboardFormFactor.values.firstWhere(
                  (e) => e.getName() == data['formFactor'],
                  orElse: () => MainboardFormFactor.atx,
                ),
                'series': MainboardSeries.values.firstWhere(
                  (e) => e.getName() == data['series'],
                  orElse: () => MainboardSeries.h,
                ),
                'compatibility': MainboardCompatibility.values.firstWhere(
                  (e) => e.getName() == data['compatibility'],
                  orElse: () => MainboardCompatibility.intel,
                ),
              });
              break;

            case CategoryEnum.drive:
              productProps.addAll({
                'type': DriveType.values.firstWhere(
                  (e) => e.getName() == data['type'],
                  orElse: () => DriveType.sataSSD,
                ),
                'capacity': DriveCapacity.values.firstWhere(
                  (e) => e.getName() == data['capacity'],
                  orElse: () => DriveCapacity.gb256,
                ),
              });
              break;

            case CategoryEnum.psu:
              productProps.addAll({
                'wattage': data['wattage'] as int,
                'efficiency': PSUEfficiency.values.firstWhere(
                  (e) => e.getName() == data['efficiency'],
                  orElse: () => PSUEfficiency.bronze,
                ),
                'modular': PSUModular.values.firstWhere(
                  (e) => e.getName() == data['modular'],
                  orElse: () => PSUModular.nonModular,
                ),
              });
              break;

            default:
              print('Unknown category: ${data['category']}');
          }

          Product product = ProductFactory.createProduct(category, productProps);
          products.add(product);
        } catch (e) {
          print('Error processing product ${doc.id}: $e');
          continue;
        }
      }
      return products;
    });
  }

  Future<List<SalesInvoice>> getSalesInvoices() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('sales_invoices')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return SalesInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error loading sales invoices: $e');
      rethrow;
    }
  }

  Stream<List<SalesInvoice>> salesInvoicesStream() {
    return _firestore
        .collection('sales_invoices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SalesInvoice.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> updateSalesInvoice(SalesInvoice invoice) async {
    try {
      await FirebaseFirestore.instance
          .collection('sales_invoices')
          .doc(invoice.salesInvoiceID)
          .update({
            ...invoice.toMap(),
            'paymentStatus': invoice.paymentStatus.toString(),
            'salesStatus': invoice.salesStatus.toString(),
          });
    } catch (e) {
      print('Error updating sales invoice: $e');
      rethrow;
    }
  }

  Future<String> createSalesInvoice(SalesInvoice invoice) async {
    try {
      // Tạo document mới và lấy ID
      final docRef = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .add({
            ...invoice.toMap(),
            'date': Timestamp.fromDate(invoice.date),
            'paymentStatus': invoice.paymentStatus.toString(),
            'salesStatus': invoice.salesStatus.toString(),
          });

      // Cập nhật lại document với ID
      await docRef.update({
        'salesInvoiceID': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      print('Error creating sales invoice: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCustomerDetails(String customerID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerID)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'customerName': data['customerName'] ?? 'Unknown Customer',
          'phoneNumber': data['phoneNumber'],
          'email': data['email'],
        };
      }
      return {
        'customerName': 'Unknown Customer',
        'phoneNumber': '',
        'email': '',
      };
    } catch (e) {
      print('Error getting customer details: $e');
      return {
        'customerName': 'Unknown Customer',
        'phoneNumber': '',
        'email': '',
      };
    }
  }

  Future<Map<String, dynamic>> getProductDetails(String productID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productID)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'productName': data['productName'] ?? 'Unknown Product',
          'category': data['category'] ?? '',
          'manufacturer': data['manufacturer'],
          'importPrice': data['importPrice'],
          'sellingPrice': data['sellingPrice'],
        };
      }

      return {
        'productName': 'Unknown Product',
        'category': '',
        'manufacturer': '',
        'importPrice': 0,
        'sellingPrice': 0,
      };
    } catch (e) {
      return {
        'productName': 'Unknown Product',
        'category': '',
        'manufacturer': '',
        'importPrice': 0,
        'sellingPrice': 0,
      };
    }
  }

  Future<SalesInvoice> getSalesInvoiceWithDetails(String invoiceID) async {
    try {
      // Lấy thông tin hóa đơn
      final invoiceDoc = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .doc(invoiceID)
          .get();

      if (!invoiceDoc.exists) {
        throw Exception('Invoice not found');
      }

      final invoice = SalesInvoice.fromMap(invoiceID, invoiceDoc.data()!);

      // Lấy thông tin khách hàng
      final customerDetails = await getCustomerDetails(invoice.customerID);
      invoice.customerName = customerDetails['customerName'];

      // Lấy chi tiết hóa đơn và thông tin sản phẩm
      final detailsSnapshot = await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .where('salesInvoiceID', isEqualTo: invoiceID)
          .get();

      List<SalesInvoiceDetail> details = [];
      for (var doc in detailsSnapshot.docs) {
        final detailData = doc.data();
        final productDetails = await getProductDetails(detailData['productID']);

        details.add(SalesInvoiceDetail(
          salesInvoiceDetailID: doc.id,
          salesInvoiceID: detailData['salesInvoiceID'],
          productID: detailData['productID'],
          productName: productDetails['productName'],
          category: productDetails['category'],
          sellingPrice: detailData['sellingPrice'].toDouble(),
          quantity: detailData['quantity'],
          subtotal: detailData['subtotal'].toDouble(),
        ));
      }

      invoice.details = details;
      return invoice;
    } catch (e) {
      print('Error getting invoice with details: $e');
      rethrow;
    }
  }

  Future<void> updateSalesInvoiceDetail(SalesInvoiceDetail detail) async {
    try {
      // Cập nhật chi tiết hóa đơn
      await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .doc(detail.salesInvoiceDetailID)
          .update(detail.toMap());

      // Cập nhật stock của sản phẩm
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(detail.productID)
          .get();

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final oldDetail = await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .doc(detail.salesInvoiceDetailID)
          .get();

      if (oldDetail.exists) {
        final oldQuantity = oldDetail.data()?['quantity'] ?? 0;
        // Đảm bảo các giá trị không null khi tính toán
        final stockChange = (oldQuantity as int) - detail.quantity;
        await updateProductStock(detail.productID, stockChange);
      }
    } catch (e) {
      print('Error updating sales invoice detail: $e');
      rethrow;
    }
  }

  Future<void> deleteSalesInvoiceDetail(String detailId) async {
    try {
      // Lấy thông tin chi tiết trước khi xóa
      final detailDoc = await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .doc(detailId)
          .get();

      if (!detailDoc.exists) {
        throw Exception('Invoice detail not found');
      }

      final productId = detailDoc.data()?['productID'];
      final quantity = detailDoc.data()?['quantity'] ?? 0;

      // Xóa chi tiết hóa đơn
      await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .doc(detailId)
          .delete();

      // Hoàn lại stock
      if (productId != null) {
        await updateProductStock(productId, quantity);
      }
    } catch (e) {
      print('Error deleting sales invoice detail: $e');
      rethrow;
    }
  }

  Future<void> updateProductStock(String productID, int stockChange) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productID)
          .get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      // Đảm bảo currentStock không null
      final currentStock = doc.data()?['stock'] as int? ?? 0;
      
      await doc.reference.update({
        'stock': currentStock + stockChange
      });
    } catch (e) {
      print('Error updating product stock: $e');
      rethrow;
    }
  }

  Future<void> createSalesInvoiceDetail(SalesInvoiceDetail detail) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .add(detail.toMap());

      await docRef.update({
        'salesInvoiceDetailID': docRef.id,
      });
    } catch (e) {
      print('Error creating sales invoice detail: $e');
      rethrow;
    }
  }

  Future<void> changeProductStatus(String productId, ProductStatusEnum status) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({'status': status.getName()});

      List<Product> products = await getProducts();
      Database().updateProductList(products);
    } catch (e) {
      print('Error changing product status: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      Map<String, dynamic> productData = {
        'productName': product.productName,
        'importPrice': product.importPrice,
        'sellingPrice': product.sellingPrice,
        'discount': product.discount,
        'release': product.release,
        'sales': product.sales,
        'stock': product.stock,
        'status': product.status.getName(),
        'manufacturerID': product.manufacturer.manufacturerID,
        'category': product.category.getName(),
      };

      switch (product.runtimeType) {
        case RAM:
          final ram = product as RAM;
          productData.addAll({
            'bus': ram.bus.getName(),
            'capacity': ram.capacity.getName(),
            'ramType': ram.ramType.getName(),
          });
          break;

        case CPU:
          final cpu = product as CPU;
          productData.addAll({
            'family': cpu.family.getName(),
            'core': cpu.core,
            'thread': cpu.thread,
            'clockSpeed': cpu.clockSpeed,
          });
          break;

        case GPU:
          final gpu = product as GPU;
          productData.addAll({
            'series': gpu.series.getName(),
            'capacity': gpu.capacity.getName(),
            'busWidth': gpu.bus.getName(),
            'clockSpeed': gpu.clockSpeed,
          });
          break;

        case Mainboard:
          final mainboard = product as Mainboard;
          productData.addAll({
            'formFactor': mainboard.formFactor.getName(),
            'series': mainboard.series.getName(),
            'compatibility': mainboard.compatibility.getName(),
          });
          break;

        case Drive:
          final drive = product as Drive;
          productData.addAll({
            'type': drive.type.getName(),
            'capacity': drive.capacity.getName(),
          });
          break;

        case PSU:
          final psu = product as PSU;
          productData.addAll({
            'wattage': psu.wattage,
            'efficiency': psu.efficiency.getName(),
            'modular': psu.modular.getName(),
          });
          break;
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productID)
          .update(productData);

      List<Product> products = await getProducts();
      Database().updateProductList(products);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      // Tạo map chứa thông tin cơ bản của sản phẩm
      Map<String, dynamic> productData = {
        'productName': product.productName,
        'importPrice': product.importPrice,
        'sellingPrice': product.sellingPrice, 
        'discount': product.discount,
        'release': product.release,
        'sales': product.sales,
        'stock': product.stock,
        'status': product.status.getName(),
        'manufacturerID': product.manufacturer.manufacturerID,
        'category': product.category.getName(),
      };

      // Thêm các thuộc tính đặc thù theo từng loại sản phẩm
      switch (product.runtimeType) {
        case RAM:
          final ram = product as RAM;
          productData.addAll({
            'bus': ram.bus.getName(),
            'capacity': ram.capacity.getName(),
            'ramType': ram.ramType.getName(),
          });
          break;

        case CPU:
          final cpu = product as CPU;
          productData.addAll({
            'family': cpu.family.getName(),
            'core': cpu.core,
            'thread': cpu.thread,
            'clockSpeed': cpu.clockSpeed,
          });
          break;

        case GPU:
          final gpu = product as GPU;
          productData.addAll({
            'series': gpu.series.getName(),
            'capacity': gpu.capacity.getName(),
            'busWidth': gpu.bus.getName(),
            'clockSpeed': gpu.clockSpeed,
          });
          break;

        case Mainboard:
          final mainboard = product as Mainboard;
          productData.addAll({
            'formFactor': mainboard.formFactor.getName(),
            'series': mainboard.series.getName(),
            'compatibility': mainboard.compatibility.getName(),
          });
          break;

        case Drive:
          final drive = product as Drive;
          productData.addAll({
            'type': drive.type.getName(),
            'capacity': drive.capacity.getName(),
          });
          break;

        case PSU:
          final psu = product as PSU;
          productData.addAll({
            'wattage': psu.wattage,
            'efficiency': psu.efficiency.getName(),
            'modular': psu.modular.getName(),
          });
          break;
      }

      await FirebaseFirestore.instance.collection('products').add(productData);

      List<Product> products = await getProducts();
      Database().updateProductList(products);
    } catch (e) {
      print('Lỗi khi thêm sản phẩm: $e');
      rethrow;
    }
  }

  Future<void> updateProductStockAndSales(String productID, int stockChange, int salesChange) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productID)
          .get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      // Đảm bảo các giá trị không null
      final currentStock = doc.data()?['stock'] as int? ?? 0;
      final currentSales = doc.data()?['sales'] as int? ?? 0;
      
      // Cập nhật cả stock và sales
      await doc.reference.update({
        'stock': currentStock + stockChange,
        'sales': currentSales + salesChange
      });

      // Cập nhật danh sách sản phẩm trong Database
      List<Product> products = await getProducts();
      Database().updateProductList(products);
    } catch (e) {
      print('Error updating product stock and sales: $e');
      rethrow;
    }
  }

  Future<void> changeSalesInvoiceStatus(SalesInvoice salesInvoice) async {
    try {
      await _firestore.collection('sales_invoices')
          .doc(salesInvoice.salesInvoiceID).update({
        'salesStatus': SalesStatus.completed.getName(),
      });

      //await Database().fetchSalesInvoice();
    } catch (e) {
      print('Error confirming delivery: $e');
      rethrow;
    }
  }

  Future<List<Address>> getCustomerAddresses(String customerID) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .where('customerID', isEqualTo: customerID)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Address(
          addressID: doc.id,
          customerID: data['customerID'],
          receiverName: data['receiverName'],
          receiverPhone: data['receiverPhone'],
          province: Database().provinceList.firstWhere(
            (p) => p.code == data['provinceCode'],
            orElse: () => Province.nullProvince,
          ),
          district: Database().provinceList
            .firstWhere(
              (p) => p.code == data['provinceCode'],
              orElse: () => Province.nullProvince,
            )
            .districts
            ?.firstWhere(
              (d) => d.code == data['districtCode'],
              orElse: () => District.nullDistrict,
            ),
          ward: Database().provinceList
            .firstWhere(
              (p) => p.code == data['provinceCode'],
              orElse: () => Province.nullProvince,
            )
            .districts
            ?.firstWhere(
              (d) => d.code == data['districtCode'],
              orElse: () => District.nullDistrict,
            )
            .wards
            ?.firstWhere(
              (w) => w.code == data['wardCode'],
              orElse: () => Ward.nullWard,
            ),
          street: data['street'],
          isDefault: data['isDefault'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error getting customer addresses: $e');
      rethrow;
    }
  }

  // Incoming Invoice Methods
  Stream<List<IncomingInvoice>> incomingInvoicesStream() {
    return _firestore
        .collection('incoming_invoices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return IncomingInvoice.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<IncomingInvoice>> getIncomingInvoices() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('incoming_invoices')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return IncomingInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error loading incoming invoices: $e');
      rethrow;
    }
  }

  Future<IncomingInvoice> getIncomingInvoiceWithDetails(String invoiceId) async {
    try {
      // Get the invoice
      final DocumentSnapshot invoiceDoc = await _firestore
          .collection('incoming_invoices')
          .doc(invoiceId)
          .get();

      if (!invoiceDoc.exists) {
        throw Exception('Invoice not found');
      }

      // Create invoice object
      IncomingInvoice invoice = IncomingInvoice.fromMap(
        invoiceDoc.id,
        invoiceDoc.data() as Map<String, dynamic>,
      );

      // Get invoice details
      final QuerySnapshot detailsSnapshot = await _firestore
          .collection('incoming_invoice_details')
          .where('incomingInvoiceID', isEqualTo: invoiceId)
          .get();

      // Add details to invoice
      invoice.details = detailsSnapshot.docs.map((doc) {
        return IncomingInvoiceDetail.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      return invoice;
    } catch (e) {
      print('Error loading incoming invoice details: $e');
      rethrow;
    }
  }

  Future<void> updateIncomingInvoice(IncomingInvoice invoice) async {
    try {
      if (invoice.incomingInvoiceID == null) {
        throw Exception('Invoice ID cannot be null');
      }

      // Update invoice
      await _firestore
          .collection('incoming_invoices')
          .doc(invoice.incomingInvoiceID)
          .update(invoice.toMap());

      // Update details
      for (var detail in invoice.details) {
        if (detail.incomingInvoiceDetailID != null) {
          await _firestore
              .collection('incoming_invoice_details')
              .doc(detail.incomingInvoiceDetailID)
              .update(detail.toMap());
        } else {
          // Create new detail if it doesn't exist
          final docRef = await _firestore
              .collection('incoming_invoice_details')
              .add(detail.toMap());

          await docRef.update({
            'incomingInvoiceDetailID': docRef.id,
          });
        }
      }
    } catch (e) {
      print('Error updating incoming invoice: $e');
      rethrow;
    }
  }

  Future<String> createIncomingInvoice(IncomingInvoice invoice) async {
    try {
      // Create invoice
      final docRef = await _firestore
          .collection('incoming_invoices')
          .add(invoice.toMap());

      // Update invoice with ID
      await docRef.update({
        'incomingInvoiceID': docRef.id,
      });

      // Create details
      for (var detail in invoice.details) {
        detail.incomingInvoiceID = docRef.id;
        final detailRef = await _firestore
            .collection('incoming_invoice_details')
            .add(detail.toMap());

        await detailRef.update({
          'incomingInvoiceDetailID': detailRef.id,
        });
      }

      return docRef.id;
    } catch (e) {
      print('Error creating incoming invoice: $e');
      rethrow;
    }
  }

  Future<void> deleteIncomingInvoice(String invoiceId) async {
    try {
      // Delete invoice details first
      final QuerySnapshot detailsSnapshot = await _firestore
          .collection('incoming_invoice_details')
          .where('incomingInvoiceID', isEqualTo: invoiceId)
          .get();

      for (var doc in detailsSnapshot.docs) {
        await _firestore
            .collection('incoming_invoice_details')
            .doc(doc.id)
            .delete();
      }

      // Delete invoice
      await _firestore
          .collection('incoming_invoices')
          .doc(invoiceId)
          .delete();
    } catch (e) {
      print('Error deleting incoming invoice: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole([String? userID]) async {
    try {
      final id = userID ?? currentUserId;
      if (id == null) return null;

      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<Customer> getCustomer(String customerId) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();

      if (!doc.exists) {
        throw Exception('Customer not found');
      }

      return Customer.fromMap(doc.id, doc.data()!);
    } catch (e) {
      print('Error getting customer: $e');
      rethrow;
    }
  }

  Future<Product?> getProduct(String productId) async {
    try {
      print('Getting product: $productId');
      
      final doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!doc.exists) {
        print('Product not found: $productId');
        return null;
      }

      final data = Map<String, dynamic>.from(doc.data()!);
      data['productID'] = doc.id;
      
      // Convert Timestamp to DateTime
      if (data['release'] is Timestamp) {
        data['release'] = (data['release'] as Timestamp).toDate();
      }
      
      // Get manufacturer data
      final manufacturerDoc = await _firestore
          .collection('manufacturers')
          .doc(data['manufacturerID'] as String)
          .get();

      if (!manufacturerDoc.exists) {
        print('Manufacturer not found for product $productId');
        return null;
      }

      // Add manufacturer to product data
      data['manufacturer'] = _mapManufacturerFromJson(
        manufacturerDoc.data()!,
        manufacturerDoc.id,
      );
      
      final categoryStr = (data['category'] as String).toLowerCase();
      print('Product category: $categoryStr');
      
      CategoryEnum? category;
      try {
        category = CategoryEnum.values.firstWhere(
          (e) => e.getName().toLowerCase() == categoryStr,
        );

        // Convert enums based on category
        if (category == CategoryEnum.drive) {
          // Convert drive-specific enums
          data['type'] = DriveType.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['type'] as String).toLowerCase(),
            orElse: () => DriveType.hdd,
          );
          
          data['capacity'] = DriveCapacity.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['capacity'] as String).toLowerCase(),
            orElse: () => DriveCapacity.gb256,
          );
        }

        if (category == CategoryEnum.ram) {
          // Convert RAM-specific enums
          data['bus'] = RAMBus.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['bus'] as String).toLowerCase(),
            orElse: () => RAMBus.mhz3200,
          );

          data['capacity'] = RAMCapacity.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['capacity'] as String).toLowerCase(),
            orElse: () => RAMCapacity.gb8,
          );

          data['ramType'] = RAMType.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['ramType'] as String).toLowerCase(),
            orElse: () => RAMType.ddr4,
          );
        }

        if (category == CategoryEnum.cpu) {
          // Convert CPU-specific enums
          data['family'] = CPUFamily.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['family'] as String).toLowerCase(),
            orElse: () => CPUFamily.corei3Ultra3,
          );
        }

        if (category == CategoryEnum.gpu) {
          // Convert GPU-specific enums
          data['series'] = GPUSeries.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['series'] as String).toLowerCase(),
            orElse: () => GPUSeries.rtx,
          );

          data['capacity'] = GPUCapacity.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['capacity'] as String).toLowerCase(),
            orElse: () => GPUCapacity.gb4,
          );

          data['busWidth'] = GPUBus.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['busWidth'] as String).toLowerCase(),
            orElse: () => GPUBus.bit128,
          );
        }

        if (category == CategoryEnum.mainboard) {
          // Convert mainboard-specific enums
          data['formFactor'] = MainboardFormFactor.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['formFactor'] as String).toLowerCase(),
            orElse: () => MainboardFormFactor.atx,
          );

          data['series'] = MainboardSeries.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['series'] as String).toLowerCase(),
            orElse: () => MainboardSeries.h,
          );

          data['compatibility'] = MainboardCompatibility.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['compatibility'] as String).toLowerCase(),
            orElse: () => MainboardCompatibility.intel,
          );
        }

        if (category == CategoryEnum.psu) {
          // Convert PSU-specific enums
          data['efficiency'] = PSUEfficiency.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['efficiency'] as String).toLowerCase(),
            orElse: () => PSUEfficiency.bronze,
          );

          data['modular'] = PSUModular.values.firstWhere(
            (e) => e.getName().toLowerCase() == (data['modular'] as String).toLowerCase(),
            orElse: () => PSUModular.nonModular,
          );
        }

        // Convert common enums
        data['status'] = ProductStatusEnum.values.firstWhere(
          (e) => e.getName().toLowerCase() == (data['status'] as String).toLowerCase(),
          orElse: () => ProductStatusEnum.active,
        );

      } catch (e) {
        print('Invalid category for product $productId: $categoryStr');
        return null;
      }

      final product = ProductFactory.createProduct(category, data);
      print('Created product: ${product.productName}');
      return product;
    } catch (e) {
      print('Error getting product $productId: $e');
      return null;
    }
  }

  Future<List<SalesInvoice>> getCustomerSalesInvoices(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('sales_invoices')
          .where('customerID', isEqualTo: customerId)
          .where('paymentStatus', isEqualTo: PaymentStatus.paid.toString())
          .where('salesStatus', isEqualTo: SalesStatus.completed.toString())
          .orderBy('date', descending: true)
          .get();

      return Future.wait(snapshot.docs.map((doc) async {
        final invoice = SalesInvoice.fromMap(doc.id, doc.data());
        
        // Load details
        final detailsSnapshot = await _firestore
            .collection('sales_invoice_details')
            .where('salesInvoiceID', isEqualTo: doc.id)
            .get();

        invoice.details = detailsSnapshot.docs
            .map((doc) => SalesInvoiceDetail.fromMap(doc.id, doc.data()))
            .toList();

        return invoice;
      }));
    } catch (e) {
      print('Error getting customer sales invoices: $e');
      rethrow;
    }
  }

  Future<List<WarrantyInvoice>> getWarrantyInvoices() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('warranty_invoices')
          .get();

      return snapshot.docs.map((doc) {
        return WarrantyInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error loading warranty invoices: $e');
      rethrow;
    }
  }

  Future<WarrantyInvoice> getWarrantyInvoiceWithDetails(String invoiceId) async {
    try {
      // Get the invoice
      final DocumentSnapshot invoiceDoc = await _firestore
          .collection('warranty_invoices')
          .doc(invoiceId)
          .get();

      if (!invoiceDoc.exists) {
        throw Exception('Warranty invoice not found');
      }

      // Create invoice object
      WarrantyInvoice invoice = WarrantyInvoice.fromMap(
        invoiceDoc.id,
        invoiceDoc.data() as Map<String, dynamic>,
      );

      // Get invoice details
      final QuerySnapshot detailsSnapshot = await _firestore
          .collection('warranty_invoice_details')
          .where('warrantyInvoiceID', isEqualTo: invoiceId)
          .get();

      // Add details to invoice
      invoice.details = detailsSnapshot.docs.map((doc) {
        return WarrantyInvoiceDetail.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      return invoice;
    } catch (e) {
      print('Error loading warranty invoice details: $e');
      rethrow;
    }
  }

  Stream<List<WarrantyInvoice>> warrantyInvoicesStream() {
    return _firestore
        .collection('warranty_invoices')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WarrantyInvoice.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> updateWarrantyInvoice(WarrantyInvoice invoice) async {
    try {
      await _firestore
          .collection('warranty_invoices')
          .doc(invoice.warrantyInvoiceID)
          .update(invoice.toMap());
    } catch (e) {
      print('Error updating warranty invoice: $e');
      rethrow;
    }
  }

  Future<String?> createWarrantyInvoice(WarrantyInvoice invoice) async {
    try {
      print('Starting warranty invoice creation in Firebase');
      
      // Create warranty invoice document
      final docRef = await _firestore.collection('warranty_invoices').add({
        'warrantyInvoiceID': '',  // Temporary placeholder
        'salesInvoiceID': invoice.salesInvoiceID,
        'customerName': invoice.customerName,
        'customerID': invoice.customerID,
        'date': invoice.date,
        'status': invoice.status.toString(),
        'reason': invoice.reason,
      });

      // Update the document with its own ID
      await docRef.update({
        'warrantyInvoiceID': docRef.id,
      });

      print('Created warranty invoice document with ID: ${docRef.id}');

      // Create warranty details
      final batch = _firestore.batch();
      
      for (var detail in invoice.details) {
        print('Processing detail: ${detail.toJson()}');
        
        final detailRef = _firestore.collection('warranty_invoice_details').doc();
        batch.set(detailRef, {
          'warrantyInvoiceID': docRef.id,
          'warrantyInvoiceDetailID': detailRef.id,
          'productID': detail.productID,
          'quantity': detail.quantity,
        });
      }

      await batch.commit();
      print('Successfully created warranty invoice and ${invoice.details.length} details');

      return docRef.id;
    } catch (e) {
      print('Error creating warranty invoice: $e');
      return null;
    }
  }

  Future<void> createWarrantyInvoiceDetail(WarrantyInvoiceDetail detail) async {
    try {
      final docRef = await _firestore
          .collection('warranty_invoice_details')
          .add(detail.toMap());

      await docRef.update({
        'warrantyInvoiceDetailID': docRef.id,
      });
    } catch (e) {
      print('Error creating warranty invoice detail: $e');
      rethrow;
    }
  }

  Future<void> updateManufacturerAndProducts(Manufacturer manufacturer) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();

      // Update manufacturer
      final manufacturerDoc = _firestore.collection('manufacturers').doc(manufacturer.manufacturerID);
      batch.update(manufacturerDoc, _mapManufacturerToJson(manufacturer));

      // Get all products from this manufacturer
      final productsSnapshot = await _firestore
          .collection('products')
          .where('manufacturerID', isEqualTo: manufacturer.manufacturerID)
          .get();

      // Update each product's status based on manufacturer status
      final newProductStatus = manufacturer.status == ManufacturerStatus.active
          ? ProductStatusEnum.active
          : ProductStatusEnum.discontinued;

      for (var doc in productsSnapshot.docs) {
        final productDoc = _firestore.collection('products').doc(doc.id);
        batch.update(productDoc, {
          'status': newProductStatus.getName(),
        });
      }

      // Commit all changes
      await batch.commit();
    } catch (e) {
      print('Error updating manufacturer and products: $e');
      rethrow;
    }
  }

  Future<void> updateUsername(String newUsername) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update username in users collection
      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
      });

      // Get user role to determine if additional updates are needed
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'] as String?;

      // Update name in respective collection based on role
      if (role == 'customer') {
        final customerDoc = await _firestore
            .collection('customers')
            .where('email', isEqualTo: user.email)
            .get();
        if (customerDoc.docs.isNotEmpty) {
          await _firestore
              .collection('customers')
              .doc(customerDoc.docs.first.id)
              .update({'customerName': newUsername});
        }
      } else if (role == 'admin' || role == 'employee') {
        final employeeDoc = await _firestore
            .collection('employees')
            .where('email', isEqualTo: user.email)
            .get();
        if (employeeDoc.docs.isNotEmpty) {
          await _firestore
              .collection('employees')
              .doc(employeeDoc.docs.first.id)
              .update({'employeeName': newUsername});
        }
      }
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }
}

Manufacturer _mapManufacturerFromJson(Map<String, dynamic> json, String id) {
  return Manufacturer(
    manufacturerID: id,
    manufacturerName: json['manufacturerName'] as String,
    status: _mapManufacturerStatus(json['status'] as String? ?? 'active'),
  );
}

Map<String, dynamic> _mapManufacturerToJson(Manufacturer manufacturer) {
  return {
    'manufacturerName': manufacturer.manufacturerName,
    'status': manufacturer.status.toString().split('.').last,
  };
}

ManufacturerStatus _mapManufacturerStatus(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return ManufacturerStatus.active;
    case 'inactive':
      return ManufacturerStatus.inactive;
    default:
      return ManufacturerStatus.active;
  }
}