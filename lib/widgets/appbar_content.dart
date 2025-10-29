import 'package:flutter/material.dart';
import 'package:growup_agro/widgets/wallet_balance.dart';

class AppbarContent extends StatelessWidget {
  const AppbarContent({
    super.key,
    required Future<Map<String, dynamic>> profileFuture,
    required int loyaltyPoints,
    required String walletBalance,
  }) : _profileFuture = profileFuture, _loyaltyPoints = loyaltyPoints, _walletBalance = walletBalance;

  final Future<Map<String, dynamic>> _profileFuture;
  final int _loyaltyPoints;
  final String _walletBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        // color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Username from API
                FutureBuilder<Map<String, dynamic>>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error fetching data"),
                      );
                    } else {
                      final profile = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                // Name
                                Flexible(
                                  child: Text(
                                    "${profile['name']}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.w400,
                                    ),
                                    overflow:
                                    TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(width: 6),

                                // Loyalty Points
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[700],
                                    borderRadius:
                                    BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        '$_loyaltyPoints',
                                        style:
                                        const TextStyle(
                                          fontSize: 8,
                                          color: Colors
                                              .white,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),

                // end of username api

                // wallet balance
                WalletBalance(walletBalance: _walletBalance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
