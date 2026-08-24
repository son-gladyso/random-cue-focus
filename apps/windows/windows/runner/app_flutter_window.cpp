#include "app_flutter_window.h"

#include <shellapi.h>
#include <windows.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kMenuShow = 1001;
constexpr UINT kMenuStartPause = 1002;
constexpr UINT kMenuStop = 1003;
constexpr UINT kMenuExit = 1004;
}  // namespace

AppFlutterWindow::AppFlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

AppFlutterWindow::~AppFlutterWindow() {}

bool AppFlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());
  RegisterMethodChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();

  return true;
}

void AppFlutterWindow::OnDestroy() {
  NOTIFYICONDATA nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = GetHandle();
  nid.uID = kTrayIconId;
  Shell_NotifyIcon(NIM_DELETE, &nid);

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT AppFlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                         WPARAM const wparam,
                                         LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE:
      HideNativeWindow();
      return 0;
    case WM_COMMAND:
      switch (LOWORD(wparam)) {
        case kMenuShow:
          ShowNativeWindow();
          return 0;
        case kMenuStartPause:
          InvokeDartCommand("startPause");
          return 0;
        case kMenuStop:
          InvokeDartCommand("stop");
          return 0;
        case kMenuExit:
          InvokeDartCommand("exit");
          return 0;
      }
      break;
    case kTrayMessage:
      if (lparam == WM_LBUTTONUP) {
        ShowNativeWindow();
        return 0;
      }
      if (lparam == WM_RBUTTONUP) {
        POINT point;
        GetCursorPos(&point);
        SetForegroundWindow(hwnd);
        HMENU menu = CreatePopupMenu();
        AppendMenu(menu, MF_STRING, kMenuShow, L"显示窗口");
        AppendMenu(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenu(menu, MF_STRING, kMenuStartPause, L"开始 / 暂停");
        AppendMenu(menu, MF_STRING, kMenuStop, L"停止");
        AppendMenu(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenu(menu, MF_STRING, kMenuExit, L"退出");
        TrackPopupMenu(menu, TPM_RIGHTBUTTON, point.x, point.y, 0, hwnd,
                       nullptr);
        DestroyMenu(menu);
        return 0;
      }
      break;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void AppFlutterWindow::RegisterMethodChannel() {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "random_cue_focus/windows",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto& method = call.method_name();
        if (method == "initialize") {
          result->Success();
          return;
        }
        if (method == "initializeTray") {
          InitializeTray();
          result->Success();
          return;
        }
        if (method == "setTrayState") {
          bool running = false;
          const auto* arguments = call.arguments();
          const auto* args =
              arguments ? std::get_if<flutter::EncodableMap>(arguments)
                        : nullptr;
          if (args) {
            auto it = args->find(flutter::EncodableValue("running"));
            if (it != args->end()) {
              running = std::get<bool>(it->second);
            }
          }
          UpdateTrayState(running);
          result->Success();
          return;
        }
        if (method == "showWindow") {
          ShowNativeWindow();
          result->Success();
          return;
        }
        if (method == "hideWindow") {
          HideNativeWindow();
          result->Success();
          return;
        }
        if (method == "closeWindow") {
          CloseNativeWindow();
          result->Success();
          return;
        }
        if (method == "exitApp") {
          ExitNativeApp();
          result->Success();
          return;
        }
        if (method == "notify") {
          std::wstring title = L"Random Cue Focus";
          std::wstring body = L"";
          const auto* arguments = call.arguments();
          const auto* args =
              arguments ? std::get_if<flutter::EncodableMap>(arguments)
                        : nullptr;
          if (args) {
            auto title_it = args->find(flutter::EncodableValue("title"));
            auto body_it = args->find(flutter::EncodableValue("body"));
            if (title_it != args->end()) {
              title = Utf8ToWide(std::get<std::string>(title_it->second));
            }
            if (body_it != args->end()) {
              body = Utf8ToWide(std::get<std::string>(body_it->second));
            }
          }
          ShowNativeNotification(title, body);
          result->Success();
          return;
        }
        result->NotImplemented();
      });
}

void AppFlutterWindow::InitializeTray() {
  NOTIFYICONDATA nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = GetHandle();
  nid.uID = kTrayIconId;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = kTrayMessage;
  nid.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(nid.szTip, L"Random Cue Focus");
  Shell_NotifyIcon(NIM_ADD, &nid);
}

void AppFlutterWindow::UpdateTrayState(bool running) {
  NOTIFYICONDATA nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = GetHandle();
  nid.uID = kTrayIconId;
  nid.uFlags = NIF_TIP;
  wcscpy_s(nid.szTip,
           running ? L"Random Cue Focus - Focus running" : L"Random Cue Focus");
  Shell_NotifyIcon(NIM_MODIFY, &nid);
}

void AppFlutterWindow::ShowNativeNotification(const std::wstring& title,
                                              const std::wstring& body) {
  NOTIFYICONDATA nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = GetHandle();
  nid.uID = kTrayIconId;
  nid.uFlags = NIF_INFO;
  wcsncpy_s(nid.szInfoTitle, title.c_str(), _TRUNCATE);
  wcsncpy_s(nid.szInfo, body.c_str(), _TRUNCATE);
  nid.dwInfoFlags = NIIF_INFO;
  Shell_NotifyIcon(NIM_MODIFY, &nid);
  MessageBeep(MB_ICONINFORMATION);
}

void AppFlutterWindow::ShowNativeWindow() {
  ShowWindow(GetHandle(), SW_SHOWNORMAL);
  SetForegroundWindow(GetHandle());
}

void AppFlutterWindow::HideNativeWindow() {
  ShowWindow(GetHandle(), SW_HIDE);
}

void AppFlutterWindow::CloseNativeWindow() {
  DestroyWindow(GetHandle());
}

void AppFlutterWindow::ExitNativeApp() {
  DestroyWindow(GetHandle());
  PostQuitMessage(0);
}

void AppFlutterWindow::InvokeDartCommand(const std::string& method) {
  if (!channel_) {
    return;
  }
  channel_->InvokeMethod(method, nullptr);
}

std::wstring AppFlutterWindow::Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return L"";
  }
  int size = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                 static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), size);
  return result;
}
