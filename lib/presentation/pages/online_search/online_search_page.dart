import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_web;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/utils/theme/app_theme.dart';
import 'package:flutter/foundation.dart';

class OnlineSearchPage extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const OnlineSearchPage({super.key, required this.scrollController});

  @override
  ConsumerState<OnlineSearchPage> createState() => _OnlineSearchPageState();
}

class _OnlineSearchPageState extends ConsumerState<OnlineSearchPage> {
  final TextEditingController urlController = TextEditingController();
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String currentStatus = '';
  
  late WebViewController _webViewController;
  final win_web.WebviewController _winWebViewController = win_web.WebviewController();
  
  bool isBrowserOpen = false;
  bool isPageLoading = false;
  bool _isWinWebViewInitialized = false;
  String? detectedAudioUrl;
  String? detectedAudioTitle;

  final yt.YoutubeExplode _ytExplode = yt.YoutubeExplode();

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    if (kIsWeb) return;
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _initWindowsWebView();
      return;
    }
    
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                isPageLoading = true;
                urlController.text = url;
                detectedAudioUrl = null;
                detectedAudioTitle = null;
              });
              _checkYoutubeUrl(url);
            },
            onPageFinished: (String url) {
              setState(() {
                isPageLoading = false;
              });
              _injectAudioSnifferMobile();
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                isPageLoading = false;
              });
            },
          ),
        );
    }
  }

  Future<void> _initWindowsWebView() async {
    try {
      await _winWebViewController.initialize();
      _winWebViewController.url.listen((url) {
        if (mounted) {
          setState(() {
            urlController.text = url;
            detectedAudioUrl = null;
            detectedAudioTitle = null;
          });
          _checkYoutubeUrl(url);
        }
      });
      
      // We will listen for JS messages
      _winWebViewController.webMessage.listen((msg) {
        if (mounted && msg is String) {
          setState(() {
            detectedAudioUrl = msg;
            detectedAudioTitle = 'Audio_Track_\${DateTime.now().second}';
          });
        }
      });
      
      setState(() {
        _isWinWebViewInitialized = true;
      });
    } catch (e) {
      debugPrint('Windows WebView error: $e');
    }
  }

  Future<void> _checkYoutubeUrl(String url) async {
    if (url.contains('youtube.com/watch') || url.contains('youtu.be/')) {
      try {
        var video = await _ytExplode.videos.get(url);
        var manifest = await _ytExplode.videos.streamsClient.getManifest(video.id);
        var audioStream = manifest.audioOnly.withHighestBitrate();
        setState(() {
          detectedAudioUrl = audioStream.url.toString();
          detectedAudioTitle = video.title;
        });
      } catch (e) {
        debugPrint('YouTube Extract Error: $e');
      }
    }
  }

  Future<void> _injectAudioSnifferMobile() async {
    final js = '''
      (function() {
        var audios = document.getElementsByTagName('audio');
        if(audios.length > 0 && audios[0].src) {
          SnifferChannel.postMessage(audios[0].src);
          return;
        }
        var links = document.getElementsByTagName('a');
        for(var i=0; i<links.length; i++) {
          if(links[i].href.endsWith('.mp3')) {
            SnifferChannel.postMessage(links[i].href);
            return;
          }
        }
      })();
    ''';
    
    try {
      await _webViewController.addJavaScriptChannel(
        'SnifferChannel',
        onMessageReceived: (JavaScriptMessage message) {
          setState(() {
            detectedAudioUrl = message.message;
            detectedAudioTitle = 'Audio_Track_\${DateTime.now().second}';
          });
        },
      );
      await _webViewController.runJavaScript(js);
    } catch (e) {
      debugPrint('Sniffer inject error: $e');
    }
  }

  Future<void> _injectAudioSnifferWindows() async {
    final js = '''
      (function() {
        var audios = document.getElementsByTagName('audio');
        if(audios.length > 0 && audios[0].src) {
          window.chrome.webview.postMessage(audios[0].src);
          return;
        }
        var links = document.getElementsByTagName('a');
        for(var i=0; i<links.length; i++) {
          if(links[i].href.endsWith('.mp3')) {
            window.chrome.webview.postMessage(links[i].href);
            return;
          }
        }
      })();
    ''';
    try {
      await _winWebViewController.executeScript(js);
    } catch (e) {
      debugPrint('Windows JS inject error: $e');
    }
  }

  @override
  void dispose() {
    urlController.dispose();
    _ytExplode.close();
    if (_isWinWebViewInitialized) {
      _winWebViewController.dispose();
    }
    super.dispose();
  }

  void _navigateToUrl(String targetUrl) {
    String finalUrl = targetUrl.trim();
    if (finalUrl.isEmpty) return;

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      if (finalUrl.contains('.') && !finalUrl.contains(' ')) {
        finalUrl = 'https://$finalUrl';
      } else {
        finalUrl = 'https://www.google.com/search?q=\${Uri.encodeComponent("\$finalUrl скачать mp3")}';
      }
    }

    setState(() {
      isBrowserOpen = true;
      urlController.text = finalUrl;
      detectedAudioUrl = null;
    });

    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (_isWinWebViewInitialized) {
        _winWebViewController.loadUrl(finalUrl);
        // Inject JS after a short delay since we don't have onPageFinished easily accessible here
        Future.delayed(const Duration(seconds: 3), () => _injectAudioSnifferWindows());
      }
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      _webViewController.loadRequest(Uri.parse(finalUrl));
    } else {
      if (finalUrl.contains('youtube.com/watch')) {
        _checkYoutubeUrl(finalUrl);
      }
    }
  }

  Future<void> _downloadAudio(String audioUrl, String trackTitle) async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
      currentStatus = 'Скачивание \$trackTitle...';
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicFolder = Directory('\${appDir.path}/NormMusic');
      if (!await musicFolder.exists()) {
        await musicFolder.create(recursive: true);
      }

      final sanitizedName = trackTitle.replaceAll(RegExp(r'[\\\\/:*?"<>|]'), '_');
      final savePath = '\${musicFolder.path}/\$sanitizedName.mp3';

      final dio = Dio();
      await dio.download(
        audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      ref.invalidate(getAllMusicProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Трек "\$trackTitle" скачан! 🎧'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка скачивания: \$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
          currentStatus = '';
        });
      }
    }
  }

  Widget _buildWebView() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (!_isWinWebViewInitialized) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
      }
      return Stack(
        children: [
          win_web.Webview(_winWebViewController),
          if (isPageLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ],
      );
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (isPageLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ],
      );
    } else {
      return Center(
        child: Text(
          'Браузер пока не поддерживается на этой платформе.\nНо вы можете вставить ссылку с YouTube!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }
  }

  void _goBack() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _winWebViewController.goBack();
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      _webViewController.goBack();
    }
  }

  void _goForward() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _winWebViewController.goForward();
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      _webViewController.goForward();
    }
  }

  void _reload() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _winWebViewController.reload();
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: urlController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  onSubmitted: _navigateToUrl,
                  decoration: InputDecoration(
                    hintText: 'Веб-поиск или ссылка (YouTube)...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor),
                      onPressed: () => _navigateToUrl(urlController.text),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
            
            if (detectedAudioUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.accentPink.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentPink, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Найдено аудио на странице!',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      label: const Text('Скачать', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _downloadAudio(detectedAudioUrl!, detectedAudioTitle ?? 'Audio_Download_\${DateTime.now().second}'),
                    ),
                  ],
                ),
              ),

            if (isDownloading)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '\$currentStatus \${(downloadProgress * 100).toInt()}%',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: isBrowserOpen
                  ? _buildWebView()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.travel_explore_rounded, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Введите поисковой запрос или ссылку',
                            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
            ),
            
            if (isBrowserOpen)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: _goBack,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: _goForward,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: _reload,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.accentPink, size: 22),
                      onPressed: () {
                        setState(() {
                          isBrowserOpen = false;
                          urlController.clear();
                          detectedAudioUrl = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
