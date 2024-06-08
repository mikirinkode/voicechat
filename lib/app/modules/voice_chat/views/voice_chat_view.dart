import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:voicechat/app/core/theme/app_color.dart';
import 'package:voicechat/app/modules/voice_chat/widgets/chat_widget.dart';

import '../controllers/voice_chat_controller.dart';

class VoiceChatView extends GetView<VoiceChatController> {
  const VoiceChatView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
              "Your Confidence: ${(controller.confidence * 100.0).toStringAsFixed(1)}%"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
            animate: controller.isListening,
            glowColor: Theme.of(context).primaryColor,
            // endRadius: 75.0,
            duration: const Duration(milliseconds: 2000),
            // repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: FloatingActionButton(
              onPressed: () {
                controller.startListening();
              },
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: Icon(controller.isListening ? Icons.stop : Icons.mic),
            )),
        body: controller.messages.isEmpty && !controller.isListening
            ? Center(
              child: Text(controller.text,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
            )
            : SingleChildScrollView(
                reverse: true,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16, 150.0),
                  child: Column(
                    children: [
                      Column(
                        children: controller.messages.map((e) {
                          var isUser = e.role == "user";
                          return ChatWidget(
                              message: e.parts?.first.text ?? "",
                              isUser: isUser);
                        }).toList(),
                      ),
                      controller.isListening
                          ? ChatWidget(
                              isUser: true,
                              message: controller.text,
                            )
                          : Container(),
                      controller.isGeneratingResponse
                          ? Padding(
                              padding:
                                  EdgeInsets.only(top: 16, right: 64, left: 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: AppColor.PRIMARY_100),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: LoadingAnimationWidget.waveDots(
                                      color: AppColor.PRIMARY_500, size: 24),
                                ),
                              ),
                            )
                          : Container()
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
