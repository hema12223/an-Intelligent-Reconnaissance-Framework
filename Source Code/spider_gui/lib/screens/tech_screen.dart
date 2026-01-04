import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TechStackPage extends StatefulWidget {
  const TechStackPage({super.key});

  @override
  _TechStackPageState createState() => _TechStackPageState();
}

class _TechStackPageState extends State<TechStackPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> technologies = [];
  bool isLoading = false;
  bool hasSearched = false;

  Future<void> detectTech() async {
    String domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = false;
      technologies.clear();
    });

    try {
      // إرسال الطلب للبايثون
      var url = Uri.parse('http://127.0.0.1:5000/detect_tech?domain=$domain');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          technologies = data['technologies'];
          hasSearched = true;
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
        title: const Text("AI Tech Fingerprinter"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blueAccent,
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
                      labelText: "Target Domain (e.g. google.com)",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      prefixIcon: Icon(Icons.code, color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : detectTech,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.fingerprint),
                  label: const Text("Identify"),
                )
              ],
            ),
          ),
          
          Expanded(
            child: !hasSearched && !isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.memory, size: 80, color: Colors.grey[800]),
                        const SizedBox(height: 10),
                        Text("Ready to analyze technology stack", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: technologies.map((tech) => _buildTechChip(tech)).toList(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blueAccent),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
