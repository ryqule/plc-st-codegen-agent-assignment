# DeepSeek 空输出诊断记录

本目录保存空输出问题的有限对照和恢复证据。它们用于解释为何完整矩阵需要关闭 DeepSeek thinking；不计入原始 120 格矩阵，也不应替换 `experiments/results.csv`。

| 文件 | 说明 |
|---|---|
| `diagnostic.csv`、`diagnostic_summary.json` | 初始参数对照，保留结构化响应元数据而不保存模型正文 |
| `fixed_smoke.csv`、`fixed_smoke_summary.json` | 关闭 thinking 后的小样本 smoke 运行 |
| `recovery.csv`、`recovery_summary.json` | 完整矩阵中 DeepSeek 60 格的恢复输出副本 |
| `probe_usage.jsonl` | 受控探测请求的费用与 token 记录；未保存请求正文或密钥 |
正式矩阵中的 60 个 DeepSeek 单元见 `../../results.csv`；复现运行步骤和费用边界见 [`../../../docs/REPRODUCING.md`](../../../docs/REPRODUCING.md)。重新执行诊断会调用在线模型并产生费用，应先取得运行者的预算授权；新输出默认写入 `experiments/local_runs/`。

对应 usage JSONL 集中留在 `experiments/` 根目录，以保持报告和审计路径稳定：`../../deepseek_diagnostic_usage_20261109_154820.jsonl`、`../../deepseek_fixed_smoke_usage_20261109_155144.jsonl`、`../../deepseek_recovery_usage_20261109_155416.jsonl` 和 `../../deepseek_probe_usage.jsonl`。
