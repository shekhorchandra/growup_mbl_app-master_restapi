import 'package:http/http.dart' as http;

class ApiConstants {
  // Base URLs for different environments
  //static const String devBaseUrl = "https://growupagro.tech/api";
  static const String devBaseUrl = "https://growupagro.tech/api";
  // static const String prodBaseUrl = "https://admin-growup.onebitstore.site/api";
  static const String prodBaseUrl = "https://growupagro.tech/api";
  static const String devImgBaseUrl = "https://dev-growup.onebitstore.site";
  // static const String prodImgBaseUrl = "https://admin-growup.onebitstore.site";
  static const String prodImgBaseUrl = "https://growupagro.tech";

// Toggle environment
  static const bool isProd = true;

// Base URL getter
  static String get baseUrl => isProd ? prodBaseUrl : devBaseUrl;

// Image URL getter
  static String get imgBaseUrl => isProd ? prodImgBaseUrl : devImgBaseUrl;

  static String updateProfileInfo = "$baseUrl/investor/profile/investor-info/update";
  static String changePassword = "$baseUrl/change-password";


  //-----------------------------------------
  //sliders
  static String sliderImages() => "$baseUrl/investor/sliders";
  // Static website URLs (non-API pages)
  static String get aboutUsUrl =>
      isProd ? "$prodImgBaseUrl/about-us" : "https://dev-growup.onebitstore.site/about-us";

  static String get newsUrl =>
      isProd ? "$prodImgBaseUrl/news" : "https://dev-growup.onebitstore.site/news";

  static String get blogsUrl =>
      isProd ? "$prodImgBaseUrl/blogs" : "https://dev-growup.onebitstore.site/blogs";

  static String get crretificatesUrl =>
      isProd ? "$prodImgBaseUrl/crretificates" : "https://dev-growup.onebitstore.site/crretificates";


  //----------------------
  // All products`Product image URL
  static String getProductImage(String? path) {
    if (path == null || path.isEmpty) {
      return "assets/images/placeholder.png"; // local fallback
    }
    return "$imgBaseUrl$path";
  }

  // 🔹 All Properties (packages) endpoint
  static String get allProperties => "$baseUrl/properties";

// 🔹 Property or package image builder
  static String getPackageImage(String? path) {
    if (path == null || path.isEmpty) {
      return "assets/images/placeholder.png"; // local fallback
    }
    return "$imgBaseUrl$path";
  }

  // Endpoints
  //-----------------------------------------
// Investor profile page
  static String investorProfile(String investorCode) =>
      "$baseUrl/investor/profile?investor_code=$investorCode";
  static String updateInvestorInfo =
      "$baseUrl/investor/profile/investor-info/update";
  // Create nominee info
  static String createNomineeInfo() => "$baseUrl/investor/nominee/info/create";
  static String updateNomineeInfo =
      "$baseUrl/investor/profile/nominee-info/update";
  static String updateBankInfo =
      "$baseUrl/investor/profile/bank-info/update";
  static String updateMobileBankingInfo =
      "$baseUrl/investor/profile/mobile-banking-info/update";
  static String totalInvestmentHistory =
      "$baseUrl/investor/total_investment_history";

//Investment History
  static String investmentHistory(String investorCode) =>
      "$baseUrl/investment-history?investor_code=$investorCode";

//Investment details page
  //Project Investment Detail
  static String projectInvestmentDetail(String investorCode, String projectId) =>
      "$baseUrl/peoject/investment/detail?investor_code=$investorCode&project_id=$projectId";

  // Invoice PDF Download
  static String invoicePdf(String invoiceNo) =>
      "$prodImgBaseUrl/dashboard/invoice/pdf/$invoiceNo";

  // ROI List Endpoint
  static String roiList(String investorCode, String projectId) {
    return "$baseUrl/roi-list?investor_code=$investorCode&project_id=$projectId";
  }

  // Wallet History
  static String walletHistory(String investorCode) {
    return "$baseUrl/wallet-history?investor_code=$investorCode";
  }


  // Deposit-related endpoints
  static String depositRequest() => "$baseUrl/deposit-request";
  // Deposit History
  static String depositHistory(String investorCode) =>
      "$baseUrl/investor/deposit-history?investor_code=$investorCode";


  // Withdraw-related endpoints
  static String withdrawHistory(String investorCode) =>
      "$baseUrl/widraw-history?investor_code=$investorCode";
// withdraw History
  static String submitWithdraw() => "$baseUrl/investor/withdraw";

  //projects
//live or shariah or long or short or coming or closed
  static String allProjects() => "$baseUrl/all-projects";

  //completed projects
  static String completedProjects(String investorCode) =>
      "$baseUrl/completed-projects?investor_code=$investorCode";

  //project details
  static String investorProjectDetails(String investorCode, String projectId) =>
      '$baseUrl/investor/project-details?investor_code=$investorCode&project_id=$projectId';

  // Investor projects
  static String investorProjectList(String investorId) =>
      "$baseUrl/investor/project-list?id=$investorId";

  //All products
  static String products(String investorCode) => "$baseUrl/products?investor_code=$investorCode";

  //logout
  static String logout = "$baseUrl/investor/logout";

  //login
  static final login = '$baseUrl/investor/login';

  //forget password
  static final forgotPassword = '$baseUrl/forgot-password';

  //register
  static final String userRegistration = '$baseUrl/user-registration';

  //profile image
  static Future<String> fetchInvestorProjectDetails(String investorCode, String projectId) async {
    // Example (if you wanted it to actually call API here)
    final url = Uri.parse("$baseUrl/investor/project-details?investor_code=$investorCode&project_id=$projectId");
    final response = await http.get(url);
    return response.body;
  }

  //default profile image
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "assets/images/img.png"; // fallback asset
    }
    return "$imgBaseUrl/storage/$path";
  }

  // Capital returns
  static String capitalReturns(String investorCode) =>
      "$baseUrl/capital-returns?investor_code=$investorCode";

  static String capitalReturnInvoiceDownload(String invoiceNo) =>
      "https://growupagro.tech/dashboard/invoice/pdf/$invoiceNo";

  // Invoice endpoints
  // static String invoicePdf(String invoiceNo) => "$baseUrl/invoice/pdf/$invoiceNo";

  static String invoices(String investorCode) => "$baseUrl/invoices?investor_code=$investorCode";

  // Recharges
  static String recharges(String investorCode) => "$baseUrl/recharges?investor_code=$investorCode";

// Recharge invoice download
  static String rechargeInvoicePdf(String invoiceNo) => "$prodImgBaseUrl/dashboard/invoice/pdf/$invoiceNo";

// ROI list for investor
  static String roiListinvoice(String investorCode) => "$baseUrl/rois?investor_code=$investorCode";

// ROI invoice download
  static String roiInvoiceDownload(String invoiceNo) => "https://growupagro.tech/dashboard/invoice/pdf/$invoiceNo";

// Pop-up projects for investor
  static String investorPopUpProjects(String investorCode) =>
      "$baseUrl/investor/pop-up/my-projects?investor_code=$investorCode";

  // My orders for investor
  static String myOrders(String investorCode) => "$baseUrl/my-orders?investor_code=$investorCode";

  // Invest now endpoint
  static String investNow() => "$baseUrl/investor/invest-now";

  // Product details by slug
  static String productDetails(String slug) => "$baseUrl/product-details/$slug";

// Place order
  static String placeOrder() => "$baseUrl/place-order";

// Project certificates endpoint
  static String projectCertificates() => "$baseUrl/investor/project-certificates";

  // Tax certificate download endpoint
  static String taxCertificateDownload(String startFiscalYear, String investorCode) =>
      "$baseUrl/tax-certificate/download/$startFiscalYear?investor_code=$investorCode";

  // Today's income popup
  static String todaysIncome(String investorCode) =>
      "$baseUrl/investor/pop-up/todays-income?investor_code=$investorCode";

  // Total income popup
  static String totalIncome(String investorCode) =>
      "$baseUrl/investor/pop-up/total-income?investor_code=$investorCode";

  static String taxCertificates(String investorCode) =>
      "$baseUrl/tax-certificates?investor_code=$investorCode";
}
