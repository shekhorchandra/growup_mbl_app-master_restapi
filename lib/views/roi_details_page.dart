import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/roi_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_button.dart';

class RoiDetailsPage extends StatefulWidget {
  final String investorCode;
  final int projectId;

  const RoiDetailsPage({
    super.key,
    required this.investorCode,
    required this.projectId,
  });

  @override
  State<RoiDetailsPage> createState() => _RoiDetailsPageState();
}

class _RoiDetailsPageState extends State<RoiDetailsPage> {
  List<RoiModel> allData = [];
  List<RoiModel> filteredData = [];

  int rowsPerPage = 10;
  int currentPage = 0;
  bool isLoading = true;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRoiData();
    _searchController.addListener(() {
      _filterSearch(_searchController.text);
    });
  }

  String formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> fetchRoiData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing. Please log in again.")),
      );
      return;
    }

    final url = Uri.parse(
      ApiConstants.roiList(widget.investorCode, widget.projectId.toString()),
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List data = jsonData['data'];
          setState(() {
            allData = data.map((e) => RoiModel.fromJson(e)).toList();
            filteredData = allData;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredData = allData;
      } else {
        filteredData = allData.where((roi) {
          final formattedDate = formatDate(roi.countingDate).toLowerCase();
          final amount = roi.roiAmount.toString();
          return formattedDate.contains(query.toLowerCase()) ||
              amount.contains(query);
        }).toList();
      }
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredData.length / rowsPerPage).ceil();
    final currentItems =
    filteredData.skip(currentPage * rowsPerPage).take(rowsPerPage).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: !_isSearching
            ? const Text(
          'ROI Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search by date or amount...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredData.isEmpty
          ? const Center(
        child: Text(
          "No ROI records found for this project.",
          style:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: currentItems.length,
              itemBuilder: (context, index) {
                final roi = currentItems[index];
                final serial =
                    (currentPage * rowsPerPage) + index + 1;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        //Serial Number
                        Text(
                          "$serial",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 24,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ROI Date
                            Text(
                              "Date: ${formatDate(roi.countingDate)}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),

                            //ROI Amount
                            Text(
                              "Amount: ${NumberFormat("#,##0.00").format(roi.roiAmount)} BDT",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 📄 Pagination Footer with Shadow
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 30),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -2),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomButton(
                  text: "Previous",
                  height: 30,
                  backgroundColor: Colors.grey[400]!,
                  textColor: Colors.white,
                  onPressed: currentPage > 0
                      ? () => setState(() => currentPage--)
                      : null,
                ),
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                CustomButton(
                  text: "Next",
                  height: 30,
                  backgroundColor: Colors.grey[400]!,
                  textColor: Colors.white,
                  onPressed: currentPage < totalPages - 1
                      ? () => setState(() => currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
