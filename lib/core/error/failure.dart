import 'package:equatable/equatable.dart';

class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.isNetwork = false});

  final String message;
  final bool isNetwork;

  /// Normalises any thrown object into a [Failure] the UI can show.
  factory Failure.from(Object error) {
    if (error is Failure) return error;
    return const Failure('Something went wrong. Please try again.');
  }

  @override
  List<Object?> get props => [message, isNetwork];
}
