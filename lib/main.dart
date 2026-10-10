import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const bg = Color(0xFF101828), vio = Color(0xFF7C5CFF), teal = Color(0xFF2DD4BF), rose = Color(0xFFFB7185), mut = Color(0xFF94A3B8);
late SharedPreferences prefs;
final fontScale = ValueNotifier<double>(1), dark = ValueNotifier<bool>(true);
final tts = FlutterTts();
const pin = '1234'; // demo PIN

Future<void> openUrl(String u) => launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
Future<void> say(String t) async {
  await tts.setLanguage('en-IN');
  await tts.speak(t);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  fontScale.value = prefs.getDouble('fs') ?? 1;
  dark.value = prefs.getBool('dark') ?? true;
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: Listenable.merge([fontScale, dark]),
        builder: (_, __) {
          final d = dark.value, b = d ? Brightness.dark : Brightness.light;
          final base = ThemeData(brightness: b, useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: vio, brightness: b), scaffoldBackgroundColor: d ? bg : const Color(0xFFF4F6FB));
          return MaterialApp(
            title: 'Calculator',
            debugShowCheckedModeBanner: false,
            theme: base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme)),
            builder: (c, ch) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(fontScale.value)),
              // Keep a phone-sized column in the middle on wide screens (Chrome, tablets).
              child: ColoredBox(
                color: d ? const Color(0xFF0B1220) : const Color(0xFFE5E9F2),
                child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: ClipRect(child: ch!))),
              ),
            ),
            home: const CalcGate(),
          );
        },
      );
}

// ---------- calculator disguise ----------
String evalExpr(String s) {
  try {
    final t = RegExp(r'(\d+\.?\d*|[+\-×÷])').allMatches(s).map((m) => m[0]!).toList();
    double v = double.parse(t[0]);
    for (var i = 1; i + 1 < t.length; i += 2) {
      final n = double.parse(t[i + 1]);
      switch (t[i]) {
        case '+': v += n; break;
        case '-': v -= n; break;
        case '×': v *= n; break;
        default: v /= n;
      }
    }
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(4);
  } catch (_) {
    return 'Error';
  }
}

class CalcGate extends StatefulWidget {
  const CalcGate({super.key});
  @override
  State<CalcGate> createState() => _CalcState();
}

class _CalcState extends State<CalcGate> {
  String ex = '';
  static const rows = [['C', '⌫', '÷', '×'], ['7', '8', '9', '-'], ['4', '5', '6', '+'], ['1', '2', '3', '='], ['0', '00', '.', '=']];
  void tap(String k) {
    setState(() {
      if (k == 'C') { ex = ''; }
      else if (k == '⌫') { ex = ex.isEmpty ? '' : ex.substring(0, ex.length - 1); }
      else if (k == '=') {
        if (ex == pin) { ex = ''; Navigator.push(context, MaterialPageRoute(builder: (_) => const Shell())); }
        else if (ex.isNotEmpty) { ex = evalExpr(ex); }
      } else { ex = (ex == 'Error' ? '' : ex) + k; }
    });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(children: [
            Expanded(child: Container(alignment: Alignment.bottomRight, padding: const EdgeInsets.all(24), child: Text(ex.isEmpty ? '0' : ex, style: const TextStyle(fontSize: 56, color: Colors.white), textAlign: TextAlign.right))),
            for (final r in rows)
              Row(children: [
                for (final k in r)
                  Expanded(child: Padding(padding: const EdgeInsets.all(1), child: SizedBox(height: 64, child: FilledButton(
                    style: FilledButton.styleFrom(shape: const RoundedRectangleBorder(), backgroundColor: '÷×-+='.contains(k) ? Colors.orange : const Color(0xFF333333), foregroundColor: Colors.white),
                    onPressed: () => tap(k), child: Text(k, style: const TextStyle(fontSize: 24)))))),
              ]),
          ]),
        ),
      );
}

// ---------- shell with 5 tabs ----------
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  void fs(double d) {
    fontScale.value = (fontScale.value + d).clamp(0.85, 1.6);
    prefs.setDouble('fs', fontScale.value);
  }

  @override
  Widget build(BuildContext c) {
    final pages = [HomePage(go: (n) => setState(() => i = n)), const OppPage(), const InfoPage(health, 'Private health guidance'), const InfoPage(learn, 'Learn'), const SafePage()];
    return Scaffold(
      appBar: AppBar(title: const Text('SafeSpace'), actions: [
        IconButton(tooltip: 'Smaller text', icon: const Icon(Icons.text_decrease), onPressed: () => fs(-.1)),
        IconButton(tooltip: 'Larger text', icon: const Icon(Icons.text_increase), onPressed: () => fs(.1)),
        IconButton(tooltip: 'Light or dark', icon: const Icon(Icons.brightness_6), onPressed: () { dark.value = !dark.value; prefs.setBool('dark', dark.value); }),
        IconButton(tooltip: 'Hide', icon: const Icon(Icons.visibility_off), onPressed: () => Navigator.popUntil(c, (r) => r.isFirst)),
      ]),
      body: SafeArea(child: pages[i]),
      bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.work_outline), label: 'Opportunities'),
        NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Health'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
        NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Safety'),
      ]),
    );
  }
}

Widget screen(String t, Widget b) => Scaffold(appBar: AppBar(title: Text(t)), body: SafeArea(child: b));
void push(BuildContext c, String t, Widget b) => Navigator.push(c, MaterialPageRoute(builder: (_) => screen(t, b)));

// ---------- data ----------
const health = [
  ['Learning about periods', 'Periods are normal. Use clean cloth or pads, change them every few hours, and wash your hands. See a health worker if pain is severe.'],
  ['Eating well', 'Add dal, greens, eggs or jaggery to meals. Iron-rich food helps you feel less tired.'],
  ['Feeling low or anxious', 'It is okay to ask for help. Tele-MANAS (14416) offers free counselling.'],
  ['Free hospital cover', 'Ayushman Bharat can cover hospital costs up to Rs 5 lakh per family per year for eligible families.'],
  ['Cheaper medicines', 'Jan Aushadhi stores sell quality generic medicines at lower prices.'],
  ['When to see a doctor', 'See a doctor for heavy bleeding, fainting, fever, or pain that does not go away.'],
];
const learn = [
  ['Know your rights at work', 'You should get your pay on time and a written record of your work.'],
  ['Using UPI safely', 'Never share your PIN or OTP. A real bank never asks for them.'],
  ['Spotting a fake job offer', 'Real employers do not ask for money. Check the company name and address first.'],
  ['Using a shared phone safely', 'Log out of apps, clear browser history, and turn off notification previews.'],
  ['Saving a little every week', 'Even Rs 50 a week adds up to Rs 2,600 in a year.'],
];
const opp = {
  'Jobs': [['j1', 'Delivery partner', 'Andheri East - Rs 18,000-22,000 / month'], ['j2', 'Tailoring assistant', 'Dadar - Rs 12,000-16,000 / month'], ['j3', 'Shop sales assistant', 'Bandra - Rs 13,000-17,000 / month']],
  'Scholarships': [['s1', 'Girls scholarship', 'Class 10 - Deadline 20 Oct'], ['s2', 'Merit scholarship', 'Class 11-12 - Deadline 5 Nov'], ['s3', 'Minority girls scholarship', 'Apply on National Scholarship Portal']],
  'Courses': [['c1', 'Digital skills basics', 'Free, on your phone - 4 weeks'], ['c2', 'Tailoring and stitching', 'Free training - 3 months']],
  'Schemes': [['m1', 'Ayushman Bharat', 'Up to Rs 5 lakh health cover - Aadhaar, ration card'], ['m2', 'Jan Dhan account', 'Zero balance - Aadhaar'], ['m3', 'Free legal aid', 'Call 15100']],
};
const helplines = [['Emergency (all)', '112'], ['Police', '100'], ['Ambulance', '108'], ['Women helpline', '181'], ['Women in distress', '1091'], ['Child helpline', '1098'], ['Cyber fraud', '1930'], ['Free legal aid', '15100'], ['Mental health (Tele-MANAS)', '14416']];
const rights = [
  ['Zero FIR', 'You can file a complaint at any police station, even if it happened elsewhere. Ask for a free copy.'],
  ['Free legal aid', 'Women can get a free lawyer through the District Legal Services Authority. Call 15100.'],
  ['Harassment at work (POSH Act)', 'Workplaces with 10+ employees must have an Internal Committee. Complain in writing, usually within 3 months.'],
  ['Domestic violence law (2005)', 'You can ask a magistrate for protection, a safe place to stay and financial support.'],
  ['Maternity leave', 'Eligible women employees get paid maternity leave (26 weeks for the first two children).'],
  ['Online harassment', 'Report at cybercrime.gov.in or call 1930. Keep screenshots.'],
];
const docs = ['Aadhaar card', 'Birth certificate', 'School marksheet', 'Bank passbook', 'Ration card', 'Income certificate', 'Passport-size photos'];
// [name, description, Android package id (empty = unknown, falls back to store search)]
const suggested = [
  ['DigiLocker', 'Keep documents digitally', 'com.digilocker.android'],
  ['UMANG', 'Government services in one app', 'in.gov.umang.negd.g2c'],
  ['DIKSHA', 'Free school learning', 'in.gov.diksha.app'],
  ['Khan Academy', 'Free lessons', 'org.khanacademy.android'],
  ['BHIM', 'Safe UPI payments', 'in.org.npci.upiapp'],
  ['Tele MANAS', 'Free mental health support', ''],
  ['eSanjeevani', 'Free online doctor consult', ''],
  ['112 India', 'Emergency SOS app', ''],
];
const portals = [['DigiLocker', 'https://digilocker.gov.in'], ['UMANG', 'https://web.umang.gov.in'], ['National Scholarship Portal', 'https://scholarships.gov.in'], ['Jan Aushadhi', 'https://janaushadhi.gov.in']];

// Opens a website inside SafeSpace (phone). On web/laptop it opens a new tab.
class WebPage extends StatefulWidget {
  final String url;
  const WebPage(this.url, {super.key});
  @override
  State<WebPage> createState() => _WebState();
}

class _WebState extends State<WebPage> {
  late final WebViewController ctl = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));
  @override
  Widget build(BuildContext c) => WebViewWidget(controller: ctl);
}

// ---------- pages ----------
class HomePage extends StatelessWidget {
  final void Function(int) go;
  const HomePage({super.key, required this.go});
  @override
  Widget build(BuildContext c) {
    final tools = <List<Object>>[
      ['Helplines', () => push(c, 'Helplines', const HelplinePage())],
      ['Know your rights', () => push(c, 'Know your rights', const InfoPage(rights, 'Know your rights'))],
      ['My documents', () => push(c, 'My documents', const DocsPage())],
      ['Scam check', () => push(c, 'Scam check', const ScamPage())],
      ['Ask SafeSpace', () => push(c, 'Assistant', const ChatPage())],
      ['Get apps', () => push(c, 'Get apps', const AppsPage())],
    ];
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Good evening', style: Theme.of(c).textTheme.headlineSmall),
      const Text('Your space is private', style: TextStyle(color: mut)),
      const SizedBox(height: 16),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.7, children: [
        for (final t in tools) FilledButton.tonal(onPressed: t[1] as VoidCallback, child: Text(t[0] as String, textAlign: TextAlign.center)),
      ]),
      const SizedBox(height: 16),
      Card(child: ListTile(title: const Text('Girls scholarship'), subtitle: const Text('Deadline: 20 Oct'), trailing: FilledButton(onPressed: () => go(1), child: const Text('Continue')))),
      const SizedBox(height: 8),
      SizedBox(height: 50, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: rose, foregroundColor: Colors.white), onPressed: () => go(4), child: const Text('Emergency help', style: TextStyle(fontSize: 18)))),
    ]);
  }
}

class InfoPage extends StatelessWidget {
  final List<List<String>> items;
  final String title;
  const InfoPage(this.items, this.title, {super.key});
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        Text(title, style: Theme.of(c).textTheme.headlineSmall),
        const SizedBox(height: 8),
        for (final it in items)
          Card(child: ListTile(title: Text(it[0], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(it[1]), trailing: IconButton(tooltip: 'Listen', icon: const Icon(Icons.volume_up), onPressed: () => say('${it[0]}. ${it[1]}')))),
        const Text('General information only.', style: TextStyle(color: mut)),
      ]);
}

class OppPage extends StatefulWidget {
  const OppPage({super.key});
  @override
  State<OppPage> createState() => _OppState();
}

class _OppState extends State<OppPage> {
  String sub = 'Jobs';
  List<String> saved = prefs.getStringList('saved') ?? [];
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        Wrap(spacing: 8, children: [for (final k in opp.keys) ChoiceChip(label: Text(k), selected: k == sub, onSelected: (_) => setState(() => sub = k))]),
        for (final o in opp[sub]!)
          Card(child: ListTile(
            title: Text(o[1], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(o[2]),
            trailing: IconButton(
              tooltip: 'Save',
              icon: Icon(saved.contains(o[0]) ? Icons.bookmark : Icons.bookmark_border, color: saved.contains(o[0]) ? teal : null),
              onPressed: () => setState(() {
                saved.contains(o[0]) ? saved.remove(o[0]) : saved.add(o[0]);
                prefs.setStringList('saved', saved);
              }),
            ),
          )),
        const Text('Sample listings for demo.', style: TextStyle(color: mut)),
      ]);
}

class SafePage extends StatefulWidget {
  const SafePage({super.key});
  @override
  State<SafePage> createState() => _SafeState();
}

class _SafeState extends State<SafePage> {
  final tp = TextEditingController(text: prefs.getString('tp') ?? '');
  static const ck = ['Save two trusted phone numbers', 'Keep your phone charged', 'Know the nearest safe place', 'Tell one person your plan'];
  List<String> done = prefs.getStringList('ck') ?? [];
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        Text('Emergency help', style: Theme.of(c).textTheme.headlineSmall),
        const SizedBox(height: 8),
        SizedBox(height: 56, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: rose, foregroundColor: Colors.white), onPressed: () => openUrl('tel:112'), child: const Text('Call 112', style: TextStyle(fontSize: 18)))),
        const SizedBox(height: 12),
        TextField(controller: tp, keyboardType: TextInputType.phone, onChanged: (v) => prefs.setString('tp', v), decoration: const InputDecoration(labelText: 'Trusted person phone', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: () => tp.text.isNotEmpty ? openUrl('tel:${tp.text}') : null, child: const Text('Call trusted person')),
        const Divider(height: 28),
        const Text('Safety checklist', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final k in ck)
          CheckboxListTile(value: done.contains(k), title: Text(k), onChanged: (v) => setState(() { v! ? done.add(k) : done.remove(k); prefs.setStringList('ck', done); })),
        const Divider(height: 28),
        OutlinedButton(onPressed: () => Navigator.popUntil(c, (r) => r.isFirst), child: const Text('Hide screen')),
        OutlinedButton(onPressed: () async { await prefs.clear(); setState(() { done = []; tp.clear(); }); }, child: const Text('Delete my data')),
      ]);
}

class HelplinePage extends StatelessWidget {
  const HelplinePage({super.key});
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        for (final h in helplines) Card(child: ListTile(title: Text(h[0]), trailing: FilledButton(onPressed: () => openUrl('tel:${h[1]}'), child: Text('Call ${h[1]}')))),
        const Text('Numbers can change. Check locally too.', style: TextStyle(color: mut)),
      ]);
}

class DocsPage extends StatefulWidget {
  const DocsPage({super.key});
  @override
  State<DocsPage> createState() => _DocsState();
}

class _DocsState extends State<DocsPage> {
  List<String> have = prefs.getStringList('docs') ?? [];
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        Text('${have.length} of ${docs.length} ready'),
        LinearProgressIndicator(value: have.length / docs.length, color: teal),
        for (final d in docs) CheckboxListTile(value: have.contains(d), title: Text(d), onChanged: (v) => setState(() { v! ? have.add(d) : have.remove(d); prefs.setStringList('docs', have); })),
      ]);
}

class ScamPage extends StatefulWidget {
  const ScamPage({super.key});
  @override
  State<ScamPage> createState() => _ScamState();
}

class _ScamState extends State<ScamPage> {
  final t = TextEditingController();
  String v = '';
  void check() {
    final s = t.text.toLowerCase();
    const w = ['otp', 'upi', 'kyc', 'blocked', 'lottery', 'prize', 'click', 'link', 'urgent', 'verify', 'pin', 'cvv', 'refund', 'http'];
    final h = w.where(s.contains).length;
    setState(() => v = (h >= 2 || s.contains('otp') || s.contains('cvv')) ? 'DANGER: This looks like a scam. Do not share OTP or PIN. Do not click links. Report on 1930.' : s.trim().isEmpty ? '' : 'No obvious scam words, but stay careful. Never share OTP or PIN.');
    if (v.isNotEmpty) say(v);
  }

  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Paste a message you are unsure about.'),
        const SizedBox(height: 8),
        TextField(controller: t, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
        const SizedBox(height: 8),
        FilledButton(onPressed: check, child: const Text('Check message')),
        if (v.isNotEmpty) Card(color: v.startsWith('DANGER') ? const Color(0xFF7F1D1D) : const Color(0xFF134E4A), child: Padding(padding: const EdgeInsets.all(14), child: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]);
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatState();
}

class _ChatState extends State<ChatPage> {
  final q = TextEditingController();
  final log = <List<String>>[['ai', 'Ask me about scholarships, jobs, documents, health, rights, money or safety. Only you can see this chat.']];
  static final rules = <RegExp, String>{
    RegExp('scholar'): 'Yes. Save the application in Opportunities and continue privately. Check My documents to see what you still need.',
    RegExp('document|aadhaar'): 'Open My documents on Home. It shows what you need.',
    RegExp('job|work|naukri'): 'Open Opportunities, then Jobs. Never pay money to get a job.',
    RegExp('period|health|doctor|pain'): 'Open the Health tab. For heavy bleeding, fainting or severe pain, see a doctor.',
    RegExp('sad|anxious|stress|lonely'): 'I am sorry you feel this way. Tele-MANAS (14416) offers free counselling.',
    RegExp('unsafe|scared|danger|harass|abuse|help'): 'Open the Safety tab or call 112 now. Women helpline: 181.',
    RegExp('legal|rights|police|fir'): 'Open Know your rights. You can file a Zero FIR at any police station. Free legal aid: 15100.',
    RegExp('otp|upi|scam|fraud'): 'Use Scam check. Never share OTP or PIN. Report fraud on 1930.',
    RegExp('app|install|download'): 'Open Get apps on Home to find and install helpful apps from your store.',
  };
  void ask() {
    final s = q.text.trim().toLowerCase();
    if (s.isEmpty) return;
    var r = 'I can help with scholarships, jobs, documents, health, rights and safety.';
    for (final e in rules.entries) { if (e.key.hasMatch(s)) { r = e.value; break; } }
    setState(() { log..add(['me', q.text])..add(['ai', r]); q.clear(); });
    say(r);
  }

  @override
  Widget build(BuildContext c) => Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          for (final m in log) Align(alignment: m[0] == 'me' ? Alignment.centerRight : Alignment.centerLeft, child: Card(color: m[0] == 'me' ? vio : null, child: Padding(padding: const EdgeInsets.all(12), child: Text(m[1])))),
        ])),
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: TextField(controller: q, onSubmitted: (_) => ask(), decoration: const InputDecoration(hintText: 'Type your question', border: OutlineInputBorder()))),
          IconButton.filled(onPressed: ask, icon: const Icon(Icons.send)),
        ])),
      ]);
}

// ---------- install any app from Play Store / App Store ----------
class AppsPage extends StatefulWidget {
  const AppsPage({super.key});
  @override
  State<AppsPage> createState() => _AppsState();
}

class _AppsState extends State<AppsPage> {
  final q = TextEditingController();
  bool get ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  String play(String s) => 'https://play.google.com/store/search?q=${Uri.encodeComponent(s)}&c=apps';
  String apple(String s) => 'itms-apps://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?media=software&term=${Uri.encodeComponent(s)}';
  void install(String s) => openUrl(ios ? apple(s) : play(s));
  final site = TextEditingController();
  void inApp(String title, String url) {
    if (!url.startsWith('http')) url = 'https://$url';
    kIsWeb ? openUrl(url) : push(context, title, WebPage(url));
  }

  // Open an installed app from inside SafeSpace; if it is not installed, open the store.
  Future<void> openApp(String name, String pkg) async {
    final m = ScaffoldMessenger.of(context);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && pkg.isNotEmpty) {
      final i = AndroidIntent(action: 'android.intent.action.MAIN', category: 'android.intent.category.LAUNCHER', package: pkg, flags: [0x10000000]);
      try {
        if (await i.canResolveActivity() ?? false) { await i.launch(); return; }
      } catch (_) {}
    }
    m.showSnackBar(SnackBar(content: Text('$name is not installed (or cannot be opened here). Opening the store.')));
    install(name);
  }
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Find and install any app', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Type an app name. Your phone\'s store opens and you tap Install.', style: TextStyle(color: mut)),
        const SizedBox(height: 10),
        TextField(controller: q, onSubmitted: (v) => v.trim().isNotEmpty ? install(v.trim()) : null, decoration: const InputDecoration(labelText: 'App name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => q.text.trim().isNotEmpty ? openUrl(play(q.text.trim())) : null, child: const Text('Google Play'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonal(onPressed: () => q.text.trim().isNotEmpty ? openUrl(apple(q.text.trim())) : null, child: const Text('App Store'))),
        ]),
        const Divider(height: 28),
        const Text('Helpful apps', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final a in suggested) Card(child: ListTile(title: Text(a[0]), subtitle: Text(a[1]), trailing: Row(mainAxisSize: MainAxisSize.min, children: [TextButton(onPressed: () => install(a[0]), child: const Text('Install')), FilledButton(onPressed: () => openApp(a[0], a[2]), child: const Text('Open'))]))),
        const Divider(height: 28),
        const Text('Use inside SafeSpace', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Websites open right here, so you do not have to leave the app.', style: TextStyle(color: mut)),
        for (final p in portals) Card(child: ListTile(title: Text(p[0]), trailing: FilledButton.tonal(onPressed: () => inApp(p[0], p[1]), child: const Text('Open here')))),
        TextField(controller: site, keyboardType: TextInputType.url, onSubmitted: (v) => v.trim().isNotEmpty ? inApp('Website', v.trim()) : null, decoration: const InputDecoration(labelText: 'Any website address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.language))),
        const SizedBox(height: 8),
        const Text('Apps cannot be installed silently. You always confirm in the store. Check the publisher before installing.', style: TextStyle(color: mut)),
      ]);
}
