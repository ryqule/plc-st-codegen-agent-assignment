# 协作与提交

## 开始工作

1. 克隆仓库并阅读 [`README.md`](README.md) 和 [`docs/REPRODUCING.md`](docs/REPRODUCING.md)。
2. 从 `main` 创建功能分支；不要直接改写正式结果文件。
3. 代码改动后运行 `py -m unittest discover -s tests -v`，并在 PR 中说明实际运行了哪些检查。

## 实验输出

- 新实验的 CSV、JSON、ST 和日志写入 `experiments/local_runs/`；该目录已加入 `.gitignore`。
- 模型调用会产生费用。PR 中记录模型、任务范围、预算上限、实际用量和结果文件；未授权时不要调用在线模型。
- 不提交 `.env`、API key、个人本地配置、`node_modules/`、`__pycache__/` 或 QA/排版检查用 PDF。
- 若要更新正式矩阵，需先在 PR 说明运行配置、输出范围、费用、源码哈希和复核方法，并保留原始 run 证据；不要用一次新运行覆盖现有结果。

## 报告结果的口径

- 将原始 120 格矩阵与 post-hoc CODESYS 复编译分开统计。
- 区分静态检查、离线编译、ST 引擎测试、CBMC 有界检查和 CODESYS runtime。
- 说明每个指标的分母与覆盖任务；`NOT_RUN`、`UNAVAILABLE`、TIMEOUT 不计 PASS。
- 描述模型行为时只使用已记录的输出和诊断证据，不声称保存过未被记录的 prompt 或响应正文。
