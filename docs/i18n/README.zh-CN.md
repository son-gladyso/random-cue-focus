# Random Cue Focus

简体中文 · [English](../../README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [繁體中文](README.zh-TW.md)

<!-- Documentation source: random-cue-focus README rewrite 2026-11-12; locale: zh-CN -->

> 你坐下来准备写第三章。四十分钟后，你在读订书机的发明史。
>
> 大多数专注 App 的解法是**加码**：更多闹钟、强制休息、连续打卡、负罪感。这个 App 反过来，做得更少——每隔一阵子轻轻问一句：**"还在做你选的那件事吗？"** 点一下回答，或者干脆不理，计时照走。

本地优先的 Flutter 专注伴侣，支持 **iOS 和 Windows**。没有账号、服务器、广告和统计上报。通知和声音默认**关闭**。

**参考研究证据设计，未经临床验证。** 不宣称能诊断注意力、提升效率，也不宣称"计时器跑了"就能改善学习。

---

## 👋 给人读的部分

### 一次专注是这样的

1. 写下具体目标和你自己的恢复句："**如果**我又拿起手机，**那么**我就重读刚写的最后一段。"
2. 开始专注。默认 50 分钟专注、10 分钟休息。
3. 每 12–18 分钟之间，会出现一个持续 20 秒的目标检查：**还在目标上** / **刚走神了** / **跳过**。专注计时从不停下。
4. 随时暂停、休息或结束；可以选填进展，以及这些打断有多烦人。
5. 回看历史——只存在你自己的设备上。

今天不想被问？整场关闭非必要检查即可。

### 它哪里不一样

- **说实话不会被惩罚。** 承认"我走神了"绝不会让它更频繁地打扰你。
- **用你的话，不用模板。** 目标、分心诱因、恢复动作都可以自己改。
- **刻意朴素。** 节奏调整是确定、可检查的规则，不是机器学习模型，而且至少 3 次专注、6 次回答之后才会调整。
- **没填就是没填。** 跳过的问卷记为缺失，不记成零。

### 为什么这样设计

| 研究发现 | 设计结果 |
|---|---|
| 提醒会打断正在进行的任务 | 通知和声音默认关闭 |
| 短暂休息对精力/疲劳的帮助比对认知表现更稳定 | 检查可选，不承诺提升表现 |
| 执行意图和自我监控有一定支持，但现代去偏估计比早期荟萃分析小 | 包含"如果—那么"计划，但不宣称本 App 或 12–18 分钟默认值已被证明有效 |
| 提取练习和间隔重复对学习的证据更强 | 单靠计时器不是学习干预 |

详见：[证据基础](../EVIDENCE_BASE.md) · [测量计划](../MEASUREMENT_PLAN.md) · [数据字典](../DATA_DICTIONARY.md) · [本地交叉实验协议](../LOCAL_CROSSOVER_PROTOCOL.md) · [学习模式规格](../LEARNING_MODE_SPEC.md)

### 想验证它对**你**有没有用？

有一个**需主动同意**的本地交叉实验：交替进行"无检查"和"稀疏检查"的专注，开始前先保存分组，从不自动上传，随时可退出。研究导出（v2）会去掉会话 ID、日期、绝对分组时间戳和自由文本。

### 发布状态

| 关卡 | 状态 |
|---|---|
| 共享核心测试 · iOS 分析/测试 · iOS 模拟器构建 · Windows 分析/测试/发布构建 | ✅ CI 自动化 |
| 实体 iPhone 通知生命周期 | ⏳ **待完成** |
| 实体 Windows 弹窗、专注助手、睡眠/唤醒、托盘 | ⏳ **待完成** |
| 产品级有效性试验 | ❌ **未进行** |

`0.2.0` 是 A+ **候选**工程升级，不是 A+ 发布。在具名硬件上完成[设备验收](../DEVICE_ACCEPTANCE.md)并附证据之前，发布保持阻塞。

### 常见问题

**这是强制休息计时器吗？** 不是。目标检查从不暂停专注计时；休息是单独的状态。
**为什么我听不到提醒？** 新安装默认关闭声音和通知，需要你主动开启；系统权限和后台行为仍需按平台验证。
**能在 Windows 上装 iPhone 版吗？** 可以在 Windows 上改和测 Dart 代码，但构建和签名需要 macOS 上的 Xcode，见 [iOS 指南](../../apps/ios/README.md)。
**历史记录能证明我学得更多吗？** 不能。时长、完成度和自评都不是客观结果。
**必须参加实验吗？** 不必，需要明确同意。

### 开发

安装稳定版 Flutter。Windows 版在 Windows 上开发，iOS 需要 macOS + Xcode。

```powershell
cd packages\focus_core
dart pub get; dart analyze --fatal-infos; dart test

cd ..\..\apps\windows
flutter pub get; flutter analyze --fatal-infos; flutter test
flutter run -d windows
```

**第一次成功**：构建、输入目标和恢复动作、开始、暂停、继续，看状态变化。这只是本地走查，不等于锁屏、睡眠唤醒或原生通知验收。平台指南：[Windows](../../apps/windows/README.md) · [iOS](../../apps/ios/README.md)。

```text
packages/focus_core/  共享领域模型、迁移、规划器、结果统计、测试
apps/ios/             Flutter iOS 应用 + 本地通知适配
apps/windows/         Flutter Windows 应用 + 原生弹窗/托盘适配
docs/                 证据、架构、隐私、发布验收
```

隐私：[PRIVACY.md](../PRIVACY.md) · [SECURITY.md](../../SECURITY.md) · [ARCHITECTURE.md](../ARCHITECTURE.md)。所有数据都在设备上，清空历史或卸载即删除。

### 参与贡献

特别欢迎：无障碍、迁移安全、平台通知行为、更清楚的目标检查交互。从 [CONTRIBUTING.md](../../CONTRIBUTING.md) 和对应模块的测试开始；设备测试按 [DEVICE_ACCEPTANCE.md](../DEVICE_ACCEPTANCE.md) 记录硬件、系统版本、提交、步骤和实际结果。大改动先开 [issue](https://github.com/son-gladyso/random-cue-focus/issues)。不要把个人目标、历史或研究导出当示例提交。

---

## 🤖 给 AI 读的部分

**先读：** [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md)、[`docs/EVIDENCE_BASE.md`](../EVIDENCE_BASE.md)、[`docs/DATA_DICTIONARY.md`](../DATA_DICTIONARY.md)。[`docs/AI_HANDOFF_LOCAL.md`](../AI_HANDOFF_LOCAL.md) 是历史本地交接，其中的 Windows 路径和分支只属于某台机器，不要照搬执行。

**代码放哪：** 共享行为放 `packages/focus_core`，平台行为放各自 app 适配层，不要在 app 里复制领域逻辑。

**产品约束（不要随意推翻）：**

- 新安装默认：50 分钟专注、10 分钟休息、12–18 分钟检查区间、20 秒响应窗口、通知关、前台声音关。
- 目标检查不暂停专注计时；非必要检查可整场关闭。
- 走神自报**绝不**提高打扰频率。
- 自适应节奏保持确定、可检查；至少 3 次专注、6 次回答后才调整。
- 未回答的结果保持缺失（null），不记为零。
- 不引入账号、服务器、API Key、广告 SDK 或远程统计。

**数据契约：** 设置/会话 schema v6，保留全部旧迁移，不静默丢弃 0.1.x 数据。交叉实验分组在暴露前持久化；注册写入失败不得消耗下一个分组。研究导出 v2 排除原始会话 ID、日期、绝对分组时间戳和自由文本。结果问卷只在完成的会话后出现，因此完成案例的组间差异**不能**描述为因果效应。

**表述纪律：** 不写"提升专注/效率/学习"。不要用模拟器、mock 或 CI 结果勾选实体设备关卡。同时报告跑过和没跑的检查。

**验证：**

```powershell
cd packages/focus_core; dart format --set-exit-if-changed .; dart analyze --fatal-infos; dart test
cd apps/windows;        flutter analyze --fatal-infos; flutter test
cd apps/ios;            flutter analyze --fatal-infos; flutter test
```
