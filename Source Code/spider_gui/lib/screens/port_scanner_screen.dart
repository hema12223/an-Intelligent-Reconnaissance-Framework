import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PortScannerPage extends StatefulWidget {
  const PortScannerPage({super.key});

  @override
  _PortScannerPageState createState() => _PortScannerPageState();
}

class _PortScannerPageState extends State<PortScannerPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> scanResults = [];
  bool isLoading = false;

  Future<void> startScan() async {
    String domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      isLoading = true;
      scanResults.clear();
    });

    try {
      var url = Uri.parse('http://127.0.0.1:5000/scan_ports?domain=$domain');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          scanResults = data['scan_results'];
        });
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text("Smart Port Scanner"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Target IP / Domain",
                      labelStyle: TextStyle(color: Colors.orangeAccent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      prefixIcon: Icon(Icons.wifi_tethering, color: Colors.orangeAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: const Text("Scan"),
                )
              ],
            ),
          ),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Text(
                      isLoading ? "Scanning Ports..." : "Enter Target to Scan",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 مربعات في الصف
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      var item = scanResults[index];
                      bool isOpen = item['status'] == "Open";
                      return Container(
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green[900]!.withOpacity(0.4) : Colors.red[900]!.withOpacity(0.2),
                          border: Border.all(color: isOpen ? Colors.greenAccent : Colors.redAccent.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${item['port']}",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              item['service'],
                              style: TextStyle(color: Colors.grey[300], fontSize: 12),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['status'],
                              style: TextStyle(
                                color: isOpen ? Colors.greenAccent : Colors.redAccent, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
