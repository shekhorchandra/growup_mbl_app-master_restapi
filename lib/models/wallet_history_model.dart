class WalletHistoryModel {
  final int id;
  final String? invoiceNo;
  final int? projectId;
  final String trxId;
  final String? context;
  final int walletId;
  final String type;
  final double amount;
  final String direction;
  final int? creditAccountId;
  final int? debitAccountId;
  final String? note;
  final int? rechargeId;
  final int? depositRequestId;
  final int? withdrawRequestId;
  final String createdAt;
  final String date;
  final String updatedAt;
  final String? status;
  final String? actionedBy;
  final String? invoice_download_url;
  final String? invoice_view_url;

  WalletHistoryModel({
    required this.id,
    this.invoiceNo,
    this.projectId,
    this.context,
    required this.trxId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.direction,
    this.creditAccountId,
    this.debitAccountId,
    this.note,
    this.rechargeId,
    this.depositRequestId,
    this.withdrawRequestId,
    required this.createdAt,
    required this.date,
    required this.updatedAt,
    this.status,
    this.actionedBy,
    required this.invoice_download_url,
    required this.invoice_view_url,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    return WalletHistoryModel(
      id: json['id'] ?? 0,
      invoiceNo: json['invoice_no']?.toString(),
      projectId: json['project_id'] != null ? int.tryParse(json['project_id'].toString()) : null,
      context: json['context']?.toString(),
      trxId: json['trx_id']?.toString() ?? '',
      walletId: int.tryParse(json['wallet_id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      direction: json['direction']?.toString() ?? '',
      creditAccountId: json['credit_account_id'] != null ? int.tryParse(json['credit_account_id'].toString()) : null,
      debitAccountId: json['debit_account_id'] != null ? int.tryParse(json['debit_account_id'].toString()) : null,
      note: json['note']?.toString(),
      rechargeId: json['recharge_id'] != null ? int.tryParse(json['recharge_id'].toString()) : null,
      depositRequestId: json['deposit_request_id'] != null ? int.tryParse(json['deposit_request_id'].toString()) : null,
      withdrawRequestId: json['withdraw_request_id'] != null ? int.tryParse(json['withdraw_request_id'].toString()) : null,
      createdAt: json['created_at']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      status: json['status']?.toString(),
      actionedBy: json['actioned_by']?.toString(),
      invoice_download_url: json['invoice_download_url'] ?? '', // ✅ add here
      invoice_view_url: json['invoice_view_url'] ?? '', // ✅ add here
    );
  }
}
