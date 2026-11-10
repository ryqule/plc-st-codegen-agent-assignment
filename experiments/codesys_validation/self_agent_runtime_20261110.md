# 自研 ST 生成 Agent：CODESYS runtime 场景测试

## 测试结果

在本机 CODESYS Control Win V3 x64 3.5.22.40 上，对自研 Agent × GPT/DeepSeek 共 60 份候选输出执行 112 个场景向量（每题 3–5 个场景）。runtime 扫描周期为 50 ms；未连接物理 I/O。

| 指标 | 结果 |
|---|---:|
| 候选输出 | 60 |
| 全场景 runtime 通过 | 20 / 60 |
| runtime 有断言失败 | 3 / 60 |
| 测试工程编译失败，未执行 | 25 / 60 |
| 正式离线编译失败，跳过 runtime | 12 / 60 |
| 模型-场景计划 / 实际执行 / 未执行 | 224 / 88 / 136 |
| 不同场景 ID 已覆盖 | 56 / 112 |
| 已执行断言通过 / 失败 | 82 / 6 |
| 已执行场景通过率 | 82/88 = 93.2% |

**93.2% 只表示已实际执行的 88 个场景中 82 个断言通过。** 不能把它解释为全部 224 个计划场景通过；只有 88/224（39.3%）进入实际 runtime 扫描；至少被一个模型输出实际执行过的不同场景 ID 为 56/112（50.0%）。全 60 个输出里 20 个全场景通过，3 个存在断言失败，37 个被阻塞。

## 每题、每模型状态

| 题目 | DeepSeek | GPT |
|---|---|---|
| P01 | BLOCKED project compile (0/4) | PASS 4/4 |
| P02 | PASS 3/3 | PASS 3/3 |
| P03 | PASS 3/3 | PASS 3/3 |
| P04 | BLOCKED project compile (0/3) | PASS 3/3 |
| P05 | BLOCKED project compile (0/3) | PASS 3/3 |
| P06 | PASS 3/3 | PASS 3/3 |
| P07 | NOT RUN official compile fail (0/3) | NOT RUN official compile fail (0/3) |
| P08 | BLOCKED project compile (0/3) | BLOCKED project compile (0/3) |
| P09 | PASS 3/3 | PARTIAL 1/3 (2 fail) |
| P10 | BLOCKED project compile (0/3) | BLOCKED project compile (0/3) |
| P11 | NOT RUN official compile fail (0/3) | NOT RUN official compile fail (0/3) |
| P12 | BLOCKED project compile (0/3) | NOT RUN official compile fail (0/3) |
| P13 | BLOCKED project compile (0/3) | PASS 3/3 |
| P14 | BLOCKED project compile (0/3) | PARTIAL 1/3 (2 fail) |
| P15 | BLOCKED project compile (0/3) | NOT RUN official compile fail (0/3) |
| P16 | BLOCKED project compile (0/3) | PARTIAL 1/3 (2 fail) |
| P17 | BLOCKED project compile (0/3) | NOT RUN official compile fail (0/3) |
| P18 | BLOCKED project compile (0/3) | BLOCKED project compile (0/3) |
| P19 | BLOCKED project compile (0/3) | NOT RUN official compile fail (0/3) |
| P20 | BLOCKED project compile (0/3) | NOT RUN official compile fail (0/3) |
| S01 | BLOCKED project compile (0/6) | NOT RUN official compile fail (0/6) |
| S02 | BLOCKED project compile (0/5) | BLOCKED project compile (0/5) |
| S03 | PASS 5/5 | PASS 5/5 |
| S04 | BLOCKED project compile (0/5) | NOT RUN official compile fail (0/5) |
| S05 | BLOCKED project compile (0/5) | NOT RUN official compile fail (0/5) |
| S06 | PASS 5/5 | PASS 5/5 |
| S07 | PASS 5/5 | PASS 5/5 |
| S08 | BLOCKED project compile (0/5) | BLOCKED project compile (0/5) |
| S09 | PASS 5/5 | PASS 5/5 |
| S10 | BLOCKED project compile (0/5) | PASS 5/5 |

## 失败项分析

- **P09 GPT：** 输入窗口长度和样本后，`average` 仍为 0，`windowSizeReached` 为 FALSE；候选源码只做窗口合法性检查，没有实现样本累加、滑动平均和占用状态更新。
- **P14 GPT：** `192.168.1.10` 转换值不匹配；另外 `256.1.1.1` 未被拒绝。属于 IPv4 八位组范围/文本解析逻辑错误。
- **P16 GPT：** 对启动后输送方向及工位完成后的路由断言失败。候选源码在初始化变量后只把两个输送输出写为 FALSE，没有实现工位状态迁移逻辑。
- **P06 的首轮两项失败已复核为计时测试边界过紧：** 原向量恰好按 100 个 50 ms 周期卡在 5 秒边界。修正为先验证小于 5 秒并复位，再独立累计 105 个周期；GPT 与 DeepSeek 均 3/3 通过。
- **S10 GPT 的首轮两项失败由跨场景状态顺序造成：** “上电”场景此前排在累计有效 2 秒之后。把上电放在首位、先执行传感器有效性恢复后，再测加热器滞环，GPT 复测 5/5 通过。S10 DeepSeek 仍因测试工程无法编译而阻塞。

## 结果口径与范围

- `RUNTIME_PASS`：该输出的所有套件场景都在 Control Win 扫描中执行且断言通过。
- `PARTIAL`：runtime 已执行，但至少一条断言失败；仍保留每个断言的 expected/observed 值。
- `BLOCKED project compile`：原正式矩阵是离线 `COMPILE_PASS`，但候选 POU 合入 runtime 测试工程后编译失败，因此场景没有执行；不能计成 runtime FAIL，也不能计 PASS。共 25 项。
- `NOT RUN official compile fail`：正式离线矩阵为 `COMPILE_FAIL`，批处理按规则跳过。共 12 项。
- 正式 120 格离线编译矩阵与本 runtime 测试独立；`experiments/results.csv` 未被修改。离线编译 PASS 也不等于 runtime 通过。
- 每道题的输入与断言见 `tests/structured_text/runtime_suites/<题号>.json`；执行器见 `tools/run_codesys_runtime_suite.py`，全批执行见 `tools/run_self_runtime_batch.py`，复现命令见 `docs/REPRODUCING.md`。
- 可审计的机器汇总及每个已执行场景的 expected/observed 值见 [`self_agent_runtime_20261110_summary.json`](self_agent_runtime_20261110_summary.json)。完整原始工程和 `result.json` 位于本机 Git 忽略目录 `experiments/local_runs/codesys_runtime_suite/`，不包含在 Git 仓库。
