import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:voicechat/app/model/groq_message.dart';

import 'package:http/http.dart' as http;
import '../../../../constants.dart';
import '../../../model/groq_response.dart';
import '../../../utils/text_utils.dart';

class GroqchatController extends GetxController {
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

  final messages = <GroqMessage>[].obs;
  final selectedVoice = "".obs;

  final pageTitle = "Llama3 x Groq".obs;

  /// Object
  late SpeechToText _speech;
  late FlutterTts _tts;
  late GoogleTranslator _translator;

  @override
  void onInit() {
    super.onInit();
    selectedVoice(Get.arguments["VOICE_MODEL"]);
    _speech = SpeechToText();
    _tts = FlutterTts();
    _translator = GoogleTranslator();

    if (selectedVoice.value == "Male") {
      _tts.setVoice({"name": "Google UK English Male", "locale": "en-GB"});
    } else {
      _tts.setVoice({"name": "Google UK English Female", "locale": "en-GB"});
    }
    _tts.setErrorHandler((message) {
      Get.log("onStatus: tts error: $message");
    });

    _initializedAgent(Get.arguments["AI_AGENT"]);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    _speech.stop();
    _tts.stop();
  }

  void _initializedAgent(String agent) {
    switch (agent) {
      case Agent.englishMentor:
        pageTitle.value = Agent.englishMentor;
        messages.addAll([
          GroqMessage("system", SystemPromptTemplate.englishMentor),
          GroqMessage("assistant",
              "Hi, I am here to help you improve your english speaking skills! are you ready? SAY LET'S GO!")
        ]);
        break;
      case Agent.techRecruiter:
        pageTitle.value = Agent.techRecruiter;
        messages.addAll([
          GroqMessage("system", SystemPromptTemplate.techRecruiter),
          GroqMessage("assistant",
              "Hello, welcome to the Mock Interview. Are you ready to start practicing Interview?")
        ]);
        break;
      case Agent.repeatAfterMeAgent:
        pageTitle.value = Agent.repeatAfterMeAgent;
        messages.addAll([
          GroqMessage("system", SystemPromptTemplate.repeatAfterMeAgent),
          GroqMessage("assistant",
              "Hello, I'm here to help you improve your intonation and pronunciation. Ready to start repeating after me?")
        ]);
        break;
      case Agent.pronunciationPracticeAgent:
        pageTitle.value = Agent.pronunciationPracticeAgent;
        messages.addAll([
          GroqMessage(
              "system", SystemPromptTemplate.pronunciationPracticeAgent),
          GroqMessage("assistant",
              "Hi there! Let's focus on improving your pronunciation, especially on tricky words. Are you ready to get started?")
        ]);
        break;
      case Agent.conversationalPracticeAgent:
        pageTitle.value = Agent.conversationalPracticeAgent;
        messages.addAll([
          GroqMessage(
              "system", SystemPromptTemplate.conversationalPracticeAgent),
          GroqMessage("assistant",
              "Hey, I'm here to help you practice your conversational skills! Ready to have some fun conversations?")
        ]);
        break;
      case Agent.casualChatAgent:
        pageTitle.value = Agent.casualChatAgent;
        messages.addAll([
          GroqMessage("system", SystemPromptTemplate.casualChatAgent),
          GroqMessage("assistant",
              "Hey there! I'm here for some casual chatting. Ready to have a relaxed conversation?")
        ]);
        break;

      default:
        pageTitle.value = Agent.aiAssistant;
        messages.addAll([
          GroqMessage("system", SystemPromptTemplate.aiAssistant),
          GroqMessage("assistant", "Hello there, how can i help you today?")
        ]);
    }
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
      messages.add(GroqMessage("user", text));
      _speech.stop();
      _getModelResponse();
    }
  }

  Future<void> _getModelResponse() async {
    _isGeneratingResponse.value = true;
    Get.log("onStatus: _getModelResponse($_text)");
    var uri = "https://api.groq.com/openai/v1/chat/completions";
    var headers = {
      'Content-Type': "application/json; charset=UTF-8",
      "Authorization": "Bearer ${Constants.GROQ_API_KEY}"
    };
    var body = jsonEncode(<String, dynamic>{
      "messages": messages.map((element) => element.toJson()).toList(),
      "model": "llama3-70b-8192"
    });

    Get.log("body: $body");
    try {
      final apiResponse = await http.post(
        Uri.parse(uri),
        headers: headers,
        body: body,
      );
      if (apiResponse.statusCode == 200) {
        Get.log("onSuccess::response data: ${apiResponse.body}");
        final groqResponse =
            GroqResponse.fromJson(jsonDecode(apiResponse.body));
        Get.log("groqResponse::${groqResponse.choices.first.message.content}");

        _text.value = "";
        _isGeneratingResponse.value = false;
        var result = groqResponse.choices.first.message.content;
        _response.value = result;

        // translate it first
        // _translator
        //     .translate(result, from: "en", to: "id")
        //     .then((value) {
        //   Get.log("translated message: ${value.text}");
        //   messages.add(GroqMessage("assistant", response, translation: value.text));
        // }).onError((error, stackTrace) {
        //   Get.log("onError::translate message");
        messages.add(GroqMessage("assistant", response));
        // });

        _speak(TextUtils.removeAsterisk(response));
      } else {
        _isGeneratingResponse.value = false;
        Get.log("onError: $apiResponse");
        Get.log("onError: ${apiResponse.body}");
      }
    } catch (e) {
      _isGeneratingResponse.value = false;
      Get.log("error: $e");
    }
  }

  void _speak(String input) {
    Get.log("onStatus: speaking");
    _tts.speak(input).onError((error, stackTrace) {
      Get.log("onStatus: speaking error: $error");
    });
  }

  void _getTranslation(GroqMessage groqMessage) {
    _translator
        .translate(groqMessage.content, from: "en", to: "id")
        .then((value) {
      Get.log("translated message: ${value.text}");
      return value.text;
    });
  }

  void getTranslation(GroqMessage groqMessage, int key) {
    if (groqMessage.translation == null) {
      _translator
          .translate(groqMessage.content, from: "en", to: "id")
          .then((value) {
        Get.log("translated message: ${value.text}");
        GroqMessage updatedMessage = GroqMessage(
            groqMessage.role, groqMessage.content,
            translation: value.text);
        messages[key] = updatedMessage;
      });
    } else {
      Get.log("onGetTranslation info: there already translation");
    }
  }
}
