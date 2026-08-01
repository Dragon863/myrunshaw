import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/pay/components/transactioncard.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/models/exceptions.dart';
import 'package:runshaw/utils/models/transaction.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RunshawPayPage extends StatefulWidget {
  const RunshawPayPage({super.key});

  @override
  State<RunshawPayPage> createState() => _RunshawPayPageState();
}

class _RunshawPayPageState extends State<RunshawPayPage> {
  bool loadingBalance = true;
  bool loadingTransactions = true;
  String balance = "£0.00";
  List<Widget> cardWidgets = [];

  @override
  void initState() {
    super.initState();
    loadIntro();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadBalance();
        loadTransactions();
      }
    });
  }

  Future<void> loadBalance() async {
    if (!mounted) return;
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final String? bal = await api.getRunshawPayBalance();
      if (bal != null && mounted) {
        setState(() {
          balance = bal.replaceAll("£", ""); // remove £ symbol if present
          loadingBalance = false;
        });
      } else if (mounted) {
        setState(() {
          balance = "Error";
          loadingBalance = false;
        });
      }
    } catch (e) {
      await Posthog().capture(
        eventName: 'runshawpay_balance_error',
        properties: {
          'error': e.toString(),
        },
      );
      if (mounted) {
        setState(() {
          balance = "Error";
          loadingBalance = false;
        });
      }
    }
  }

  Future<void> loadTransactions() async {
    if (!mounted) return;
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final transactions = await api.getRunshawPayTransactions();
      await Posthog().capture(
        eventName: 'runshawpay_transactions_loaded',
        properties: {
          'transaction_count': transactions.length,
        },
      );
      if (transactions.isEmpty) {
        setState(() {
          cardWidgets = [const Center(child: Text("No transactions found."))];
          loadingTransactions = false;
        });
        return;
      }

      final DateFormat apiDateFormat = DateFormat("dd/MM/yyyy");

      transactions.sort((a, b) {
        try {
          final DateTime dateA = apiDateFormat.parse(a.date);
          final DateTime dateB = apiDateFormat.parse(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          // parse fail
          return 0;
        }
      });

      List<Widget> newWidgets = [];
      String? lastDate;

      for (final Transaction transaction in transactions) {
        if (lastDate != transaction.date) {
          newWidgets.add(
            Padding(
              padding: const EdgeInsets.only(
                  top: 6.0, bottom: 6.0, left: 16.0, right: 16.0),
              child: Text(
                _formatDateTitle(apiDateFormat.parse(transaction.date)),
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(
                        (0.9 * 255).round(), // 90% opacity
                      ),
                ),
              ),
            ),
          );
          lastDate = transaction.date;
        }

        newWidgets.add(
          TransactionCard(
            topText: transaction.details,
            bottomText: transaction.action,
            trailing: Text(
              transaction.amount,
              style: GoogleFonts.rubik(
                fontWeight: FontWeight.bold,
                color: transaction.action.contains("Spend")
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          cardWidgets = newWidgets;
          loadingTransactions = false;
        });
      }
    } on RunshawPayException catch (e) {
      if (mounted) {
        setState(() {
          cardWidgets = [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            Center(child: Text(e.cause, textAlign: TextAlign.center))
          ];
          loadingTransactions = false;
          balance = "Error";
          loadingBalance = false;
        });
      }
      await Posthog().capture(
        eventName: 'runshawpay_transactions_error',
        properties: {
          'error_cause': e.cause,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          cardWidgets = [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            const Center(
                child: Text("An unexpected error occurred",
                    textAlign: TextAlign.center))
          ];
          loadingTransactions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDateTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat("EEEE, d MMMM").format(date);
    }
  }

  void loadIntro() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool? shownBefore = preferences.getBool("shown_runshawpay_intro");
    if (shownBefore == null || !shownBefore) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            "Intro",
            style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
          ),
          insetPadding: const EdgeInsets.all(2.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    height: 4,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const <TextSpan>[
                    TextSpan(
                        text:
                            "Thanks for trying out the RunshawPay integration! Please note:\n "),
                    TextSpan(text: "- This is "),
                    TextSpan(
                        text: "unofficial",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "; it may not work as expected.\n"),
                    TextSpan(
                        text:
                            " - The \"Top Up\" button redirects to the official college top up page; this app is "),
                    TextSpan(
                        text: "NOT",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: " able to read your payment details, and will "),
                    TextSpan(
                        text: "NEVER",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " store your balance or transactions\n"),
                    TextSpan(
                      text:
                          " - All payments are processed by the college, not the developer of this app\n",
                    ),
                    TextSpan(
                        text:
                            "- If you have any issues, please report them in the settings page under \"Other\" > \"Report Bug\".\n"),
                    TextSpan(
                      text:
                          "\nThanks for using My Runshaw, and I hope this feature is useful!",
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                preferences.setBool("shown_runshawpay_intro", true);
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 1000,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Card(
                  color: context.read<ThemeProvider>().isDarkMode
                      ? Colors.red
                      : Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.read<ThemeProvider>().isDarkMode
                              ? Colors.red
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "RunshawPay Balance",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color:
                                        context.read<ThemeProvider>().isDarkMode
                                            ? Colors.white
                                                .withAlpha((0.6 * 255).round())
                                            : Colors.black
                                                .withAlpha((0.6 * 255).round()),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "BEN••••••59",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color:
                                        context.read<ThemeProvider>().isDarkMode
                                            ? Colors.white
                                                .withAlpha((0.6 * 255).round())
                                            : Colors.black
                                                .withAlpha((0.6 * 255).round()),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeletonizer(
                                  enabled: loadingBalance,
                                  effect: ShimmerEffect(
                                    baseColor:
                                        context.read<ThemeProvider>().isDarkMode
                                            ? Colors.white.withAlpha(
                                                (0.1 * 255).round(),
                                              )
                                            : Colors.black.withAlpha(
                                                (0.2 * 255).round(),
                                              ),
                                    highlightColor: Colors.white,
                                  ),
                                  textBoneBorderRadius: TextBoneBorderRadius(
                                    BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 0.0),
                                        child: Text(
                                          "£",
                                          style: GoogleFonts.oxanium(
                                            color: context
                                                    .read<ThemeProvider>()
                                                    .isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 36,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        balance,
                                        style: GoogleFonts.oxanium(
                                          color: context
                                                  .read<ThemeProvider>()
                                                  .isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 57,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              icon: Icon(
                                Icons.add,
                                color: context.read<ThemeProvider>().isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              label: Text(
                                "Top Up",
                                style: TextStyle(
                                    color:
                                        context.read<ThemeProvider>().isDarkMode
                                            ? Colors.black
                                            : Colors.white),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    context.read<ThemeProvider>().isDarkMode
                                        ? Colors.white
                                        : Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                  horizontal: 16.0,
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  final BaseAPI api = context.read<BaseAPI>();
                                  final String topUpUrl =
                                      await api.getRunshawPayTopupUrl();
                                  if (await canLaunchUrlString(topUpUrl)) {
                                    await launchUrlString(
                                      topUpUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Couldn't open top up page."),
                                      ),
                                    );
                                    await Posthog().capture(
                                      eventName:
                                          'runshawpay_topup_launch_failed',
                                    );
                                  }
                                } on RunshawPayException catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("An error occurred: ${e.cause}"),
                                    ),
                                  );
                                  await Posthog().capture(
                                    eventName: 'runshawpay_topup_error',
                                    properties: {
                                      'error_cause': e.cause,
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        height: 80,
                        child: Image.asset(
                          context.read<ThemeProvider>().isDarkMode
                              ? "assets/img/pay_card_pattern_dark.png"
                              : "assets/img/pay_card_pattern_light.png",
                        ),
                      ),
                    ],
                  ),
                ),
                Skeletonizer(
                  enabled: loadingTransactions,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: loadingTransactions
                        ? ListView.builder(
                            itemBuilder: (_, index) {
                              return TransactionCard(
                                topText: "Top-Up of £$index.00",
                                bottomText: "Systems test",
                                trailing: const Icon(Icons.add,
                                    color: Colors.green, size: 30),
                              );
                            },
                            itemCount: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                          )
                        : ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: cardWidgets,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
