#include "window_embedder.h"

#include <tlhelp32.h>

#include <string>

namespace {

constexpr wchar_t kEmbedHostClassName[] = L"WORKY_EMBED_HOST";

struct EnumWindowsData {
  DWORD process_id;
  std::wstring title_hint;
  HWND result = nullptr;
};

BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lparam) {
  auto* data = reinterpret_cast<EnumWindowsData*>(lparam);

  DWORD window_pid = 0;
  GetWindowThreadProcessId(hwnd, &window_pid);
  if (window_pid != data->process_id) {
    return TRUE;
  }

  if (!IsWindowVisible(hwnd)) {
    return TRUE;
  }

  wchar_t title[512] = {};
  GetWindowTextW(hwnd, title, 512);
  if (title[0] == L'\0') {
    return TRUE;
  }

  if (!data->title_hint.empty()) {
    if (wcsstr(title, data->title_hint.c_str()) == nullptr) {
      return TRUE;
    }
  }

  data->result = hwnd;
  return FALSE;
}

}  // namespace

WindowEmbedder::WindowEmbedder(HWND parent_window)
    : parent_window_(parent_window) {}

WindowEmbedder::~WindowEmbedder() {
  DestroyHost();
}

bool WindowEmbedder::CreateHost(int x, int y, int width, int height) {
  if (host_handle_ != nullptr) {
    ResizeHost(width, height);
    return true;
  }

  WNDCLASSW wc = {};
  wc.lpfnWndProc = DefWindowProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = kEmbedHostClassName;
  wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
  RegisterClassW(&wc);

  host_handle_ = CreateWindowExW(
      0, kEmbedHostClassName, L"", WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN,
      x, y, width, height, parent_window_, nullptr, GetModuleHandle(nullptr),
      nullptr);

  return host_handle_ != nullptr;
}

void WindowEmbedder::DestroyHost() {
  if (embedded_handle_ != nullptr) {
    SetParent(embedded_handle_, nullptr);
    embedded_handle_ = nullptr;
  }

  if (host_handle_ != nullptr) {
    DestroyWindow(host_handle_);
    host_handle_ = nullptr;
  }
}

void WindowEmbedder::SetHostVisible(bool visible) {
  if (host_handle_ != nullptr) {
    ShowWindow(host_handle_, visible ? SW_SHOW : SW_HIDE);
  }
}

void WindowEmbedder::ResizeHost(int width, int height) {
  if (host_handle_ == nullptr) {
    return;
  }

  SetWindowPos(host_handle_, nullptr, 0, 0, width, height,
               SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
  ResizeEmbeddedToHost();
}

HWND WindowEmbedder::FindTopLevelWindowForProcess(
    DWORD process_id,
    const std::wstring& title_hint) {
  EnumWindowsData data{process_id, title_hint, nullptr};
  EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&data));
  return data.result;
}

bool WindowEmbedder::ApplyEmbeddedStyles(HWND child) {
  LONG_PTR style = GetWindowLongPtr(child, GWL_STYLE);
  style &= ~WS_POPUP;
  style |= WS_CHILD;
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX |
             WS_SYSMENU);
  SetWindowLongPtr(child, GWL_STYLE, style);

  LONG_PTR ex_style = GetWindowLongPtr(child, GWL_EXSTYLE);
  ex_style &= ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE |
                WS_EX_STATICEDGE);
  SetWindowLongPtr(child, GWL_EXSTYLE, ex_style);

  return true;
}

void WindowEmbedder::ResizeEmbeddedToHost() {
  if (host_handle_ == nullptr || embedded_handle_ == nullptr) {
    return;
  }

  RECT rect = {};
  GetClientRect(host_handle_, &rect);
  SetWindowPos(embedded_handle_, nullptr, 0, 0, rect.right - rect.left,
               rect.bottom - rect.top,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED |
                   SWP_SHOWWINDOW);
}

bool WindowEmbedder::EmbedProcessWindow(DWORD process_id,
                                        const std::wstring& title_hint,
                                        DWORD timeout_ms) {
  if (host_handle_ == nullptr) {
    return false;
  }

  const DWORD start = GetTickCount();
  HWND target = nullptr;

  while (target == nullptr) {
    target = FindTopLevelWindowForProcess(process_id, title_hint);
    if (target != nullptr) {
      break;
    }
    if (GetTickCount() - start > timeout_ms) {
      return false;
    }
    Sleep(250);
  }

  ApplyEmbeddedStyles(target);
  SetParent(target, host_handle_);
  embedded_handle_ = target;
  ResizeEmbeddedToHost();
  return true;
}
