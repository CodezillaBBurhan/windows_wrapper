#ifndef RUNNER_RUNTIME_CHANNEL_HANDLER_H_
#define RUNNER_RUNTIME_CHANNEL_HANDLER_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>

#include "window_embedder.h"

// Handles platform channel calls from Dart for runtime window embedding.
class RuntimeChannelHandler {
 public:
  RuntimeChannelHandler(flutter::BinaryMessenger* messenger,
                        HWND main_window,
                        HWND flutter_view);
  ~RuntimeChannelHandler();

  void SetFlutterViewVisible(bool visible);

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool IsProcessRunning(DWORD process_id);
  bool RequestCameraPermission();

  HWND main_window_;
  HWND flutter_view_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<WindowEmbedder> embedder_;
};

#endif  // RUNNER_RUNTIME_CHANNEL_HANDLER_H_
