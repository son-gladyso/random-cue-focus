#ifndef RUNNER_APP_FLUTTER_WINDOW_H_
#define RUNNER_APP_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "win32_window.h"

class AppFlutterWindow : public Win32Window {
 public:
  explicit AppFlutterWindow(const flutter::DartProject& project);
  virtual ~AppFlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  void RegisterMethodChannel();
  void InitializeTray();
  void UpdateTrayState(bool running);
  void ShowNativeNotification(const std::wstring& title,
                              const std::wstring& body);
  void ShowNativeWindow();
  void HideNativeWindow();
  void CloseNativeWindow();
  void ExitNativeApp();
  void InvokeDartCommand(const std::string& method);
  std::wstring Utf8ToWide(const std::string& value);
};

#endif  // RUNNER_APP_FLUTTER_WINDOW_H_
