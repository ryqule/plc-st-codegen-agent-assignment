# PLC Structured Text Code Generation Assignment

This repository contains the assignment code, dataset, four-condition model
experiment, raw results, compiler diagnostics, post-hoc CODESYS recheck, and
submission report.

## At a glance

- Dataset: 20 supplied questions and 10 self-developed PLC questions, with
  interfaces, assumptions, scan-level LTL, and 112 test scenarios.
- Experiment: 120 cells across Pi and the custom harness, each paired with
  GPT-6.1 Sol and DeepSeek V4.1 Flash.
- Original matrix: 90 PASS, 30 FAIL, and 0 unresolved TIMEOUT after retry.
- Post-hoc CODESYS recheck: all 30 original FAIL sources compile PASS with the
  corrected project adapter; source hashes are unchanged. The original matrix
  is preserved, and the 120 cells were not uniformly rebuilt with one adapter.
- Additional P02 checks: 20/20 STruC++ tests and 918 CBMC properties passed.
- Scope boundary: CODESYS runtime tests were not run (0/112); the assignment
  report distinguishes offline compile evidence from runtime behavior.

## Start here

- [Submission guide](README_提交说明.md)
- [Acceptance checklist](验收对照表.md)
- [Full experiment report](report/实验报告.pdf) or [editable report](report/实验报告.docx)
- [Dataset and test scenarios](dataset/tasks.json)
- [Original experiment matrix](experiments/results.csv)
- [Post-hoc recheck evidence](experiments/posthoc_repair/README.md)
- [CODESYS DUT support types](st/support_types/README.md)

## Repository map

- `src/`: custom PLC agent and model adapters.
- `dataset/`: questions, interfaces, assumptions, LTL, and test scenarios.
- `st/runs/`: original generated ST sources and compile diagnostics.
- `st/support_types/`: task-defined DUT types for P07 and P17.
- `experiments/`: experiment protocol, results, usage records, tests, formal
  checks, and post-hoc recompile evidence.
- `tools/`: experiment, compile, test, and packaging scripts.
- `report/`: Markdown, DOCX, and PDF reports.

## Reproduce key checks

Run from the repository root in PowerShell:

```powershell
py -m unittest discover -s tests -v
py tools/run_st_tests.py `
  --source st/runs/pi/deepseek/P02.st `
  --test-template tests/structured_text/P02_test.st `
  --strucpp C:\path\to\strucpp.exe `
  --result experiments/functional_tests/P02_pi_deepseek.json
```

The original compile procedure is documented in `README_提交说明.md` and
`experiments/protocol.md`. The corrected adapter recheck is available through
`tools/posthoc_recheck_failures.py`. Model reruns require `DMXAPI_API_KEY` in
the process environment; never commit the key or local configuration files.
