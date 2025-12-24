import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 'Terms & Conditions'.text.bold.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            'Terms of Service'.text.xl.bold.make(),
            16.heightBox,
            'Agreement to Terms'.text.lg.bold.make(),
            8.heightBox,
            'By accessing the Upasthit application, you agree to be bound by these terms of service, all applicable laws and regulations, and agree that you are responsible for compliance with any applicable local laws.'
                .text
                .make(),
            20.heightBox,

            'User Responsibility'.text.lg.bold.make(),
            8.heightBox,
            'Users are responsible for maintaining the confidentiality of their account and password. You are responsible for all activities that occur under your account.'
                .text
                .make(),
            20.heightBox,

            'Service Availability'.text.lg.bold.make(),
            8.heightBox,
            'We strive to maintain high availability of the tracking service, but we do not guarantee uninterrupted service due to potential network or technical issues.'
                .text
                .make(),
            20.heightBox,

            'Governing Law'.text.lg.bold.make(),
            8.heightBox,
            'These terms and conditions are governed by and construed in accordance with the local laws and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location.'
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
