import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:http/http.dart' as http;


class SpiderPage extends StatefulWidget {
  const SpiderPage({super.key});

  @override
  _SpiderPageState createState() => _SpiderPageState();
}

class _SpiderPageState extends State<SpiderPage> {
  final TextEditingController _controller = TextEditingController();
  
  Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  Key graphKey = UniqueKey(); 
  
  bool isLoading = false;
  bool hasData = false;

  Map<int, String> nodeLabels = {}; 
 
  Map<int, int> nodeScores = {};

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  Future<void> scanDomain() async {
    String domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      isLoading = true;
      hasData = false;
      nodeLabels.clear();
      nodeScores.clear(); 
    });

    Graph newGraph = Graph()..isTree = true;

    try {
      var url = Uri.parse('http://127.0.0.1:5000/scan?domain=$domain');
      print("Connecting to: $url");

      var response = await http.get(url);
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        if (data['nodes'] != null && (data['nodes'] as List).isNotEmpty) {
            Map<int, Node> nodeMap = {};
            
            for (var n in data['nodes']) {
              int id = n['id'];
              String label = n['label']; 
            
int score = (n['score'] ?? 0).toInt();
              
              var node = Node.Id(id);
              nodeMap[id] = node;
              newGraph.addNode(node);
              
              nodeLabels[id] = label;
              nodeScores[id] = score; 
            }

            for (var e in data['edges']) {
              var source = nodeMap[e['from']];
              var destination = nodeMap[e['to']];
              if (source != null && destination != null) {
                newGraph.addEdge(source, destination);
              }
            }

            setState(() {
              graph = newGraph;
              graphKey = UniqueKey();
              hasData = true;
            });
        }
      }
    } catch (e) {
      print("Connection Error: $e");
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
        title: const Text("AI Subdomain Spider"),
        backgroundColor: Colors.black, 
        foregroundColor: Colors.white,
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
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      prefixIcon: Icon(Icons.radar, color: Colors.greenAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : scanDomain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  icon: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.play_arrow),
                  label: const Text("Scan"),
                )
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                color: Colors.black54,
              ),
              child: !hasData 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hub, size: 80, color: Colors.grey[800]),
                      const SizedBox(height: 10),
                      Text(
                        isLoading ? "AI Analysis in progress..." : "Ready to Map Infrastructure", 
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(500),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    key: graphKey,
                    graph: graph,
                    algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                    paint: Paint()..color = Colors.grey.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      var id = node.key!.value as int;
                      return _buildNodeWidget(id);
                    },
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(int id) {
    bool isRoot = (id == 1);
    String label = nodeLabels[id] ?? "Unknown";
    int score = nodeScores[id] ?? 0; 

   
    Color nodeColor = Colors.blue; 
    Color borderColor = Colors.blueAccent;
    IconData icon = Icons.storage;

    if (isRoot) {
      nodeColor = Colors.red[900]!;
      borderColor = Colors.red;
      icon = Icons.security;
    } else if (score >= 50) {
    
      nodeColor = Colors.orange[900]!;
      borderColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else if (score >= 20) {
   
      nodeColor = Colors.teal[800]!;
      borderColor = Colors.tealAccent;
      icon = Icons.vpn_key;
    } else {
    
      nodeColor = Colors.grey[900]!;
      borderColor = Colors.grey;
      icon = Icons.public;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: nodeColor, 
        border: Border.all(color: borderColor, width: isRoot || score > 50 ? 2 : 1),
        boxShadow: [
           BoxShadow(color: borderColor.withOpacity(0.4), spreadRadius: 2, blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 5),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
          if (!isRoot)
        
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4)
            ),
            child: Text(
              "AI Score: $score",
              style: TextStyle(color: borderColor, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          )
        ],
      ),
    );
  }
}
