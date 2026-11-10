# CODESYS 编译与 runtime 验证记录

本目录包含正式 120 格矩阵的离线编译重试，以及两项独立 Control Win runtime 验证。离线矩阵数据仍以 `experiments/results.csv` 为准；runtime 结果不修改或合并进正式矩阵。

环境：CODESYS V3.5 SP22 Patch 4，compiler/device description 3.5.22.40，目标 Control Win V3 x64（device ID `0000 0004`）。

| 文件 | 矩阵单元 | 重试结果 |
|---|---|---|
| `deepseek_timeout_retries/115-P15-deepseek-pi.json` | Pi / P15 / DeepSeek | PASS |
| `deepseek_timeout_retries/116-P15-deepseek-self.json` | 自研 harness / P15 / DeepSeek | PASS |
| `deepseek_timeout_retries/119-P11-deepseek-pi.json` | Pi / P11 / DeepSeek | PASS |
| `deepseek_timeout_retries/120-P11-deepseek-self.json` | 自研 harness / P11 / DeepSeek | FAIL |

以上全部是离线项目构建结果，不代表 PLC 下载、扫描周期执行或 runtime 功能正确。runtime 复现限制见 [`../../docs/REPRODUCING.md`](../../docs/REPRODUCING.md)。

## P02 runtime 冒烟测试

另有一次真实 Control Win runtime 验证：[`P02_control_win_runtime_smoke_20261110.json`](P02_control_win_runtime_smoke_20261110.json)。CODESYS Control Win V3 x64 3.5.22.40 在线构建 0 错误/0 警告，随后以 50 ms 周期执行 5 个 P02 测试用例，5/5 PASS。该结果只覆盖 P02 冒烟向量。

## 自研 Agent 两模型 runtime 场景测试

自研 Agent × GPT/DeepSeek 的 60 份候选输出共计划执行 224 个模型-场景组合。实际执行 88 个断言场景，82 PASS、6 FAIL，覆盖 56/112 个不同场景 ID；136 个模型-场景组合因正式离线编译失败或 runtime 测试工程编译失败而未执行。20 个候选输出全场景通过，3 个候选输出至少有一个 runtime 断言失败，其余 37 个没有 runtime 结果。逐题结果、阻塞原因和 expected/observed 值见 [`self_agent_runtime_20261110.md`](self_agent_runtime_20261110.md) 与 [`self_agent_runtime_20261110_summary.json`](self_agent_runtime_20261110_summary.json)。复现方式见 [`../../docs/REPRODUCING.md`](../../docs/REPRODUCING.md)。
