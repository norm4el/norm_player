import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_web;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:flutter/foundation.dart';

import 'package:norm_player/utils/theme/app_theme.dart';
import '../../providers/playlists/local_playlists_provider.dart';

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
        ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36")
        ..addJavaScriptChannel(
          'SnifferChannel',
          onMessageReceived: (JavaScriptMessage message) {
            if (mounted) {
              setState(() {
                detectedAudioUrl = message.message;
                detectedAudioTitle = 'Audio_Track_\${DateTime.now().second}';
              });
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                isPageLoading = true;
                urlController.text = url;
                detectedAudioUrl = null;
                detectedAudioTitle = null;
              });
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
            onNavigationRequest: (NavigationRequest request) {
              if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) {
                return NavigationDecision.prevent;
              }
              if (request.url.contains('youtube.com/watch') || request.url.contains('youtu.be/')) {
                 _showYoutubeActionSheet(request.url);
                 return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
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
          if (url.contains('youtube.com/watch') || url.contains('youtu.be/')) {
            _showYoutubeActionSheet(url);
          }
        }
      });
      
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
      debugPrint('Windows WebView error: \$e');
    }
  }

  Future<void> _showYoutubeActionSheet(String url) async {
    try {
      var video = await _ytExplode.videos.get(url);
      
      if (!mounted) return;
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          message: Text(video.author),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: const Text('Загрузить', style: TextStyle(color: AppTheme.primaryColor)),
              onPressed: () {
                Navigator.pop(context);
                _downloadAudioFromYoutube(video);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Скопировать ссылку', style: TextStyle(color: AppTheme.primaryColor)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отменить'),
          ),
        ),
      );
    } catch (e) {
      debugPrint('YouTube Action Sheet Error: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка получения данных YouTube: \$e')));
      }
    }
  }

  String _getAdvancedSnifferJs() {
    return '''
      (function() {
        if (window._audioSnifferInjected) return;
        window._audioSnifferInjected = true;

        var lastReportedUrl = '';
        function reportAudio(url) {
          if (!url || typeof url !== 'string' || url.startsWith('blob:') || url.startsWith('data:')) return;
          if (url === lastReportedUrl) return;
          
          var lowerUrl = url.toLowerCase();
          var isAudio = lowerUrl.includes('.mp3') || lowerUrl.includes('.m4a') || lowerUrl.includes('.wav') || lowerUrl.includes('audio') || lowerUrl.includes('music') || lowerUrl.includes('track');
          
          if (!isAudio) return;
          
          lastReportedUrl = url;
          try {
            if (typeof SnifferChannel !== 'undefined') {
               SnifferChannel.postMessage(url);
            } else if (window.chrome && window.chrome.webview) {
               window.chrome.webview.postMessage(url);
            }
          } catch(e) {}
        }

        // 1. Intercept window.Audio
        var OriginalAudio = window.Audio;
        window.Audio = function() {
          var audio = new OriginalAudio();
          audio.addEventListener('play', function() { reportAudio(audio.src); });
          return audio;
        };

        // 2. Intercept src setter on HTMLMediaElement
        var originalSrcDescriptor = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
        if (originalSrcDescriptor) {
            Object.defineProperty(HTMLMediaElement.prototype, 'src', {
                set: function(value) {
                    reportAudio(value);
                    originalSrcDescriptor.set.call(this, value);
                },
                get: function() {
                    return originalSrcDescriptor.get.call(this);
                }
            });
        }

        // 3. Scan existing DOM
        function checkExisting() {
          var audios = document.querySelectorAll('audio');
          for(var i=0; i<audios.length; i++) {
            if(audios[i].src) reportAudio(audios[i].src);
            audios[i].addEventListener('play', function(e) { reportAudio(e.target.src); });
          }
          var links = document.querySelectorAll('a');
          for(var i=0; i<links.length; i++) {
            if(links[i].href && (links[i].href.endsWith('.mp3') || links[i].href.endsWith('.m4a'))) {
              reportAudio(links[i].href);
            }
          }
        }
        checkExisting();

        // 4. Monitor DOM changes
        var observer = new MutationObserver(function(mutations) {
           mutations.forEach(function(mutation) {
               mutation.addedNodes.forEach(function(node) {
                   if (node.tagName === 'AUDIO') {
                       if (node.src) reportAudio(node.src);
                       node.addEventListener('play', function(e) { reportAudio(e.target.src); });
                   } else if (node.tagName === 'A' && node.href && (node.href.endsWith('.mp3'))) {
                       reportAudio(node.href);
                   } else if (node.querySelectorAll) {
                       try {
                           var audios = node.querySelectorAll('audio');
                           audios.forEach(function(a) { 
                               if (a.src) reportAudio(a.src); 
                               a.addEventListener('play', function(e) { reportAudio(e.target.src); });
                           });
                       } catch(e) {}
                   }
               });
           });
        });
        observer.observe(document.body, { childList: true, subtree: true });
        
        // 5. Fallback polling for dynamically attached streams
        setInterval(checkExisting, 1500);
      })();
    ''';
  }

  Future<void> _injectAudioSnifferMobile() async {
    try {
      await _webViewController.runJavaScript(_getAdvancedSnifferJs());
    } catch (e) {
      debugPrint('Sniffer inject error: \$e');
    }
  }

  Future<void> _injectAudioSnifferWindows() async {
    try {
      await _winWebViewController.executeScript(_getAdvancedSnifferJs());
    } catch (e) {
      debugPrint('Windows JS inject error: \$e');
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

  void _navigateToUrl(String targetUrl) async {
    String finalUrl = targetUrl.trim();
    if (finalUrl.isEmpty) return;

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      if (finalUrl.contains('.') && !finalUrl.contains(' ')) {
        finalUrl = 'https://\$finalUrl';
      } else {
        finalUrl = 'https://www.google.com/search?q=\${Uri.encodeComponent(finalUrl)}';
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
        Future.delayed(const Duration(seconds: 3), () => _injectAudioSnifferWindows());
      }
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      _webViewController.loadRequest(Uri.parse(finalUrl));
    }
  }

  Future<void> _downloadAudioFromYoutube(yt.Video video) async {
    try {
      var manifest = await _ytExplode.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      _downloadAudio(audioStream.url.toString(), video.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка получения аудио: \$e')));
      }
    }
  }

  Future<void> _downloadAudio(String audioUrl, String trackTitle) async {
    if (audioUrl.startsWith('blob:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('К сожалению, защищенные (blob) треки скачать нельзя. Попробуйте найти прямую ссылку или YouTube!'), backgroundColor: Colors.orange),
      );
      return;
    }

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

      setState(() {
        isDownloading = false;
        currentStatus = 'Сохранено: \$trackTitle';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек "\$trackTitle" успешно загружен!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        isDownloading = false;
        currentStatus = 'Ошибка: \$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка скачивания: \$e')));
      }
    }
  }

  Widget _buildWebView() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (!_isWinWebViewInitialized) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
      }
      return win_web.Webview(_winWebViewController);
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (isPageLoading)
            const Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(color: AppTheme.primaryColor, backgroundColor: Colors.transparent),
            ),
        ],
      );
    } else {
      return Center(
        child: Text(
          'Браузер пока не поддерживается на этой платформе.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }
  }

  void _goBack() {
    if (isBrowserOpen) {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        _winWebViewController.goBack();
      } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        _webViewController.canGoBack().then((value) {
          if (value) {
            _webViewController.goBack();
          } else {
            setState(() {
              isBrowserOpen = false;
              urlController.clear();
            });
          }
        });
      }
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

  Widget _buildBookmarksGrid() {
    final bookmarks = [
      {'title': 'YouTube', 'url': 'https://m.youtube.com', 'icon': Icons.play_circle_filled, 'color': Colors.red},
      {'title': 'VK', 'url': 'https://m.vk.com/audio', 'icon': Icons.music_note, 'color': Colors.blue},
      {'title': 'Zaycev', 'url': 'https://zaycev.net', 'icon': Icons.download, 'color': Colors.amber},
      {'title': 'SoundCloud', 'url': 'https://m.soundcloud.com', 'icon': Icons.cloud, 'color': Colors.orange},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Закладки', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final b = bookmarks[index];
              return GestureDetector(
                onTap: () => _navigateToUrl(b['url'] as String),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(b['icon'] as IconData, color: b['color'] as Color, size: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b['title'] as String,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
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
                    hintText: 'Веб-поиск или имя сайта',
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
            
            if (detectedAudioUrl != null && isBrowserOpen)
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
              child: isBrowserOpen ? _buildWebView() : _buildBookmarksGrid(),
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
                      icon: const Icon(Icons.share_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                         if (urlController.text.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: urlController.text));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
                         }
                      },
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
