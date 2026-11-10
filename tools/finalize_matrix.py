"""Merge DeepSeek recovery and refresh the auditable experiment summary."""
from __future__ import annotations

import csv
import glob
import json
import math
import statistics
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPERIMENTS = ROOT / "experiments"
AUTHORIZED_TOTAL_CNY = 18.0


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def read_usage(path: Path) -> list[dict]:
    rows = []
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            if line.strip():
                rows.append(json.loads(line))
    return rows


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def rate(passed: int, total: int) -> float | None:
    return round(passed / total, 10) if total else None


def wilson95(passed: int, total: int) -> list[float] | None:
    if total == 0:
        return None
    z = 1.959963984540054
    p = passed / total
    d = 1 + z * z / total
    center = (p + z * z / (2 * total)) / d
    half = z * math.sqrt((p * (1 - p) / total) + z * z / (4 * total * total)) / d
    return [round(center - half, 10), round(center + half, 10)]


def main() -> None:
    original = read_csv(EXPERIMENTS / "results.csv")
    recovery = read_csv(EXPERIMENTS / "deepseek_recovery.csv")
    if len(original) != 120:
        raise SystemExit(f"Expected 120 original matrix rows, found {len(original)}")
    if len(recovery) != 60:
        raise SystemExit(f"Wait for all 60 DeepSeek recovery rows; found {len(recovery)}")
    recovered_by_id = {row["run_id"]: row for row in recovery}
    if len(recovered_by_id) != 60:
        raise SystemExit("Recovery run IDs are not unique")

    merged = []
    for row in original:
        replacement = recovered_by_id.get(row["run_id"])
        if replacement:
            merged.append(replacement.copy())
        else:
            merged.append(row.copy())
    if len({row["run_id"] for row in merged}) != 120:
        raise SystemExit("Merged matrix run IDs are not unique")
    if sum(row["model_id"].startswith("deepseek") for row in merged) != 60:
        raise SystemExit("Merged matrix does not contain 60 DeepSeek cells")
    if any(row["status"] == "EMPTY_RESPONSE" for row in merged):
        raise SystemExit("DeepSeek still has empty responses; do not finalize yet")

    retry_dir = EXPERIMENTS / "codesys_validation" / "deepseek_timeout_retries"
    retry_results = {path.stem: (path, read_json(path)) for path in sorted(retry_dir.glob("*.json"))}
    retry_summary = {}
    for row in merged:
        retry = retry_results.get(row["run_id"])
        if not retry:
            continue
        path, result = retry
        retry_status = result.get("status")
        if retry_status not in ("PASS", "FAIL", "TIMEOUT"):
            continue
        row["final_compile"] = retry_status
        row["status"] = {"PASS": "COMPILE_PASS", "FAIL": "COMPILE_FAIL", "TIMEOUT": "TIMEOUT"}[retry_status]
        detail_path = path.relative_to(ROOT).as_posix()
        row["notes"] = (
            f"Initial CODESYS compile timed out; offline retry {retry_status} "
            f"({int(result.get('elapsed_ms') or 0)} ms); evidence: {detail_path}. "
            "CODESYS runtime scenarios and PLCVerif remain unrun."
        )
        retry_summary[row["run_id"]] = {
            "status": retry_status,
            "elapsed_ms": result.get("elapsed_ms"),
            "evidence": detail_path,
            "error_count": len(result.get("errors") or []),
        }

    functional_results = sorted((EXPERIMENTS / "functional_tests").glob("P02_*.json"))
    formal_results = sorted((EXPERIMENTS / "formal_verification").glob("P02_*/result.json"))
    if len(functional_results) != 4 or len(formal_results) != 4:
        raise SystemExit("Expected four P02 functional-test and four CBMC result JSONs")
    functional = [read_json(path) for path in functional_results]
    formal = [read_json(path) for path in formal_results]

    test_by_source = {Path(result["source"]).as_posix().lower(): result for result in functional}
    formal_by_source = {Path(result["source"]).as_posix().lower(): result for result in formal}
    for row in merged:
        normalized_output_path = (ROOT / row["output_file"].replace("\\", "/")).resolve().as_posix().lower()
        if row["task_id"] == "P02":
            test = next((result for key, result in test_by_source.items()
                         if key == Path(normalized_output_path).as_posix().lower()), None)
            check = next((result for key, result in formal_by_source.items()
                          if key == Path(normalized_output_path).as_posix().lower()), None)
            if test and check:
                row["test_passed"] = str(test["passed"])
                row["test_total"] = str(test["test_count"])
                row["verifier_status"] = "PASS_CBMC_P02" if check["status"] == "PASS" else "FAIL_CBMC_P02"
                row["notes"] = row["notes"].replace(
                    "Functional tests and PLCVerif remain unconfigured.",
                    "P02 supplementary STruC++ tests and CBMC checks are recorded in experiments/.")
        row["notes"] = row["notes"].replace(
            "Functional tests and PLCVerif remain unconfigured.",
            "CODESYS runtime scenarios and PLCVerif remain unrun; see the P02 bonus artifacts.")

    results_path = EXPERIMENTS / "results.csv"
    with results_path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(merged[0].keys()))
        writer.writeheader()
        writer.writerows(merged)

    status_counts = Counter(row["status"] for row in merged)
    repair_counts = [int(row.get("repairs") or 0) for row in merged]
    compiler_submitted_statuses = ("PASS", "FAIL", "TIMEOUT")
    first_submitted = [row for row in merged if row.get("first_compile") in compiler_submitted_statuses]
    final_submitted = [row for row in merged if row.get("final_compile") in compiler_submitted_statuses]
    condition_summary = {}
    for row in merged:
        condition = f"{row['framework']} + {row['model_id']}"
        summary = condition_summary.setdefault(condition, {
            "attempted": 0, "first_compile_submitted": 0, "first_compile_passed": 0,
            "final_compile_submitted": 0, "final_compile_passed": 0,
            "empty_response": 0, "compile_fail": 0, "compile_pass": 0,
        })
        summary["attempted"] += 1
        summary["empty_response"] += row["status"] == "EMPTY_RESPONSE"
        summary["compile_fail"] += row["status"] == "COMPILE_FAIL"
        summary["compile_pass"] += row["status"] == "COMPILE_PASS"
        summary["first_compile_submitted"] += row.get("first_compile") in compiler_submitted_statuses
        summary["first_compile_passed"] += row.get("first_compile") == "PASS"
        summary["final_compile_submitted"] += row.get("final_compile") in compiler_submitted_statuses
        summary["final_compile_passed"] += row.get("final_compile") == "PASS"
    for summary in condition_summary.values():
        summary["first_compile_rate_over_all_attempts"] = rate(summary["first_compile_passed"], summary["attempted"])
        summary["final_compile_rate_over_all_attempts"] = rate(summary["final_compile_passed"], summary["attempted"])
        summary["first_compile_rate_on_submitted"] = rate(summary["first_compile_passed"], summary["first_compile_submitted"])
        summary["final_compile_rate_on_submitted"] = rate(summary["final_compile_passed"], summary["final_compile_submitted"])
        summary["first_compile_wilson95_over_all_attempts"] = wilson95(summary["first_compile_passed"], summary["attempted"])
        summary["final_compile_wilson95_over_all_attempts"] = wilson95(summary["final_compile_passed"], summary["attempted"])

    dataset = read_json(ROOT / "dataset" / "tasks.json")
    usage_files = sorted(Path(p) for p in glob.glob(str(EXPERIMENTS / "*usage*.jsonl")))
    usage_records = [(path, record) for path in usage_files for record in read_usage(path)]
    model_totals = defaultdict(float)
    model_tokens = defaultdict(lambda: {"prompt_tokens": 0, "completion_tokens": 0})
    model_latencies = defaultdict(list)
    matrix_cost = 0.0
    model_matrix_cost = defaultdict(float)
    model_cost_debug = defaultdict(float)
    for path, record in usage_records:
        cost = float(record.get("cost_cny") or 0.0)
        model = record.get("model", "unknown")
        model_totals[model] += cost
        model_tokens[model]["prompt_tokens"] += int(record.get("prompt_tokens") or 0)
        model_tokens[model]["completion_tokens"] += int(record.get("completion_tokens") or 0)
        if record.get("elapsed_ms") is not None:
            model_latencies[model].append(int(record["elapsed_ms"]))
        if path.name.startswith("results_usage_") or path.name.startswith("deepseek_recovery_usage_"):
            matrix_cost += cost
            model_matrix_cost[model] += cost
        else:
            model_cost_debug[model] += cost
    total_cost = sum(float(record.get("cost_cny") or 0.0) for _, record in usage_records)
    p02_tests = {"outputs": len(functional), "passed": sum(int(x.get("passed") or 0) for x in functional),
                 "total": sum(int(x.get("test_count") or 0) for x in functional),
                 "failed": sum(int(x.get("failed") or 0) for x in functional)}
    p02_formal = {"outputs": len(formal),
                  "properties_checked": sum(int(x.get("verified_properties") or 0) for x in formal),
                  "failed_properties": sum(int(x.get("failed_properties") or 0) for x in formal),
                  "statuses": dict(Counter(x["status"] for x in formal)),
                  "engine": "CBMC 5.95.1 over STruC++ 0.7.0 translations; P02 only"}
    runtime_test_scenarios = 0
    summary = {
        "run_rows": len(merged),
        "dataset_total": dataset["task_count"],
        "planned_cells": 120,
        "results_csv": "experiments/results.csv",
        "run_status": "COMPLETE",
        "executed_cells": len(merged),
        "budget_stopped_cells": 0,
        "fully_covered_tasks": len({row["task_id"] for row in merged}),
        "partially_covered_tasks": 0,
        "unstarted_tasks": 0,
        "executed_cells_by_model": dict(Counter(row["model_id"] for row in merged)),
        "executed_cells_by_framework": dict(Counter(row["framework"] for row in merged)),
        "cell_status_counts": dict(status_counts),
        "condition_summary": condition_summary,
        "codesys_timeout_retries": retry_summary,
        "first_compile": {"submitted": len(first_submitted),
                           "passed": sum(row.get("first_compile") == "PASS" for row in merged),
                           "failed": sum(row.get("first_compile") == "FAIL" for row in merged),
                           "timed_out": sum(row.get("first_compile") == "TIMEOUT" for row in merged)},
        "final_compile": {"submitted": len(final_submitted),
                          "passed": sum(row.get("final_compile") == "PASS" for row in merged),
                          "failed": sum(row.get("final_compile") == "FAIL" for row in merged),
                          "timed_out": sum(row.get("final_compile") == "TIMEOUT" for row in merged)},
        "repaired_cells": sum(count > 0 for count in repair_counts),
        "successful_repair_requests": sum(repair_counts),
        "first_compile_pass_over_all_attempts": {
            "passed": sum(row.get("first_compile") == "PASS" for row in merged),
            "attempted": len(merged),
            "rate": rate(sum(row.get("first_compile") == "PASS" for row in merged), len(merged)),
            "wilson95": wilson95(sum(row.get("first_compile") == "PASS" for row in merged), len(merged))},
        "final_compile_pass_over_all_attempts": {
            "passed": sum(row.get("final_compile") == "PASS" for row in merged),
            "attempted": len(merged),
            "rate": rate(sum(row.get("final_compile") == "PASS" for row in merged), len(merged)),
            "wilson95": wilson95(sum(row.get("final_compile") == "PASS" for row in merged), len(merged))},
        "test_cases_defined": sum(len(task.get("test_cases", [])) for task in dataset["tasks"]),
        "codesys_runtime_test_scenarios_executed": runtime_test_scenarios,
        "independent_st_test_engine": "STruC++ 0.7.0",
        "independent_st_tests_p02": p02_tests,
        "plcverif_tasks": 0,
        "cbmc_formal_p02": p02_formal,
        "matrix_usage_cost_cny": round(matrix_cost, 9),
        "project_usage_cost_cny": round(total_cost, 9),
        "project_authorized_budget_cny": AUTHORIZED_TOTAL_CNY,
        "remaining_authorized_budget_cny": round(AUTHORIZED_TOTAL_CNY - total_cost, 9),
        "api_usage_records_all_logs": len(usage_records),
        "model_cost_cny_all_project_usage": {k: round(v, 9) for k, v in model_totals.items()},
        "model_matrix_cost_cny": {k: round(v, 9) for k, v in model_matrix_cost.items()},
        "model_debug_and_pilot_cost_cny": {k: round(v, 9) for k, v in model_cost_debug.items()},
        "model_tokens_all_project_usage": dict(model_tokens),
        "model_median_latency_ms_all_project_usage": {
            model: round(statistics.median(latencies), 3)
            for model, latencies in model_latencies.items() if latencies},
        "input_tokens_all_project_usage": sum(int(r.get("prompt_tokens") or 0) for _, r in usage_records),
        "completion_tokens_all_project_usage": sum(int(r.get("completion_tokens") or 0) for _, r in usage_records),
        "http_status_counts_all_usage_logs": dict(Counter(str(r.get("http_status", "unknown")) for _, r in usage_records)),
        "usage_logs": [path.relative_to(ROOT).as_posix() for path in usage_files],
        "runtime_service_status": "STOPPED",
        "formal_verification_scope_note": "Custom CBMC proof covers P02 outputs only, over the STruC++ translation; PLCVerif and the other 29 tasks remain unverified.",
    }
    (EXPERIMENTS / "results_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "matrix_rows": len(merged), "statuses": dict(status_counts),
        "project_usage_cost_cny": round(total_cost, 9),
        "remaining_authorized_budget_cny": round(AUTHORIZED_TOTAL_CNY - total_cost, 9),
        "p02_independent_tests": p02_tests, "p02_cbmc": p02_formal,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
