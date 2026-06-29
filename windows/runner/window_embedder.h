#ifndef RUNNER_WINDOW_EMBEDDER_H_
#define RUNNER_WINDOW_EMBEDDER_H_

#include <windows.h>

#include <optional>
#include <string>

// Manages a native host panel and embeds external process windows via SetParent.
class WindowEmbedder {
 public:
  explicit WindowEmbedder(HWND parent_window);
  ~WindowEmbedder();

  bool CreateHost(int x, int y, int width, int height);
  void DestroyHost();
  void SetHostVisible(bool visible);
  void ResizeHost(int width, int height);

  bool EmbedProcessWindow(DWORD process_id,
                          const std::wstring& title_hint,
                          DWORD timeout_ms);

  HWND host_handle() const { return host_handle_; }
  HWND embedded_handle() const { return embedded_handle_; }

 private:
  HWND FindTopLevelWindowForProcess(DWORD process_id,
                                    const std::wstring& title_hint);
  bool ApplyEmbeddedStyles(HWND child);
  void ResizeEmbeddedToHost();

  HWND parent_window_;
  HWND host_handle_ = nullptr;
  HWND embedded_handle_ = nullptr;
};

#endif  // RUNNER_WINDOW_EMBEDDER_H_
