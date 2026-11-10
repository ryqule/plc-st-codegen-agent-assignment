# 复现指南

本文区分“查看已交付结果”“运行本地检查”“重新调用模型”和“PLC runtime 验证”。后两者成本和工具要求不同；不要把离线编译当成 runtime 测试。

## 1. 环境要求

| 用途 | 要求 |
|---|---|
| 数据集与 Python 检查 | Python 3.10+；只使用标准库 |
| Pi coding-agent 基线 | Node.js 22.19+、npm；依赖版本由 `package-lock.json` 固定 |
| 离线 CODESYS 编译 | Windows、CODESYS V3.5 SP22 Patch 4（编译器 3.5.22.40）及 Control Win x64 设备描述 |
| P02 ST 测试 | Windows 版 STruC++ 0.7.0 |
| P02 CBMC 检查 | WSL Ubuntu、CBMC 5.95.1、Windows 版 STruC++ |
| 新模型实验 | 上述 Pi 环境、DMXAPI 账户及由操作者设置的预算上限 |

离线编译需要已安装 CODESYS 工程/脚本环境，但不要求运行 Control Win 服务。当前交付没有 PLC runtime adapter，112 个数据集测试场景尚未在 CODESYS runtime 中执行。

## 2. 克隆与本地检查

```powershell
git clone https://github.com/yedou37/plc-st-codegen-agent-assignment.git
Set-Location plc-st-codegen-agent-assignment
py --version
py -m unittest discover -s tests -v
```

Python 检查不会调用模型 API。查看最终结果无需安装 Node 或 CODESYS：打开 `experiments/results.csv`、`report/实验报告.pdf` 和 `验收对照表.md` 即可。

若要运行 Pi 基线：

```powershell
node --version   # 应为 v22.19.0 或更新
npm ci
```

不要用未固定版本的 `npm install` 替代 `npm ci`；实验框架基线版本为 `@earendil-works/pi-coding-agent@1.5.0`。

## 3. 重跑 P02 的 ST 功能测试

从 [STruC++ 官方 Releases](https://github.com/Autonomy-Logic/STruCpp/releases) 安装 Windows x64 版本，并在 PowerShell 中将可执行文件路径传给 `--strucpp`。下面的例子会把新结果写进 Git 忽略的本地运行目录：

```powershell
New-Item -ItemType Directory -Force experiments/local_runs | Out-Null
py tools/run_st_tests.py `
  --source st/runs/pi/deepseek/P02.st `
  --test-template tests/structured_text/P02_test.st `
  --strucpp C:\Tools\STruCpp\strucpp.exe `
  --result experiments/local_runs/P02_pi_deepseek.json
```

每种 Agent/模型对应的输入文件：

| Agent | 模型 | 源码 |
|---|---|---|
| Pi | DeepSeek | `st/runs/pi/deepseek/P02.st` |
| Pi | GPT | `st/runs/pi/gpt/P02.st` |
| 自研 harness | DeepSeek | `st/runs/self/deepseek/P02_attempt1.st` |
| 自研 harness | GPT | `st/runs/self/gpt/P02_attempt1.st` |

同一个模板包含 5 个扫描周期测试。当前保存的四份测试结果在 `experiments/functional_tests/`。DeepSeek/Pi 的一个位掩码表达式会在测试副本中做等价归一化；源文件不被改写，转换前后哈希记录在 JSON。完整说明见 [`../tests/structured_text/README.md`](../tests/structured_text/README.md)。

## 4. 重跑 P02 的 CBMC 有界检查

CBMC 在 WSL 安装：

```powershell
wsl -e bash -lc 'sudo apt-get update && sudo apt-get install -y cbmc'
```

先确认 `cbmc --version` 在 WSL 中可用，再用同一套 STruC++ 可执行文件生成翻译并交给 CBMC：

```powershell
py tools/run_p02_cbmc.py `
  --source st/runs/pi/gpt/P02.st `
  --strucpp C:\Tools\STruCpp\strucpp.exe `
  --output-dir experiments/local_runs/formal_verification/P02_pi_gpt
```

命令会写入生成的 C++、harness、`cbmc.log` 和 `result.json`。逐输出的已交付结果在 `experiments/formal_verification/P02_*`。该验证检查的是 STruC++ 翻译代码及脚本列出的有界性质，不等价于 CODESYS runtime，也不覆盖其余 29 题或全部 LTL。

## 5. 单个 CODESYS 离线编译

安装 CODESYS V3.5 SP22 Patch 4 和 Control Win x64 设备描述。适配器会尝试自动发现安装位置；如自动发现失败，可设置 `CODESYS_EXE` 指向 CODESYS IDE 可执行文件，并用 `CODESYS_PROFILE` 指定已安装 profile。

```powershell
New-Item -ItemType Directory -Force experiments/local_runs | Out-Null
py tools/codesys_compile.py `
  --source st/runs/pi/deepseek/P02.st `
  --task-id P02 `
  --output experiments/local_runs/P02_codesys_compile.json
```

这条命令是单个 POU 的离线项目编译，不会启动 PLC 扫描。P07/P17 的 DUT 在 `st/support_types/`。原始矩阵日志位于 `st/runs/`；原始失败项的修正适配器复测在 `experiments/posthoc_repair/`。如要重跑 30 格复测，使用：

```powershell
py tools/posthoc_recheck_failures.py `
  --output-dir experiments/local_runs/posthoc_repair
```

复测脚本读取原始 `experiments/results.csv` 和各单元源码；它不修改这些源码。输出目录应使用 `experiments/local_runs/` 下的新路径，避免覆盖随仓库交付的证据。PLC runtime 服务和 runtime 测试 adapter 没有配置，所以本仓库无法据此执行 112 个 runtime 场景。

## 6. 可选：运行新模型实验

新模型请求会产生真实费用。正式项目历史费用不是新运行的报价；模型价格、token 数和失败重试都会影响成本。先使用小预算 pilot，确认设置正确后再由项目负责人决定是否做全量。

PowerShell 安全输入密钥并在当前会话运行小预算 pilot（密钥不会回显到终端）：

```powershell
$secureKey = Read-Host 'DMXAPI API key' -AsSecureString
$keyPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
try {
  $env:DMXAPI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPtr)
  py experiments/run_matrix.py `
    --pilot `
    --max-cost-cny 0.25 `
    --output experiments/local_runs/pilot.csv
} finally {
  Remove-Item Env:DMXAPI_API_KEY -ErrorAction SilentlyContinue
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPtr)
  Remove-Variable secureKey,keyPtr -ErrorAction SilentlyContinue
}
```

Pilot 选择 P02 和 S08，在四种条件下最多发出 8 个模型请求。`0.25` CNY 是**本次运行上限**示例，不保证能完成所有请求；超过上限的请求会被预算代理拦截。若要重新运行 120 格，把 `--pilot` 替换为 `--full` 并显式选择新的预算上限；不要把输出写入正式 `experiments/results.csv`。例如：

```powershell
py experiments/run_matrix.py `
  --full `
  --max-cost-cny 1.00 `
  --output experiments/local_runs/full_matrix.csv
```

上面只展示运行参数。运行前仍需按前面的安全输入方式设置 `DMXAPI_API_KEY`。默认上限为 1.00 CNY；要提高上限，必须由密钥所有者根据自己的授权额度明确决定。配置和模型参数见 `experiments/config.example.json`。DeepSeek 的 thinking 已按诊断结果关闭。切勿把密钥写入 JSON、shell 脚本、GitHub Issue 或提交记录。

`--resume` 只应配合**同一份本地运行 CSV**使用；脚本会读取同目录的 usage 分片日志，并复用已完成的单元。每次运行会生成 CSV、汇总 JSON、usage JSONL 和 ST 输出。默认均落入 `experiments/local_runs/`，该目录被 Git 忽略。

## 7. 生成提交 ZIP

```powershell
$zip = Join-Path (Split-Path -Parent (Get-Location).Path) 'PLC_ST_Agent_Submission.zip'
& .\tools\package_submission.ps1 -OutputPath $zip
```

打包脚本会排除 `.git`、Python 缓存、`node_modules` 和 `*_QA.pdf`，并检查报告、数据集和原始结果矩阵是否包含在 ZIP 中。

## 8. 输出状态怎么读

- `PASS` / `FAIL`：对应记录所标明编译器、输入视图和 adapter 的离线编译结果。
- `TIMEOUT`：编译调用超时；检查单独保存的超时重试证据，不能自行覆盖首次结果。
- `NOT_RUN`、`UNAVAILABLE`：没有取得通过证据，绝不能计作 PASS。
- `experiments/results.csv` 是原始矩阵；`experiments/posthoc_repair/recheck.csv` 是修正项目适配器后对原始失败单元的单独复测。两者分开报告。
- 所有已提交的 `st/runs/` 文件均是模型输出或其有限修复尝试；除报告明确列出的 P02 加分项外，数据集 112 个 runtime 场景并没有逐题执行。

## 9. 重算汇总

`tools/finalize_matrix.py` 不调用模型 API。默认读取归档矩阵、DeepSeek 60 格恢复、四个超时重试和归档 usage 日志，并将重算结果写到 `experiments/local_runs/finalized_matrix/`：

```powershell
py tools/finalize_matrix.py
```

脚本**不会**把 post-hoc 30 格 CODESYS 复测合并进 120 格正式矩阵。只有明确想替换归档结果并已核对输入及 Git diff 时，才运行 `py tools/finalize_matrix.py --write-archive`；该选项会重写 `experiments/results.csv` 与 `experiments/results_summary.json`。
