import 'package:attendo/config/api_config.dart';
import 'package:flutter/material.dart';

class AddConnection extends StatefulWidget {
  const AddConnection({super.key});

  @override
  State<AddConnection> createState() => _AddConnectionState();
}

class _AddConnectionState extends State<AddConnection> {
  final TextEditingController ipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Enter IP Address',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                String ip = ipController.text.trim();

                if (ip.isNotEmpty) {
                  ApiConfig.setApiBaseUrl(ip);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Connection saved successfully'),
                    ),
                  );
                }
              },
              child: const Text("Save Connection"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }
}