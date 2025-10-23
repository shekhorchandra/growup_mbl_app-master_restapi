import 'package:http/http.dart' as http;

class ApiConstants {
  // Base URLs for different environments
  static const String devBaseUrl = "https://dev-growup.onebitstore.site/api";
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
  // ✅ Static website URLs (non-API pages)
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
      "$baseUrl/capital-return-invoice-download/$invoiceNo";

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
  static String roiInvoiceDownload(String invoiceNo) => "$baseUrl/roi-invoice-download/$invoiceNo";

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

//   // Create nominee info
//   static String createNomineeInfo() => "$baseUrl/investor/nominee/info/create";
//
// // Update nominee info
//   static String updateNomineeInfo = "$baseUrl/investor/profile/nominee-info/update";

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

  // Wallet history
  // static String walletHistory(String investorCode) =>
  //     "$baseUrl/wallet-history?investor_code=$investorCode";

// Investor profile (wallet, banking, mobile info, etc.)
//   static String investorProfile(String investorCode) =>
//       "$baseUrl/investor/profile?investor_code=$investorCode";

// Tax Certificates
  static String taxCertificates(String investorCode) =>
      "$baseUrl/tax-certificates?investor_code=$investorCode";


}














//
// import 'package:http/http.dart' as http;
//
// class ApiConstants {
//   // ✅ Base URLs (Production)
//   static const String baseurl = "https://growupagro.tech/api";
//   static const String prodImgBaseUrl = "https://growupagro.tech/";
//
//   // ✅ Toggle if needed for development (currently production)
//   static const bool isProd = true;
//
//   // -------------------------------
//   // 🔹 Authentication
//   static const String login = "$baseurl/investor/login"; // done
//   static const String logout = "$baseurl/investor/logout";
//   static const String forgotPassword = "$baseurl/forgot-password";
//   static const String userRegistration = "$baseurl/user-registration";
//   static const String changePassword = "$baseurl/change-password";
//
//   // -------------------------------
//   // 🔹 Profile Management
//   static String investorProfile(String investorCode) =>
//       "$baseurl/investor/profile?investor_code=$investorCode";
//
//   static const String updateInvestorInfo =
//       "$baseurl/investor/profile/investor-info/update";
//
//   static const String updateBankInfo =
//       "$baseurl/investor/profile/bank-info/update";
//
//   static const String updateMobileBankingInfo =
//       "$baseurl/investor/profile/mobile-banking-info/update";
//
//   static const String updateNomineeInfo =
//       "$baseurl/investor/profile/nominee-info/update";
//
//   static String createNomineeInfo() => "$baseurl/investor/nominee/info/create";
//
//   static String updateProfileInfo = "$baseurl/investor/profile/investor-info/update";
//
//
//   // -------------------------------
//   // 🔹 Investment
//   static String investmentHistory(String investorCode) =>
//       "$baseurl/investment-history?investor_code=$investorCode";
//
//   static String projectInvestmentDetail(String investorCode, String projectId) =>
//       "$baseurl/peoject/investment/detail?investor_code=$investorCode&project_id=$projectId";
//
//   static String investorProjectDetails(String investorCode, String projectId) =>
//       "$baseurl/investor/project-details?investor_code=$investorCode&project_id=$projectId";
//
//   static String investorProjectList(String investorId) =>
//       "$baseurl/investor/project-list?id=$investorId";
//
//   static String completedProjects(String investorCode) =>
//       "$baseurl/completed-projects?investor_code=$investorCode";
//
//   static String allProjects() => "$baseurl/all-projects";
//
//   static String investNow() => "$baseurl/investor/invest-now";
//
//   // -------------------------------
//   // 🔹 Wallet
//   static String walletHistory(String investorCode) =>
//       "$baseurl/wallet-history?investor_code=$investorCode";
//
//   static String totalInvestmentHistory =
//       "$baseurl/investor/total_investment_history";
//
//   // -------------------------------
//   // 🔹 Deposit & Withdraw
//   static String depositRequest() => "$baseurl/deposit-request";
//
//   static String depositHistory(String investorCode) =>
//       "$baseurl/investor/deposit-history?investor_code=$investorCode";
//
//   static String withdrawHistory(String investorCode) =>
//       "$baseurl/widraw-history?investor_code=$investorCode";
//
//   static String submitWithdraw() => "$baseurl/investor/withdraw";
//
//   // 🔹 All Properties (packages) endpoint
//   static String get allProperties => "$baseurl/properties";
//
//   // -------------------------------
//   // 🔹 ROI & Capital Returns
//   static String roiList(String investorCode, String projectId) =>
//       "$baseurl/roi-list?investor_code=$investorCode&project_id=$projectId";
//
//   static String roiListinvoice(String investorCode) =>
//       "$baseurl/rois?investor_code=$investorCode";
//
//   static String roiInvoiceDownload(String invoiceNo) =>
//       "$baseurl/roi-invoice-download/$invoiceNo";
//
//   static String capitalReturns(String investorCode) =>
//       "$baseurl/capital-returns?investor_code=$investorCode";
//
//   static String capitalReturnInvoiceDownload(String invoiceNo) =>
//       "$baseurl/capital-return-invoice-download/$invoiceNo";
//
//   // -------------------------------
//   // 🔹 Invoices
//   static String invoices(String investorCode) =>
//       "$baseurl/invoices?investor_code=$investorCode";
//
//   static String invoicePdf(String invoiceNo) =>
//       "$baseurl/invoice/pdf/$invoiceNo";
//
//   // -------------------------------
//   // 🔹 Recharge
//   static String recharges(String investorCode) =>
//       "$baseurl/recharges?investor_code=$investorCode";
//
//   static String rechargeInvoicePdf(String invoiceNo) =>
//       "$baseurl/recharge-invoice/$invoiceNo";
//
//   // -------------------------------
//   // 🔹 Projects Popup & Income
//   static String investorPopUpProjects(String investorCode) =>
//       "$baseurl/investor/pop-up/my-projects?investor_code=$investorCode";
//
//   static String todaysIncome(String investorCode) =>
//       "$baseurl/investor/pop-up/todays-income?investor_code=$investorCode";
//
//   static String totalIncome(String investorCode) =>
//       "$baseurl/investor/pop-up/total-income?investor_code=$investorCode";
//
//   // -------------------------------
//   // 🔹 Products & Orders
//   static String products(String investorCode) =>
//       "$baseurl/products?investor_code=$investorCode";
//
//   static String productDetails(String slug) =>
//       "$baseurl/product-details/$slug";
//
//   static String placeOrder() => "$baseurl/place-order";
//
//   static String myOrders(String investorCode) =>
//       "$baseurl/my-orders?investor_code=$investorCode";
//
//   // -------------------------------
//   // 🔹 Certificates
//   static String projectCertificates() => "$baseurl/project-crretificates";
//
//   static String taxCertificateDownload(
//       String startFiscalYear, String investorCode) =>
//       "$baseurl/tax-certificate/download/$startFiscalYear?investor_code=$investorCode";
//
//   static String taxCertificates(String investorCode) =>
//       "$baseurl/tax-certificates?investor_code=$investorCode";
//
//   // -------------------------------
//   // 🔹 Static Pages
//   static String get aboutUsUrl => "$prodImgBaseUrl/about-us";
//   static String get newsUrl => "$prodImgBaseUrl/news";
//   static String get blogsUrl => "$prodImgBaseUrl/blogs";
//   static String get certificatesUrl => "$prodImgBaseUrl/crretificates";
//
//   // -------------------------------
//   // 🔹 Sliders
//   static String sliderImages() => "$baseurl/investor/sliders";
//
//   // -------------------------------
//   // 🔹 Helpers
//   static String getProductImage(String? path) {
//     if (path == null || path.isEmpty) {
//       return "assets/images/placeholder.png";
//     }
//     return "$prodImgBaseUrl$path";
//   }
//
//   static String getPackageImage(String? path) {
//     if (path == null || path.isEmpty) {
//       return "assets/images/placeholder.png";
//     }
//     return "$prodImgBaseUrl$path";
//   }
//
//   // -------------------------------
//   // 🔹 Example API call
//   static Future<String> fetchInvestorProjectDetails(
//       String investorCode, String projectId) async {
//     final url = Uri.parse(
//         "$baseurl/investor/project-details?investor_code=$investorCode&project_id=$projectId");
//     final response = await http.get(url);
//     return response.body;
//   }
// }



