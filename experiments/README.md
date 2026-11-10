# 实验目录说明

本目录把正式矩阵、补充诊断、费用审计和新运行隔离开，避免把开发过程中的临时输出误认为正式结果。

| 路径 | 用途 | 是否正式矩阵 |
|---|---|---|
| `results.csv`、`results_summary.json` | 本次冻结的四条件 120 格正式结果和汇总 | 是，归档基线 |
| `diagnostics/deepseek/` | DeepSeek 空输出的受控诊断、smoke、恢复和对应 usage | 否，诊断证据 |
| `codesys_validation/` | 正式矩阵四个首次超时的编译重试 | 对应原始结果行 |
| `posthoc_repair/` | 修正编译适配器后重编译原始 FAIL 的逐格证据 | 否，单独的事后复测 |
| `functional_tests/`、`formal_verification/` | P02 的 STruC++ 测试和 CBMC 检查归档 | 加分验证，仅 P02 |
| `local_runs/` | 新的临时矩阵、源码、日志和复测结果 | 否，默认被 Git 忽略 |

`experiments/*usage*.jsonl` 保留正式矩阵、pilot 和诊断调用的费用审计。早期 pilot 的性能 CSV 和状态摘要已从交付仓库移除；pilot 的 usage JSONL 保留，因为项目总费用统计包含这些请求。CODESYS 项目适配器探索时的三个临时 probe 日志已移除；最终 30 格 post-hoc 编译日志仍保留。DeepSeek 诊断数据保留，因为报告的 API 根因分析依赖这些受控对照。

## 重要口径

- 正式矩阵共 120 格。首次编译为 77 PASS、39 FAIL、4 TIMEOUT；四个首次超时独立复编译后，最终矩阵状态为 **90 PASS、30 FAIL、0 个未结清 TIMEOUT**（3 个重试通过、1 个重试失败）。
- 修正适配器后的 30/30 PASS 属于单独复测；不能改写或合并成新版 adapter 的 120/120 单次矩阵结果。
- `PASS` 均需结合所在文件的编译器和验证范围解释。CODESYS 离线编译不是 runtime；112 个 PLC runtime 场景尚未执行。
- `tools/finalize_matrix.py` 读取归档 120 行矩阵、60 行 DeepSeek 恢复、4 个超时重试和所有归档 usage JSONL。它不读取 post-hoc 的 30 行复测表；两套结果仍分开。
- 费用汇总脚本默认把重算后的 CSV 和 summary 写到 `experiments/local_runs/finalized_matrix/`，不覆盖正式结果。只有明确传入 `--write-archive` 才会重写正式 `results.csv` 和 `results_summary.json`；运行前应检查归档输入及 Git diff。

完整运行说明见 [`../docs/REPRODUCING.md`](../docs/REPRODUCING.md)，实验设计见 [`protocol.md`](protocol.md)。
