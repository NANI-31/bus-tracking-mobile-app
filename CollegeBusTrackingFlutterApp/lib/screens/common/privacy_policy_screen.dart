import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 'Privacy Policy'.text.bold.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            'Privacy is our priority.'.text.xl.bold.make(),
            16.heightBox,
            'Information We Collect'.text.lg.bold.make(),
            8.heightBox,
            'We collect information to provide better services to all our users. This includes your location for live tracking, your profile details, and usage data to improve the app performance.'
                .text
                .make(),
            20.heightBox,

            'How We Use Information'.text.lg.bold.make(),
            8.heightBox,
            'We use the information we collect to provide, maintain, and improve our services, and to develop new ones. Live location is only shared with relevant authorities for safety and tracking purposes.'
                .text
                .make(),
            20.heightBox,

            'Data Security'.text.lg.bold.make(),
            8.heightBox,
            'We work hard to protect our users from unauthorized access to or unauthorized alteration, disclosure or destruction of information we hold.'
                .text
                .make(),
            20.heightBox,

            'Changes to Policy'.text.lg.bold.make(),
            8.heightBox,
            'Our Privacy Policy may change from time to time. We will post any privacy policy changes on this page.'
                .text
                .make(),
            40.heightBox,

            'Last Updated: December 2025'.text.gray400.make().centered(),
          ],
        ),
      ),
    );
  }
}
