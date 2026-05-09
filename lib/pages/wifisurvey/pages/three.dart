import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/surveys/check_eligible.dart';
import 'package:runshaw/utils/surveys/wifi_speed.dart';

class WifiSurveyStageThree extends StatefulWidget {
  final ValueChanged<WifiSpeedSurveyResult>? onComplete;

  const WifiSurveyStageThree({
    super.key,
    this.onComplete,
  });

  @override
  State<WifiSurveyStageThree> createState() => _WifiSurveyStageThreeState();
}

class _WifiSurveyStageThreeState extends State<WifiSurveyStageThree> {
  double _progress = 0.0;
  bool _isRunning = false;

  void _setProgress(double progress) {
    if (!mounted) {
      return;
    }

    setState(() {
      _progress = progress.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: _progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        strokeWidth: 16,
                        value: value,
                        backgroundColor: Colors.grey[900]!.withAlpha(50),
                        color: Colors.green,
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  "${(_progress * 100).toInt()}%",
                  style: TextStyle(fontSize: 48, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Speed Test",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s start the test! Tap below to begin. This can take up to 30 seconds, after which the results are uploaded',
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _isRunning
                  ? null
                  : () async {
                      final bool eligible = await checkWifiSurveyEligibility();
                      if (eligible == false) {
                        // show popup alert
                        if (!mounted) {
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Not Eligible"),
                              content: const Text(
                                  "Please check that you are currently connected to the eduroam Wi-Fi network and try again."),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }
                      setState(() {
                        _isRunning = true;
                        _progress = 0.0;
                      });
                      final WifiSpeedSurvey survey = WifiSpeedSurvey();

                      final WifiSpeedSurveyResult? result =
                          await survey.runSpeedTest(
                        onProgress: _setProgress,
                      );

                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _isRunning = false;
                      });

                      if (result != null) {
                        final bool uploaded = await survey.uploadResult(
                          result,
                          submitter:
                              context.read<BaseAPI>().submitWifiSurveyResults,
                        );

                        if (!mounted) {
                          return;
                        }

                        if (uploaded) {
                          // ignore: use_build_context_synchronously
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Test Complete"),
                                content: const Text(
                                  "Thanks for participating! We'll run additional tests in the background periodically while you use the app until the survey period is over. Disable location permissions in settings at any time to opt out.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Test completed, but the upload failed. Please try again later.",
                              ),
                            ),
                          );
                        }

                        debugLog(result.toJson().toString());
                        widget.onComplete?.call(result);
                        debugLog("Wi-Fi speed test completed successfully.");
                        Navigator.pop(context);
                        debugLog("Exiting Wi-Fi survey flow.");
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Test failed. Please ensure you have a Wi-Fi connection and try again.",
                            ),
                          ),
                        );
                        _setProgress(0.0);
                      }
                    },
              child: Text(_isRunning ? "Running..." : "Start Test"),
            ),
          ),
        ],
      ),
    );
  }
}
