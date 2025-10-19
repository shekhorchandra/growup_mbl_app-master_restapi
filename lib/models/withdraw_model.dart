class Withdraw {
  final int id;
  final String? invoiceNo;
  final String amount;
  final String status;
  final String sendMoneyMobileMedia;
  final String createdAt;
  final String? note;
  final String trxId;

  Withdraw({
    required this.id,
    required this.amount,
    required this.invoiceNo,
    required this.status,
    required this.sendMoneyMobileMedia,
    required this.createdAt,
    this.note,
    required this.trxId,
  });

  factory Withdraw.fromJson(Map<String, dynamic> json) {
    return Withdraw(
      id: json['id'] ?? 0,
      amount: json['amount']?.toString() ?? '',
      // invoiceNo: json['invoice_no']?.toString(),
      invoiceNo: (json['invoice_no'] != null && json['invoice_no'].toString().isNotEmpty)
          ? json['invoice_no'].toString()
          : 'N/A', // 👈 Handle null/empty invoice number
      status: json['status'] ?? '',
      sendMoneyMobileMedia: json['send_money_mobile_media'] ?? '',
      createdAt: json['created_at'] ?? '',
      note: json['note'],
      trxId: json['trx_id']?.toString() ?? '',
    );
  }

}
