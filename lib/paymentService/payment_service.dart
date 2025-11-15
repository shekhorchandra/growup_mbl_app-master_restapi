import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class PaymentService {
  static final String _baseUrlSuccess = '${ApiConstants.baseUrl}/sslcommerz/payment/success';
  static final String _baseUrlFail = '${ApiConstants.baseUrl}/sslcommerz/payment/success';
  static final String _baseUrlCancel = '${ApiConstants.baseUrl}/sslcommerz/payment/success';

  static final String _baseUrlShurjoPay = '${ApiConstants.baseUrl}/shurjopay/payment/callback';

  static Uri? url = null;

  /// Fetch payment success info from API
  static Future<String> fetchPaymentSuccess(String transactionId, String status) async {
    try {
      if(status == "VALID"){
        url = Uri.parse('$_baseUrlSuccess?transaction_id=$transactionId');
      } else if(status == "FAILED"){
        url = Uri.parse('$_baseUrlFail?transaction_id=$transactionId');
      } else if(status == "Closed"){
        url = Uri.parse('$_baseUrlCancel?transaction_id=$transactionId');
      } else if (status == "ShurjoPay"){
        url = Uri.parse('$_baseUrlShurjoPay?order_id=$transactionId');
      } else {
        url = Uri.parse('$_baseUrlCancel?transaction_id=$transactionId');
      }

      print('🔗 Calling: $url');

      final response = await http.get(url!);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Payment Success Response: $data');
        return "success";
      } else {
        print('API failed with status: ${response.statusCode}');
        print('Body: ${response.body}');
        return "failed";
      }
    } catch (e) {
      print('Error: $e');
      return "failed";
    }
  }
}
