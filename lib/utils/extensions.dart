import 'dart:math';

extension DoubleExtensions on double {
  double toPrecision(int fractionDigits) {
    final multiplier = pow(10, fractionDigits);
    return (this * multiplier).roundToDouble() / multiplier;
  }
}

extension IntExtensions on int {
  String toPercentage() => '$this%';
}