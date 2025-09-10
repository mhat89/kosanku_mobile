import 'package:flutter/cupertino.dart';
import 'package:bot_toast/bot_toast.dart';

enum BannerStyle { info, success, warn, error }

class Notifier {
  // ====== Toast singkat di bawah ======
  static CancelFunc info(String msg) =>
      _toast(msg, CupertinoColors.activeBlue);
  static CancelFunc success(String msg) =>
      _toast(msg, CupertinoColors.activeGreen);
  static CancelFunc warn(String msg) =>
      _toast(msg, CupertinoColors.activeOrange);
  static CancelFunc error(String msg) =>
      _toast(msg, CupertinoColors.systemRed);

  static CancelFunc _toast(String msg, Color dotColor) {
    // ⛳ Perhatikan: pakai *toastBuilder* dan param nya (cancel), BUKAN (context)
    return BotToast.showCustomText(
      duration: const Duration(seconds: 2),
      toastBuilder: (cancel) => SafeArea(
        bottom: true,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: cancel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withOpacity(0.85),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            msg,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====== Banner notifikasi di atas ======
  static CancelFunc bannerTop(
      String msg, {
        BannerStyle style = BannerStyle.info,
        Duration duration = const Duration(seconds: 3),
      }) {
    final color = switch (style) {
      BannerStyle.success => CupertinoColors.activeGreen,
      BannerStyle.warn => CupertinoColors.activeOrange,
      BannerStyle.error => CupertinoColors.systemRed,
      _ => CupertinoColors.activeBlue,
    };

    // ⛳ Pakai *toastBuilder: (cancel) => ...*
    return BotToast.showCustomNotification(
      align: Alignment.topCenter,
      duration: duration,
      toastBuilder: (cancel) => SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
              ),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 30,
                      onPressed: cancel,
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
