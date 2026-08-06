class NumberToWords {
  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convert(double number) {
    if (number == 0) return 'Zero Rupees only';
    
    int rupees = number.toInt();
    int paise = ((number - rupees) * 100).round();

    String rupeesStr = _convertInteger(rupees) + ' Rupees';
    String paiseStr = paise > 0 ? ' and ' + _convertInteger(paise) + ' Paise' : '';

    return rupeesStr + paiseStr + ' only';
  }

  static String _convertInteger(int number) {
    if (number < 0) return 'Minus ' + _convertInteger(-number);
    if (number == 0) return '';

    if (number < 20) {
      return _ones[number];
    }

    if (number < 100) {
      return _tens[number ~/ 10] + ((number % 10 != 0) ? ' ' + _ones[number % 10] : '');
    }

    if (number < 1000) {
      return _ones[number ~/ 100] + ' Hundred' + ((number % 100 != 0) ? ' and ' + _convertInteger(number % 100) : '');
    }

    if (number < 100000) { // Thousand (1,000 to 99,999)
      return _convertInteger(number ~/ 1000) + ' Thousand' + ((number % 1000 != 0) ? ' ' + _convertInteger(number % 1000) : '');
    }

    if (number < 10000000) { // Lakh (1,00,000 to 99,99,999)
      return _convertInteger(number ~/ 100000) + ' Lakh' + ((number % 100000 != 0) ? ' ' + _convertInteger(number % 100000) : '');
    }

    // Crore
    return _convertInteger(number ~/ 10000000) + ' Crore' + ((number % 10000000 != 0) ? ' ' + _convertInteger(number % 10000000) : '');
  }
}
