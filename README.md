# PLC Structured Text 代码生成大作业

本仓库包含完整题集、自研 PLC Agent、四条件模型实验、生成的 ST 源码、编译与补充验证证据，以及提交报告。本文面向第一次接手的组员；需要逐步复现实验时，继续阅读 [`docs/REPRODUCING.md`](docs/REPRODUCING.md)。代码 Agent 的协作规则见 [`AGENTS.md`](AGENTS.md)。

## 当前结果与范围

- 数据集共 30 题：20 道给定题、10 道原创题；包含接口、假设、201 条 scan-level LTL 规约和 112 个测试场景。
- 正式矩阵为 30 题 × 2 个模型 × 2 种 Agent，共 120 格。原始矩阵最终为 **90 PASS、30 FAIL、0 TIMEOUT**；见 [`experiments/results.csv`](experiments/results.csv) 和 [`experiments/results_summary.json`](experiments/results_summary.json)。
- 对原始 30 个 FAIL 源码使用修正后的 CODESYS 项目适配器复编译，结果为 **30/30 PASS**，且源码哈希不变。合并证据表示 120 份源码都至少有一次离线编译通过记录；这不是新版适配器对全部 120 格的一次统一重跑。详见 [`experiments/posthoc_repair/README.md`](experiments/posthoc_repair/README.md)。
- P02 的四种输出通过 STruC++ 测试 **20/20**；相应翻译代码通过 CBMC **918 项性质**。两项只覆盖 P02。
- **CODESYS PLC runtime 场景执行数为 0/112。**离线编译、STruC++ 和 CBMC 结果都不能写成完整 PLC runtime 验收通过；其他 29 题的功能测试和全部 LTL 形式验证也没有完成。
- DeepSeek 修复前后的实验和调用费用记录保留在 `experiments/`，但不保留 prompt、模型响应正文或 API key。

完整验收判断见 [`验收对照表.md`](验收对照表.md)，提交内容清单见 [`README_提交说明.md`](README_提交说明.md)，分析细节见 [`report/实验报告.pdf`](report/实验报告.pdf) 或 [`report/实验报告.docx`](report/实验报告.docx)。

## 快速开始

下面的本地数据集检查不需要 DMXAPI 密钥、Node.js、CODESYS 或外网 API：

仓库目前为私有；组员需要先接受仓库协作者邀请，再执行克隆命令。

```powershell
git clone https://github.com/yedou37/plc-st-codegen-agent-assignment.git
Set-Location plc-st-codegen-agent-assignment
py -m unittest discover -s tests -v
```

Python 3.10 或更新版本即可运行 Python 检查脚本；项目不需要额外 pip 包。要运行 Pi 基线，需安装 Node.js 22.19+ 和锁定版本的依赖：

```powershell
node --version
npm ci
```

按需检查 STruC++、CBMC 和 CODESYS 的完整步骤见 [`docs/REPRODUCING.md`](docs/REPRODUCING.md)。

## 仓库导航

| 路径 | 内容 |
|---|---|
| `dataset/` | 题库、标准化的 30 题、原创题来源及重建脚本 |
| `src/` | 自研 Agent、模型 API 适配器、ST 静态检查与提示词 |
| `st/runs/` | 正式矩阵生成的 ST 输出和对应编译日志；`attemptN` 保留自研 Agent 的修复尝试 |
| `st/support_types/` | P07/P17 需要的题目定义 DUT |
| `experiments/results.csv` | 原始 120 格正式矩阵 |
| `experiments/codesys_validation/` | 正式矩阵四个首次超时的重试证据 |
| `experiments/posthoc_repair/` | 30 个原始 FAIL 的修正适配器复测证据 |
| `experiments/functional_tests/` | 四个 P02 STruC++ 运行结果 |
| `experiments/formal_verification/` | 四个 P02 的 CBMC 输入、日志和结果 |
| `experiments/diagnostics/deepseek/` | DeepSeek 空输出诊断、参数 smoke 和恢复结果；不并入原始矩阵 |
| `tests/` | Python 检查、ST 测试模板及 CBMC harness |
| `tools/` | 运行、编译、复测、报告和打包脚本 |
| `report/` | 最终报告的 Markdown、DOCX 和 PDF 版本 |
| `验收对照表.md` | 作业验收项与证据映射 |

`experiments/README.md` 解释正式证据、诊断记录和本地新运行的区别。
`experiments/*usage*.jsonl` 保存正式矩阵、pilot 和诊断调用的 usage 审计日志。

## 协作约定

- 正式证据文件是只读基线。新实验写到 `experiments/local_runs/`；默认被 Git 忽略，不会覆盖正式 `results.csv` 或 `st/runs/`。
- 需要调用模型 API 时先确认个人预算上限。密钥只通过当前进程环境变量 `DMXAPI_API_KEY` 提供，绝不提交到 Git、配置文件或日志。
- 每次报告结果时都标明实验分母、测试覆盖范围，以及离线编译和 PLC runtime 的区别。
- 建议从功能分支提交并发 PR；操作步骤见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。
