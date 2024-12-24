import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import '../../../objects/employee.dart';
import 'employees_screen_state.dart';

class EmployeesScreenCubit extends Cubit<EmployeesScreenState> {
  final _firebase = Firebase();
  late final Stream<List<Employee>> _employeesStream;
  StreamSubscription<List<Employee>>? _subscription;

  EmployeesScreenCubit() : super(const EmployeesScreenState()) {
    _employeesStream = _firebase.employeesStream();
    _listenToEmployees();
    loadEmployees();
  }

  void _listenToEmployees() {
    _subscription = _employeesStream.listen((employees) {
      if (state.searchQuery.isEmpty) {
        emit(state.copyWith(employees: employees));
      } else {
        searchEmployees(state.searchQuery);
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> loadEmployees() async {
    emit(state.copyWith(isLoading: true));
    try {
      final employees = await _firebase.getEmployees();
      emit(state.copyWith(
        employees: employees,
        isLoading: false,
      ));
    } catch (e) {
      print('Lỗi khi tải danh sách nhân viên: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  void searchEmployees(String query) {
    emit(state.copyWith(searchQuery: query));
    
    if (query.isEmpty) {
      loadEmployees();
      return;
    }

    final filteredEmployees = state.employees.where((employee) {
      return employee.employeeName.toLowerCase().contains(query.toLowerCase()) ||
          employee.email.toLowerCase().contains(query.toLowerCase()) ||
          employee.phoneNumber.contains(query) ||
          employee.role.toString().contains(query);
    }).toList();

    emit(state.copyWith(employees: filteredEmployees));
  }

  void setSelectedIndex(int? index) {
    emit(state.copyWith(selectedIndex: index));
  }

  Future<void> updateEmployee(Employee employee) async {
    try {
      await _firebase.updateEmployee(employee);
      // No need to manually update state as the stream will handle it
    } catch (e) {
      print('Error updating employee: $e');
      // You might want to handle the error appropriately
    }
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firebase.deleteEmployee(employeeId);
      // No need to manually update state as the stream will handle it
    } catch (e) {
      print('Error deleting employee: $e');
      // You might want to handle the error appropriately
    }
  }
}
