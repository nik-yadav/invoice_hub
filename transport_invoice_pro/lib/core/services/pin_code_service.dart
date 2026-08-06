import 'dart:convert';
import 'package:http/http.dart' as http;

class PinCodeDetails {
  final String city;
  final String district;
  final String state;
  final String address;

  PinCodeDetails({
    required this.city,
    required this.district,
    required this.state,
    required this.address,
  });
}

class PinCodeService {
  static Future<PinCodeDetails?> fetchDetails(String pinCode) async {
    if (pinCode.length != 6) return null;

    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pinCode'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final List<dynamic> postOffices = data[0]['PostOffice'];
          if (postOffices.isNotEmpty) {
            final first = postOffices[0];
            final city = first['Block'] ?? first['Name'] ?? '';
            final district = first['District'] ?? '';
            final state = first['State'] ?? '';
            final name = first['Name'] ?? '';
            
            final address = '$name, $city, $district, $state - $pinCode';

            return PinCodeDetails(
              city: city,
              district: district,
              state: state,
              address: address,
            );
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
