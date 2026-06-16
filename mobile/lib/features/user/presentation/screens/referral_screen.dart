import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:share_plus/share_plus.dart';

import 'package:collegebus/shared/widgets/success_modal.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final referralCode = user.referralCode ?? "---";

    return Scaffold(
      appBar: AppBar(title: const Text("Refer & Earn"), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            VxBox(
                  child: VStack([
                    const Icon(
                      Icons.card_giftcard_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                    20.heightBox,
                    "Give a friend 1 week of Premium".text.white
                        .size(20)
                        .bold
                        .center
                        .make(),
                    10.heightBox,
                    "When they make their first purchase, you'll also get 1 week of Premium for free!"
                        .text
                        .white
                        .size(14)
                        .center
                        .make(),
                  ]).p24(),
                )
                .width(double.infinity)
                .color(Theme.of(context).primaryColor)
                .customRounded(
                  const BorderRadius.vertical(bottom: Radius.circular(40)),
                )
                .make(),

            40.heightBox,

            "Your Referral Code".text
                .size(16)
                .semiBold
                .color(Colors.grey)
                .make(),
            10.heightBox,

            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: referralCode));
                SuccessModal.show(
                  context: context,
                  title: 'Copied',
                  message: 'Code copied to clipboard!',
                  primaryActionText: 'OK',
                );
              },
              child:
                  VxBox(
                        child: referralCode.text
                            .size(32)
                            .bold
                            .letterSpacing(2)
                            .indigo600
                            .make()
                            .centered(),
                      ).white.rounded
                      .border(color: Colors.indigo.shade100, width: 2)
                      .p20
                      .make()
                      .pSymmetric(h: 40),
            ),

            20.heightBox,
            "Tap to copy".text.size(12).color(Colors.grey).make(),

            60.heightBox,

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: "Hey! Join me on CollegeBus, the best bus tracking app. Use my referral code $referralCode to get started! Download now: https://collegebus.app",
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: "Share with Friends".text.bold.make(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ).pSymmetric(h: 32),

            40.heightBox,

            // How it works section
            VxBox(
              child: VStack([
                "How it works?".text.size(18).bold.make(),
                20.heightBox,
                _buildStep(
                  Icons.person_add_rounded,
                  "Share your code with a friend",
                ),
                15.heightBox,
                _buildStep(
                  Icons.shopping_cart_rounded,
                  "They join and buy a Premium plan",
                ),
                15.heightBox,
                _buildStep(
                  Icons.workspace_premium_rounded,
                  "Both of you get 1 week extra Premium!",
                ),
              ]),
            ).p32.width(double.infinity).make(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String text) {
    return HStack([
      Icon(icon, color: Colors.indigo, size: 28),
      20.widthBox,
      text.text.size(15).make().expand(),
    ]);
  }
}
