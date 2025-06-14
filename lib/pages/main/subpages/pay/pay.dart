import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/pay/components/transactioncard.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/models.dart';
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
    loadBalance();
    loadTransactions();
  }

  Future<void> loadBalance() async {
    final BaseAPI api = context.read<BaseAPI>();
    final bal = await api.getRunshawPayBalance();
    if (bal != null && mounted) {
      setState(() {
        balance = bal;
        loadingBalance = false;
      });
    } else {
      setState(() {
        balance = "Unknown";
        loadingBalance = false;
      });
    }
  }

  Future<void> loadTransactions() async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final transactions = await api.getRunshawPayTransactions();

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
        balance = "Unknown";
        loadingBalance = false;
      });
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
    final bool? shownBefore = preferences.getBool("shownRunshawPayIntro");
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
                            "Thanks for trying out the beta RunshawPay integration! Please note:\n "),
                    TextSpan(text: "- This is "),
                    TextSpan(
                        text: "experimental",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "! It may not work as expected.\n"),
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
                preferences.setBool("shownRunshawPayIntro", true);
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
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Row(
                    children: [
                      Text(
                        "Your RunshawPay balance is",
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Skeletonizer(
                  enabled: loadingBalance,
                  textBoneBorderRadius: TextBoneBorderRadius(
                    BorderRadius.circular(12),
                  ),
                  child: Container(
                    transform: Matrix4.translationValues(
                        0.0, -10.0, 0.0), // shift above top text slightly
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 0),
                      child: Text(
                        balance,
                        style: GoogleFonts.rubik(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 12),
                  child: Container(
                    height: 11,
                    width: 100,
                    transform: Matrix4.translationValues(
                      0.0,
                      -12.0,
                      0.0,
                    ), // shift again
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final BaseAPI api = context.read<BaseAPI>();
            final String? topUpUrl = await api.getRunshawPayTopupUrl();
            if (topUpUrl != null) {
              if (await canLaunchUrlString(topUpUrl)) {
                await launchUrlString(topUpUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Couldn't open top up page."),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Top up URL is not available."),
                ),
              );
            }
          } on RunshawPayException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("An error occurred: ${e.cause}"),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Top Up"),
      ),
    );
  }
}
