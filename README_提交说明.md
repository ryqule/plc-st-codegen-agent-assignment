# PLC 结构化文本代码生成大作业提交包

## 交付内容

- `report/实验报告.docx`、`report/实验报告.pdf`、`report/实验报告.md`：完整实验报告。
- `验收对照表.md`：按原始 Basic Tasks、Advanced Tasks 和报告要求列出的证据、完成状态与范围限制。
- `dataset/`：20 道给定题和 10 道原创题；包含接口、假设、LTL、测试场景、来源说明和原始题库材料。
- `src/`、`tools/`：自研 Agent harness、模型适配器、CODESYS 编译器适配器、实验汇总、自动化测试及有界形式验证脚本。
- `experiments/results.csv`、`experiments/results_summary.json`：四条件 120 格正式矩阵及可复算汇总；usage 日志、编译诊断、DeepSeek 修复前后诊断和超时重试证据均随包提供。
- `st/runs/`：四条件生成的 Structured Text 源码。
- `st/support_types/`：P07、P17 使用的题目定义 DUT 类型，可直接导入 CODESYS。
- `experiments/posthoc_repair/`：修正编译适配器后对原始 30 个 FAIL 源码的复测 CSV、逐条编译日志和汇总；原源码哈希保持不变。
- `tests/structured_text/`、`experiments/functional_tests/`：P02 自动化测试模板和四份运行结果。
- `experiments/formal_verification/`：P02 四种输出对应的 CBMC harness、翻译证据、检查日志和结果。

## 最终实验结果

正式矩阵覆盖 30 道题 × 2 个模型 × 2 种 Agent，共 120/120 格。最初 DeepSeek 有 60 格空输出；受控关闭 thinking mode 后恢复全量运行，当前 60/60 格均有非空 ST。该诊断与 DeepSeek Thinking Mode API 文档描述的请求参数和 reasoning/content 分离相符；初始调用均到达 768-token completion 上限，但代理未保存原始响应正文，因此根因属于受控对照支持的诊断结论。

原始矩阵的首次编译为 77 PASS、39 FAIL、4 TIMEOUT；四份超时在模型请求结束后单独重试，3 份通过，1 份失败，原始矩阵最终记录为 **90 PASS、30 FAIL、0 TIMEOUT**。后续审查发现旧 CODESYS 适配器没有剥离 ST 源码外层 Markdown 围栏、没有加入 Standard 库及 P07/P17 的题目 DUT，且将带 `VAR_IN_OUT` 的程序放进了未绑定实参的任务调用。用修正后的适配器对原始 30 个失败单元复编译后，**30/30 PASS，0 FAIL**；逐条源码哈希均未变化。因此，120 份源码都已有至少一次 CODESYS 离线编译 PASS 证据（原始 90 PASS + 复测 30 PASS）。该组合口径不是新版适配器统一重跑全部 120 格，原始 90/120 实验指标仍完整保留于 `experiments/results.csv` 与原始汇总文件。CODESYS 结果代表离线构建，不等于 PLC runtime 功能测试。

加分项已经完成：STruC++ 0.7.0 对 P02 的 Pi/self × GPT/DeepSeek 四份输出分别运行 5 项测试，共 **20/20 通过**；CBMC 5.95.1 对四份 P02 翻译代码检查 **918 项性质、0 项失败**。这两项都只覆盖 P02。Windows 上的 CODESYS Control Win 服务当前停止，因此题库设计的 112 个 PLC runtime 场景执行数为 0；PLCVerif 未安装，其他 29 题没有做形式验证。

DMXAPI 项目全部 usage 实扣 **¥6.099742 / ¥18**，正式矩阵部分为 ¥5.880938，授权余额为 ¥11.900258。usage 日志共 234 条记录（233 次 HTTP 200、1 次预算拦截）。密钥不在交付包中，运行时通过环境变量 `DMXAPI_API_KEY` 提供。

## 复现与检查

在 `submission` 目录打开 PowerShell：

```powershell
py -m unittest discover -s tests -v
py tools/run_st_tests.py `
  --source st/runs/pi/deepseek/P02.st `
  --test-template tests/structured_text/P02_test.st `
  --strucpp C:\path\to\strucpp.exe `
  --result experiments/functional_tests/P02_pi_deepseek.json
```

其余三组输入源码路径见 `experiments/functional_tests/` 中 JSON 的 `source` 字段。CBMC 复现说明与命令见 `tests/structured_text/README.md`；CBMC 在本次环境的 WSL Ubuntu 中运行。测试和形式检查的精确输入哈希、转换方式及工具输出均保存在结果目录。

CODESYS 3.5.22.40 原始实验构建通过 `experiments/config.example.json` 调用 `tools/codesys_compile.py`；失败样本的后处理复测调用 `tools/posthoc_recheck_failures.py`。本机目标设备为 Control Win V3 x64，设备 ID `0000 0004`。P07/P17 编译前需按 `st/support_types/README.md` 导入 DUT。runtime 服务停止，不能据此包声称已经执行 PLC 扫描仿真。

如需重新运行模型矩阵，请设置 `DMXAPI_API_KEY` 环境变量并先查看 `experiments/protocol.md` 与 `experiments/config.example.json`。费用按供应商 usage 日志核算；不要把密钥写入配置、命令行或提交文件。

## 结果边界

90/120 是原始实验适配器下的矩阵指标；30/30 是原始失败源码在修正项目依赖和代码抽取后的离线复测。两组合并表示每份源文件至少有一次编译 PASS 证据，但并非所有 120 格都由同一版适配器重跑。20/20 是 P02 上独立 ST 引擎的测试结果；918 项是 P02 的 CBMC 有界检查结果。编译、自动测试和有界检查都不等同于完整 30 题在 PLC runtime 上逐扫描功能正确，也不代表全部 LTL 已经证明。详细方法、逐条件指标、复测证据和复现边界见 `report/实验报告.pdf` 与 `experiments/posthoc_repair/README.md`。
