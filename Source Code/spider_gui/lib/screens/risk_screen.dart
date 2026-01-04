import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiskAssessmentPage extends StatefulWidget {
  const RiskAssessmentPage({super.key});

  @override
  _RiskAssessmentPageState createState() => _RiskAssessmentPageState();
}

class _RiskAssessmentPageState extends State<RiskAssessmentPage> {
  final TextEditingController _controller = TextEditingController();
  int riskScore = 0;
  String riskLevel = "Unknown";
  List<dynamic> issues = [];
  bool isLoading = false;
  bool hasScanned = false;

  Future<void> assessRisk() async {
    String domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      isLoading = true;
      hasScanned = false;
      issues.clear();
      riskScore = 0;
    });

    try {
      var url = Uri.parse('http://127.0.0.1:5000/assess_risk?domain=$domain');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          riskScore = data['risk_score'];
          riskLevel = data['risk_level'];
          issues = data['issues'];
          hasScanned = true;
        });
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }


  Color getRiskColor() {
    if (riskScore > 75) return Colors.red;
    if (riskScore > 40) return Colors.orange;
    if (riskScore > 20) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text("AI Risk Assessor"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.redAccent,
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
                      labelText: "Target Domain",
                      labelStyle: TextStyle(color: Colors.redAccent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      prefixIcon: Icon(Icons.shield, color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : assessRisk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.analytics),
                  label: const Text("Assess"),
                )
              ],
            ),
          ),
          
          Expanded(
            child: !hasScanned
                ? Center(
                    child: Text(
                      isLoading ? "Calculating Risk Matrices..." : "Enter Target to Generate Report",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: riskScore / 100,
                                strokeWidth: 15,
                                backgroundColor: Colors.grey[800],
                                color: getRiskColor(),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "$riskScore%",
                                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: getRiskColor()),
                                ),
                                Text(
                                  riskLevel,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                )
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text("SECURITY ISSUES FOUND", style: TextStyle(color: Colors.grey, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        

                        ...issues.map((issue) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red[900]!.withOpacity(0.2),
                            border: Border(left: BorderSide(color: getRiskColor(), width: 4)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.white, size: 20),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(issue, style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )).toList(),
                        
                        if (issues.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: const Text("No Critical Issues Detected ✅", style: TextStyle(color: Colors.greenAccent, fontSize: 18)),
                          )
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
