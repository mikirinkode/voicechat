import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../utils/text_utils.dart';

class VoiceChatController extends GetxController {
  final _isListening = false.obs;
  bool get isListening => _isListening.value;

  final _isGeneratingResponse = false.obs;
  bool get isGeneratingResponse => _isGeneratingResponse.value;

  final _text = "Press the button and start speaking".obs;
  String get text => _text.value;

  final _response = "".obs;
  String get response => _response.value;

  final _confidence = 0.0.obs;
  double get confidence => _confidence.value;

  final messages = <Content>[].obs;
  final selectedVoice = "".obs;

  /// Object
  late SpeechToText _speech;
  late Gemini _gemini;
  late FlutterTts _tts;

  @override
  void onInit() {
    super.onInit();
    selectedVoice(Get.arguments["VOICE_MODEL"]);
    _speech = SpeechToText();
    _gemini = Gemini.instance;
    _tts = FlutterTts();

    if (selectedVoice.value == "Male") {
      _tts.setVoice({"name": "Google UK English Male", "locale": "en-GB"});
    } else {
      _tts.setVoice({"name": "Google UK English Female", "locale": "en-GB"});
    }
    _tts.setErrorHandler((message) {
      Get.log("onStatus: tts error: $message");
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    _tts.stop();
    _speech.stop();
    _gemini.cancelRequest();
  }

  startListening() async {
    _tts.stop();
    if (!isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => Get.log("onStatus: $val"),
        onError: (val) => Get.log("onError: $val"),
      );
      if (available) {
        _text.value = "";
        _isListening.value = true;
        _speech.listen(
            onResult: (val) => {
                  _text.value = val.recognizedWords,
                  if (val.hasConfidenceRating && val.confidence > 0)
                    {_confidence.value = val.confidence}
                });
      }
    } else {
      _isListening.value = false;
      messages.add(Content(parts: [Parts(text: text)], role: "user"));
      _speech.stop();
      _getGeminiResponse();
    }
  }

  void _getGeminiResponse() async {
    Get.log("onStatus: _getGeminirResponse($_text)");
    try {
      _response.value = "";
      _isGeneratingResponse.value = true;
      _gemini.chat(messages.value).then((value) {
        if (value.isBlank != true) {
          Get.log("onStatus: onGemini Done");
          _text.value = "";
          _isGeneratingResponse.value = false;
          var result =
              value?.output ?? "Sorry we are having a problem right now.";
          _response.value = result;
          messages.add(Content(parts: [Parts(text: response)], role: "model"));
          _speak(TextUtils.removeAsterisk(response));
        }
      }).onError((error, stackTrace) {
        Get.log("onStatus: Error: $error");
      });
    } catch (e) {
      _isGeneratingResponse.value = false;
      Get.log("onStatus: gemini error: $e");
    }
  }

  void _speak(String input) {
    Get.log("onStatus: speaking");
    _tts.speak(input).onError((error, stackTrace) {
      Get.log("onStatus: speaking error: $error");
    });
  }
}
