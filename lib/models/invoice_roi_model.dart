class RoiInvoice {
  final String projectName;
  final String projectCategory;
  final String projectCode;
  final String invoiceNo;
  final String totalRoi;
  final String amountInvested;
  final String currency;

  RoiInvoice({
    required this.projectName,
    required this.projectCategory,
    required this.projectCode,
    required this.invoiceNo,
    required this.totalRoi,
    required this.amountInvested,
    required this.currency,
  });

  factory RoiInvoice.fromJson(Map<String, dynamic> json) {
    return RoiInvoice(
      projectName: json['project_name']?.toString() ?? '',
      projectCategory: json['project_category']?.toString() ?? '',
      projectCode: json['project_code']?.toString() ?? '',
      invoiceNo: json['invoice_no']?.toString() ?? '',
      totalRoi: json['total_roi']?.toString() ?? '0',
      amountInvested: json['amount_invested']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? '',
    );
  }

}
