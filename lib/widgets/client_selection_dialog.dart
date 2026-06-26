import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/api_service.dart';

class ClientSelectionDialog extends StatefulWidget {
  final Function(Client) onClientSelected;

  const ClientSelectionDialog({
    super.key,
    required this.onClientSelected,
  });

  @override
  State<ClientSelectionDialog> createState() => _ClientSelectionDialogState();
}

class _ClientSelectionDialogState extends State<ClientSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  Client? _selectedClient;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clients = await ApiService.getCustomerList();
      setState(() {
        _allClients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _allClients;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredClients = _allClients.where((client) {
          final nameMatch = client.customerName.toLowerCase().contains(lowercaseQuery);
          final shortNameMatch = client.clientShortName?.toLowerCase().contains(lowercaseQuery) ?? false;
          final labelMatch = client.label.toLowerCase().contains(lowercaseQuery);
          return nameMatch || shortNameMatch || labelMatch;
        }).toList();
      }

      // If the selected client is no longer visible in the filtered list, we don't necessarily deselect it,
      // but if we want to, we can check. For now, we keep the selection.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26), // ~0.1 opacity
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_pin_circle, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Select Client',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        'Fetching client list...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchClients,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Search Field
              TextField(
                controller: _searchController,
                onChanged: _filterClients,
                decoration: InputDecoration(
                  hintText: 'Search client site...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterClients('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable Client List
              Expanded(
                child: _filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, color: Colors.grey[300], size: 48),
                            const SizedBox(height: 8),
                            const Text(
                              'No clients found',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredClients.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          final isSelected = _selectedClient?.id == client.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Material(
                              color: isSelected
                                  ? Colors.orange.withAlpha(20) // ~0.08 opacity
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.orange
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Colors.orange
                                      : Colors.grey[100],
                                  child: Text(
                                    client.clientShortName != null &&
                                            client.clientShortName!.isNotEmpty
                                        ? client.clientShortName!.substring(0, 1).toUpperCase()
                                        : client.customerName.isNotEmpty
                                            ? client.customerName.substring(0, 1).toUpperCase()
                                            : 'C',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  client.customerName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: client.clientShortName != null &&
                                        client.clientShortName!.isNotEmpty
                                    ? Text(
                                        client.clientShortName!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.orange.shade700
                                              : Colors.grey[600],
                                        ),
                                      )
                                    : null,
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: Colors.orange)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedClient = client;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedClient == null
                        ? null
                        : () {
                            Navigator.pop(context); // Close dialog
                            widget.onClientSelected(_selectedClient!);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
