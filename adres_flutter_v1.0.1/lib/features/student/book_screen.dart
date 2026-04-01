import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/services/reading_state_local_service.dart';
import '../../core/services/progress_local_service.dart';
import '../../core/services/student_local_service.dart';
import '../../core/services/ai_service.dart';
import 'dart:async';

enum ViewMode { book, summary1, summary2, summary3, ai }

class BookScreen extends StatefulWidget {
  final String subjectName;
  final String termName;
  final String bookId;
  final int startPage;

  const BookScreen({
    super.key,
    required this.subjectName,
    required this.termName,
    required this.bookId,
    this.startPage = 1,
  });

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  ViewMode _currentMode = ViewMode.book;

  late WebViewController _bookController;
  late WebViewController _summaryController;

  int _currentPage = 1;
  int _summaryPage = 1;
  int _currentSummaryType = 1;

  bool _hasNext = false;
  bool _hasPrev = false;

  final int totalPages = 192;

  // ===== تتبع التقدم الحقيقي =====
  DateTime? _pageArrivalTime;   // وقت فتح الصفحة الحالية
  Timer? _progressTimer;        // مؤقت دوري كل 5 ثواني
  int _sessionClicks = 0;       // نقرات الجلسة

  // بيانات الطالب (محفوظ للمزامنة المستقبلية)
  // ignore: unused_field
  String _studentAcademicId = '';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.startPage;

    final student = StudentLocalService.getStudent();
    _studentAcademicId = student['academicId'] ?? '';

    _bookController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterAI',
        onMessageReceived: (message) {
          _handleAITextSelection(message.message);
        },
      )
      ..addJavaScriptChannel(
        'FlutterInteraction',
        onMessageReceived: (_) {
          // عدّ التفاعلات (نقرات، سحب، لمس)
          _sessionClicks++;
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          _injectTextSelectionJS();
          _injectInteractionTrackingJS();
          // حفظ محتوى الصفحة للـ RAG
          try {
            final res = await http.get(Uri.parse(_pageUrl(_currentPage)))
                .timeout(const Duration(seconds: 5));
            if (res.statusCode == 200) AIService.currentPageContent = res.body;
          } catch (_) {}
        },
      ))
      ..loadRequest(Uri.parse(_pageUrl(_currentPage)));

    _summaryController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    _startPageTimer();
    _recordPageOpened(_currentPage);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _flushCurrentPageProgress();
    super.dispose();
  }

  // ===== إدارة التقدم الحقيقي =====

  /// بدء تتبع الصفحة الحالية
  void _startPageTimer() {
    _pageArrivalTime = DateTime.now();
    _progressTimer?.cancel();
    // حفظ كل 5 ثواني بشكل دوري
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _flushCurrentPageProgress();
    });
  }

  /// تفريغ التقدم المتراكم للصفحة الحالية
  void _flushCurrentPageProgress() {
    if (_pageArrivalTime == null) return;
    final int elapsed =
        DateTime.now().difference(_pageArrivalTime!).inSeconds;
    if (elapsed > 0) {
      ProgressLocalService.addReadingTime(
        bookId: widget.bookId,
        seconds: elapsed,
        totalPages: totalPages,
      );
      _pageArrivalTime = DateTime.now(); // إعادة الضبط
    }
    if (_sessionClicks > 0) {
      ProgressLocalService.addInteraction(
        bookId: widget.bookId,
        count: _sessionClicks,
      );
      _sessionClicks = 0;
    }
  }

  /// تسجيل أن الطالب فتح هذه الصفحة
  void _recordPageOpened(int page) {
    ProgressLocalService.recordPageOpened(
      bookId: widget.bookId,
      page: page,
      totalPages: totalPages,
    );
    ReadingStateLocalService.addOpenedPage(
      bookId: widget.bookId,
      page: page,
    );
    ReadingStateLocalService.updateReadingState(
      bookId: widget.bookId,
      lastPage: page,
      subjectName: widget.subjectName,
      termName: widget.termName,
    );
  }

  // ===== URLs =====

  String _pageUrl(int page) {
    return '${AppConfig.backendBaseUrl}/book-pages/$page/';
  }

  String _summaryUrl(int type, int page) {
    return '${AppConfig.backendBaseUrl}/api/summary-html/?book=1&page=$_currentPage&type=$type&summary_page=$page';
  }

  // ===== التنقل =====

  Future<void> _checkSummaryNavigation() async {
    final nextUrl = _summaryUrl(_currentSummaryType, _summaryPage + 1);
    final prevUrl = _summaryUrl(_currentSummaryType, _summaryPage - 1);
    try {
      final next = await http
          .get(Uri.parse(nextUrl))
          .timeout(const Duration(seconds: 5));
      final prev = await http
          .get(Uri.parse(prevUrl))
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _hasNext = next.statusCode == 200;
          _hasPrev = prev.statusCode == 200;
        });
      }
    } catch (_) {}
  }

  void _loadSummary() {
    final url = _summaryUrl(_currentSummaryType, _summaryPage);
    _summaryController.loadRequest(Uri.parse(url));
    _checkSummaryNavigation();
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      _flushCurrentPageProgress();
      setState(() => _currentPage++);
      _bookController.loadRequest(Uri.parse(_pageUrl(_currentPage)));
      _startPageTimer();
      _recordPageOpened(_currentPage);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _flushCurrentPageProgress();
      setState(() => _currentPage--);
      _bookController.loadRequest(Uri.parse(_pageUrl(_currentPage)));
      _startPageTimer();
      _recordPageOpened(_currentPage);
    }
  }

  void _goToPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اذهب إلى صفحة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اكتب رقم الصفحة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(context);
              if (page >= 1 && page <= totalPages) {
                _flushCurrentPageProgress();
                setState(() => _currentPage = page);
                _bookController.loadRequest(Uri.parse(_pageUrl(page)));
                _startPageTimer();
                _recordPageOpened(page);
              }
            },
            child: const Text('اذهب'),
          ),
        ],
      ),
    );
  }

  void _searchTextDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث في الصفحة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اكتب النص للبحث عنه',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bookController.runJavaScript("window.find('');");
            },
            child: const Text('مسح'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context);
              if (text.isNotEmpty) {
                _bookController.runJavaScript(
                  "window.find(${text.replaceAll("'", "\\'").replaceAll('"', '\\"').contains("'") ? '"$text"' : "'$text'"}, false, false, true);",
                );
              }
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  void _selectMode(ViewMode mode) {
    Navigator.pop(context);
    setState(() {
      _currentMode = mode;
      _summaryPage = 1;
    });
    if (mode == ViewMode.summary1) {
      _currentSummaryType = 1;
      _loadSummary();
    } else if (mode == ViewMode.summary2) {
      _currentSummaryType = 2;
      _loadSummary();
    } else if (mode == ViewMode.summary3) {
      _currentSummaryType = 3;
      _loadSummary();
    }
  }

  // ===== JavaScript Injection =====

  /// حقن JS لتتبع التفاعلات (نقرات + سحب)
  void _injectInteractionTrackingJS() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _bookController.runJavaScript('''
        (function() {
          if (window._interactionTracked) return;
          window._interactionTracked = true;
          
          var events = ['click', 'touchstart', 'scroll'];
          events.forEach(function(ev) {
            document.addEventListener(ev, function() {
              try { FlutterInteraction.postMessage('1'); } catch(e) {}
            }, { passive: true });
          });
        })();
      ''');
    });
  }

  /// حقن JS لتحديد النص وإظهار زر "بحث مخصص AI"
  void _injectTextSelectionJS() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _bookController.runJavaScript(r'''
        (function() {
          if (window._aiSelectionInjected) return;
          window._aiSelectionInjected = true;

          // إخفاء قائمة السياق الافتراضية
          document.addEventListener('contextmenu', function(e) { e.preventDefault(); }, true);
          document.documentElement.style.webkitUserSelect = 'text';
          document.documentElement.style.userSelect = 'text';

          // إخفاء toolbar الافتراضي عبر CSS
          var style = document.createElement('style');
          style.textContent = '::selection { background: rgba(98,0,238,0.25); }';
          document.head.appendChild(style);

          function showAIButton() {
            var sel = window.getSelection();
            var old = document.getElementById('ai-sel-btn');
            if (old) old.remove();

            if (!sel || sel.toString().trim().length < 3) return;

            var text = sel.toString().trim();
            var range = sel.getRangeAt(0);
            var rect = range.getBoundingClientRect();

            var btn = document.createElement('button');
            btn.id = 'ai-sel-btn';
            btn.innerText = '\uD83E\uDD16 \u0628\u062D\u062B \u0645\u062E\u0635\u0635 AI';
            btn.style.cssText = 'position:fixed;' +
              'top:' + Math.max(0, rect.top - 44) + 'px;' +
              'left:' + Math.max(0, rect.left) + 'px;' +
              'background:#6200EE;color:white;border:none;' +
              'padding:8px 16px;border-radius:20px;' +
              'font-size:14px;cursor:pointer;z-index:99999;' +
              'font-family:Cairo,sans-serif;' +
              'box-shadow:0 2px 8px rgba(0,0,0,0.3);' +
              'white-space:nowrap;';
            btn.onclick = function(e) {
              e.stopPropagation();
              FlutterAI.postMessage(text);
              btn.remove();
            };
            document.body.appendChild(btn);
          }

          document.addEventListener('mouseup', function(e) {
            if (e.target && e.target.id === 'ai-sel-btn') return;
            setTimeout(showAIButton, 50);
          });
          document.addEventListener('touchend', function(e) {
            if (e.target && e.target.id === 'ai-sel-btn') return;
            setTimeout(showAIButton, 200);
          });

          // إخفاء الزر عند النقر في مكان آخر
          document.addEventListener('mousedown', function(e) {
            if (!e.target || e.target.id !== 'ai-sel-btn') {
              var b = document.getElementById('ai-sel-btn');
              if (b) b.remove();
            }
          });
          document.addEventListener('touchstart', function(e) {
            if (!e.target || e.target.id !== 'ai-sel-btn') {
              var b = document.getElementById('ai-sel-btn');
              if (b) b.remove();
            }
          }, { passive: true });
        })();
      ''');
    });
  }

  void _handleAITextSelection(String text) {
    _showAIResult(text, isSelected: true);
  }

  /// AI للصفحة الكاملة
  Future<void> _aiFullPage() async {
    String pageHtml = '';
    try {
      final res = await http
          .get(Uri.parse(_pageUrl(_currentPage)))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) pageHtml = res.body;
    } catch (_) {}

    if (!mounted) return;
    _showAIResult(
      pageHtml.isNotEmpty ? pageHtml : 'محتوى الصفحة $_currentPage',
      isSelected: false,
    );
  }

  void _showAIResult(String text, {required bool isSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AIResultSheet(
        text: text,
        isSelected: isSelected,
      ),
    );
  }

  void _showHelpOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اختر نوع المساعدة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HelpOption('ملخص 1', () => _selectMode(ViewMode.summary1)),
                _HelpOption('ملخص 2', () => _selectMode(ViewMode.summary2)),
                _HelpOption('ملخص 3', () => _selectMode(ViewMode.summary3)),
                _HelpOption('AI', () {
                  Navigator.pop(context);
                  _aiFullPage();
                }, icon: Icons.psychology),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} • ${widget.termName}'),
        leading: BackButton(
          onPressed: () {
            _flushCurrentPageProgress();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          if (_currentMode != ViewMode.book)
            Container(
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _currentMode = ViewMode.book);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة إلى الكتاب'),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContent()),
          if (_currentMode == ViewMode.book || _currentMode == ViewMode.ai)
            _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentMode) {
      case ViewMode.book:
      case ViewMode.ai:
        return Stack(
          children: [
            WebViewWidget(controller: _bookController),
            if (_currentMode == ViewMode.ai)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'حدد أي نص للشرح بالذكاء الاصطناعي، أو اضغط 💡 لأدوات المساعدة',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      case ViewMode.summary1:
      case ViewMode.summary2:
      case ViewMode.summary3:
        return _buildSummary();
    }
  }

  Widget _buildNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // زر الصفحة السابقة
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                ),

                // رقم الصفحة (اضغط للذهاب لصفحة)
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _goToPageDialog,
                      child: Text(
                        '$_currentPage / $totalPages',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),

                // زر الذهاب لصفحة محددة
                IconButton(
                  icon: const Icon(Icons.find_in_page),
                  tooltip: 'اذهب إلى صفحة',
                  onPressed: _goToPageDialog,
                ),

                // زر البحث بنص
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'بحث في الصفحة',
                  onPressed: _searchTextDialog,
                ),

                // ===== زر المصباح (الأدوات + AI للصفحة) =====
                // هذا هو الزر الوحيد - يفتح قائمة: ملخص 1, 2, 3 + AI
                IconButton(
                  icon: const Icon(Icons.lightbulb_outline),
                  tooltip: 'أدوات المساعدة',
                  onPressed: _showHelpOptions,
                ),

                // زر الصفحة التالية
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _currentPage < totalPages ? _goToNextPage : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _currentPage / totalPages,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        Expanded(child: WebViewWidget(controller: _summaryController)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_hasPrev)
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() => _summaryPage--);
                    _loadSummary();
                  },
                )
              else
                const SizedBox(width: 48),
              Text('صفحة الملخص $_summaryPage'),
              if (_hasNext)
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() => _summaryPage++);
                    _loadSummary();
                  },
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }
}

// ======== AI Result Sheet ========
class _AIResultSheet extends StatefulWidget {
  final String text;
  final bool isSelected;

  const _AIResultSheet({required this.text, required this.isSelected});

  @override
  State<_AIResultSheet> createState() => _AIResultSheetState();
}

class _AIResultSheetState extends State<_AIResultSheet> {
  String? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAIResult();
  }

  Future<void> _fetchAIResult() async {
    setState(() => _loading = true);
    final result = widget.isSelected
        ? await AIService.explainText(widget.text)
        : await AIService.explainFullPage(widget.text);
    if (mounted) {
      setState(() {
        _result = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // رأس الشيت
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF6200EE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isSelected
                        ? 'شرح الذكاء الاصطناعي للنص المحدد'
                        : 'شرح الذكاء الاصطناعي للصفحة الكاملة',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // النص المحدد
          if (widget.isSelected && widget.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('النص المحدد:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 4),
                  Text(
                    widget.text.length > 200
                        ? '${widget.text.substring(0, 200)}...'
                        : widget.text,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

          // النتيجة
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحليل المحتوى...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _result ?? 'لا توجد نتيجة',
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
          ),

          if (!_loading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _fetchAIResult,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EE),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _HelpOption(this.label, this.onTap, {this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 24),
            if (icon != null) const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
