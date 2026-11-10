# CODESYS 矩阵超时重试记录

本目录只保留正式 120 格矩阵里四个首次编译 TIMEOUT 的重试记录。源码位于 `st/runs/`，每份 JSON 保存本次重试状态与编译诊断。重试更新原始矩阵中的最终状态，但首次编译超时仍保留在 `experiments/results.csv` 的相应字段中。

环境：CODESYS V3.5 SP22 Patch 4，compiler/device description 3.5.22.40，目标 Control Win V3 x64（device ID `0000 0004`）。

| 文件 | 矩阵单元 | 重试结果 |
|---|---|---|
| `deepseek_timeout_retries/115-P15-deepseek-pi.json` | Pi / P15 / DeepSeek | PASS |
| `deepseek_timeout_retries/116-P15-deepseek-self.json` | 自研 harness / P15 / DeepSeek | PASS |
| `deepseek_timeout_retries/119-P11-deepseek-pi.json` | Pi / P11 / DeepSeek | PASS |
| `deepseek_timeout_retries/120-P11-deepseek-self.json` | 自研 harness / P11 / DeepSeek | FAIL |

以上全部是离线项目构建结果，不代表 PLC 下载、扫描周期执行或 runtime 功能正确。runtime 复现限制见 [`../../docs/REPRODUCING.md`](../../docs/REPRODUCING.md)。

## P02 runtime 冒烟测试

另有一次真实 Control Win runtime 验证：[`P02_control_win_runtime_smoke_20261110.json`](P02_control_win_runtime_smoke_20261110.json)。CODESYS Control Win V3 x64 3.5.22.40 在线构建 0 错误/0 警告，随后以 50 ms 周期执行 5 个 P02 测试用例，5/5 PASS。该结果只覆盖 P02 冒烟向量，不修改也不合并到正式 120 格离线编译矩阵；112 个数据集场景尚未全部执行 runtime 验证。
