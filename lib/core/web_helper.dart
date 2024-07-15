import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendImageToServer(Uint8List imageBytes) async {
  final uri = Uri.parse('https://skynse.pythonanywhere.com/predict');

  // Create multipart request
  var request = http.MultipartRequest('POST', uri)
    ..files.add(http.MultipartFile.fromBytes('image', imageBytes,
        filename: 'image.png'));

  // Send the request and get the response
  var response = await request.send();
  var responseString = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    var responseData = json.decode(responseString);
    if (responseData['success']) {
      // Handle success
      print('Predictions: ${responseData['predictions']}');
    } else {
      print('Failed to get predictions.');
    }
  } else {
    print('Server error: ${response.statusCode}');
  }
}
