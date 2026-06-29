#include "runtime_channel_handler.h"

#include <windows.h>
#include <tlhelp32.h>

#include <variant>

namespace {

int GetIntArg(const flutter::EncodableMap& map,
              const char* key,
              int default_value) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return default_value;
  }
  if (auto* value = std::get_if<int32_t>(&it->second)) {
    return *value;
  }
  if (auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  return default_value;
}

bool GetBoolArg(const flutter::EncodableMap& map,
                const char* key,
                bool default_value) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return default_value;
  }
  if (auto* value = std::get_if<bool>(&it->second)) {
    return *value;
  }
  return default_value;
}

std::wstring GetStringArg(const flutter::EncodableMap& map,
                          const char* key,
                          const std::wstring& default_value) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return default_value;
  }
  if (auto* value = std::get_if<std::string>(&it->second)) {
    return std::wstring(value->begin(), value->end());
  }
  return default_value;
}

}  // namespace

RuntimeChannelHandler::RuntimeChannelHandler(
    flutter::BinaryMessenger* messenger,
    HWND main_window,
    HWND flutter_view)
    : main_window_(main_window),
      flutter_view_(flutter_view),
      embedder_(std::make_unique<WindowEmbedder>(main_window)) {
  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "com.worky.android_wrapper/runtime",
          &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });
}

RuntimeChannelHandler::~RuntimeChannelHandler() = default;

void RuntimeChannelHandler::SetFlutterViewVisible(bool visible) {
  if (flutter_view_ != nullptr) {
    ShowWindow(flutter_view_, visible ? SW_SHOW : SW_HIDE);
  }
}

bool RuntimeChannelHandler::IsProcessRunning(DWORD process_id) {
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) {
    return false;
  }

  PROCESSENTRY32W entry = {};
  entry.dwSize = sizeof(entry);
  bool found = false;

  if (Process32FirstW(snapshot, &entry)) {
    do {
      if (entry.th32ProcessID == process_id) {
        found = true;
        break;
      }
    } while (Process32NextW(snapshot, &entry));
  }

  CloseHandle(snapshot);
  return found;
}

bool RuntimeChannelHandler::RequestCameraPermission() {
  // Windows 10/11: prompt user via Settings if camera access is blocked.
  // For desktop apps, camera access is generally allowed when hardware exists.
  return true;
}

void RuntimeChannelHandler::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();

  if (method == "createEmbedHost") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("invalid_args", "Missing arguments");
      return;
    }

    RECT client = {};
    GetClientRect(main_window_, &client);
    const int width = GetIntArg(*args, "width", client.right - client.left);
    const int height = GetIntArg(*args, "height", client.bottom - client.top);

    const bool ok = embedder_->CreateHost(0, 0, width, height);
    result->Success(flutter::EncodableValue(ok));
    return;
  }

  if (method == "embedProcessWindow") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("invalid_args", "Missing arguments");
      return;
    }

    const int process_id = GetIntArg(*args, "processId", 0);
    const auto title_hint =
        GetStringArg(*args, "windowTitleHint", L"Android Emulator");
    const int timeout_ms = GetIntArg(*args, "timeoutMs", 120000);

    const bool ok = embedder_->EmbedProcessWindow(
        static_cast<DWORD>(process_id), title_hint,
        static_cast<DWORD>(timeout_ms));
    result->Success(flutter::EncodableValue(ok));
    return;
  }

  if (method == "resizeEmbedHost") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("invalid_args", "Missing arguments");
      return;
    }

    embedder_->ResizeHost(GetIntArg(*args, "width", 800),
                          GetIntArg(*args, "height", 600));
    result->Success();
    return;
  }

  if (method == "setEmbedHostVisible") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("invalid_args", "Missing arguments");
      return;
    }
    embedder_->SetHostVisible(GetBoolArg(*args, "visible", true));
    result->Success();
    return;
  }

  if (method == "setFlutterViewVisible") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("invalid_args", "Missing arguments");
      return;
    }
    SetFlutterViewVisible(GetBoolArg(*args, "visible", true));
    result->Success();
    return;
  }

  if (method == "destroyEmbedHost") {
    embedder_->DestroyHost();
    SetFlutterViewVisible(true);
    result->Success();
    return;
  }

  if (method == "isProcessRunning") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("invalid_args", "Missing arguments");
      return;
    }
    const int process_id = GetIntArg(*args, "processId", 0);
    result->Success(flutter::EncodableValue(
        IsProcessRunning(static_cast<DWORD>(process_id))));
    return;
  }

  if (method == "requestCameraPermission") {
    result->Success(flutter::EncodableValue(RequestCameraPermission()));
    return;
  }

  result->NotImplemented();
}
