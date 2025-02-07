import 'package:equatable/equatable.dart';

class Owner extends Equatable {
  final String name;
  const Owner({required this.name});
  @override
  List<Object?> get props => [name];
}
