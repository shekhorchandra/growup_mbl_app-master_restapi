class Recharge {
  final String date;
  final String amount;
  final String method;
  final String status;
  final String note;
  final String invoiceNo;
  final String? invoiceUrl;
  final String? invoiceDownloadUrl;

  Recharge({
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
    required this.note,
    required this.invoiceNo,
    this.invoiceUrl,
    this.invoiceDownloadUrl,
  });

  factory Recharge.fromJson(Map<String, dynamic> json) {
    return Recharge(
      date: json['date'] ?? '',
      amount: json['amount']?.toString() ?? '',
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      note: json['note'] ?? '',
      invoiceNo: (json['invoice_no'] != null && json['invoice_no'].toString().isNotEmpty)
          ? json['invoice_no'].toString()
          : "N/A",
      invoiceUrl: json['invoice_url']?.toString(),
      invoiceDownloadUrl: json['invoice_download_url']?.toString(),
    );
  }

}
