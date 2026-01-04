import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../theme_config.dart';
import 'spider_screen.dart';
import 'port_scanner_screen.dart';
import 'tech_screen.dart';
import 'risk_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  Future<void> _generateReportDialog() async {
    TextEditingController reportController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("GENERATE REPORT", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter target domain to generate full PDF audit:", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: reportController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "e.g. google.com",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("DOWNLOAD PDF"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[900], foregroundColor: Colors.white),
            onPressed: () async {
              String domain = reportController.text.trim();
              if (domain.isNotEmpty) {
                final Uri url = Uri.parse('${AppConfig.baseUrl}/generate_report?domain=$domain');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  throw Exception('Could not launch $url');
                }
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
    );
  }


  void toggleTheme(bool enableMultiColor) {
    setState(() {
      AppTheme.isMultiColorMode = enableMultiColor;

      if (!enableMultiColor) {
        AppTheme.primaryColor = const Color(0xFF00FF41);
      }
    });
    Navigator.pop(context); 
  }


  Color getCardColor(int index, Color defaultMultiColor) {
    if (AppTheme.isMultiColorMode) {
      return defaultMultiColor; 
    } else {
      return AppTheme.primaryColor; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateReportDialog,
        backgroundColor: AppTheme.isMultiColorMode ? Colors.white : AppTheme.primaryColor,
        icon: Icon(Icons.picture_as_pdf, color: Colors.black),
        label: Text(
          "EXPORT REPORT",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("NEXUS INTELLIGENCE"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: AppTheme.isMultiColorMode ? Colors.white : AppTheme.primaryColor,
        elevation: 10,
        actions: [

          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  height: 200,
                  child: Column(
                    children: [
                      const Text(
                        "SELECT THEME STYLE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          _buildThemeOption(
                            icon: Icons.terminal,
                            label: "Matrix (Original)",
                            color: const Color(0xFF00FF41),
                            isActive: !AppTheme.isMultiColorMode,
                            onTap: () => toggleTheme(false),
                          ),
                          

                          _buildThemeOption(
                            icon: Icons.palette,
                            label: "Cyberpunk (Multi)",
                            color: Colors.pinkAccent, 
                            isActive: AppTheme.isMultiColorMode,
                            onTap: () => toggleTheme(true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(

        padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AVAILABLE MODULES",
              style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  // 1. Spider (Red in Multi Mode)
                  FeatureCard(
                    title: "Subdomain Spider",
                    icon: Icons.hub,
                    color: getCardColor(0, Colors.redAccent),
                    description: "AI-Powered Recon & Visualizer",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SpiderPage())),
                  ),

                  // 2. Tech Fingerprint (Blue in Multi Mode)
                  FeatureCard(
                    title: "Tech Fingerprint",
                    icon: Icons.fingerprint,
                    color: getCardColor(1, Colors.cyanAccent),
                    description: "Identify CMS & Frameworks",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TechStackPage())),
                  ),

                  // 3. Port Scanner (Orange in Multi Mode)
                  FeatureCard(
                    title: "Port Scanner",
                    icon: Icons.radar,
                    color: getCardColor(2, Colors.orangeAccent),
                    description: "Detect Open Ports & Services",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortScannerPage())),
                  ),

                  // 4. Risk Report (Purple in Multi Mode)
                  FeatureCard(
                    title: "AI Risk Report",
                    icon: Icons.assessment,
                    color: getCardColor(3, Colors.purpleAccent),
                    description: "Vulnerability Scoring & Analysis",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiskAssessmentPage())),
                  ),
                ],
              ),
            ),
            

            const SizedBox(height: 10),
            

            Center(
              child: Opacity(
                opacity: 0.7,
                child: Column(
                  children: [
                    Text(
                      "POWERED BY",
                      style: TextStyle(
                        color: AppTheme.isMultiColorMode ? Colors.white54 : AppTheme.primaryColor.withOpacity(0.8), 
                        fontSize: 8, 
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const SizedBox(height: 2), 
                    const Text(
                      "SILENT ROOT",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'monospace'
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildThemeOption({required IconData icon, required String label, required Color color, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.2) : Colors.transparent,
              border: Border.all(color: isActive ? color : Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: isActive ? color : Colors.grey, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
