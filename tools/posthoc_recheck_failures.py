"""Rebuild the original failed matrix cells with the corrected CODESYS adapter.

This is a post-hoc diagnostic pass. It leaves results.csv and all original ST
sources untouched and records each rebuild under experiments/posthoc_repair/.
"""
from __future__ import annotations

import csv
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from codesys_compile_posthoc import compile_one  # noqa: E402


OUT = ROOT / "experiments" / "posthoc_repair"
LOG_DIR = OUT / "codesys_logs"
CSV_PATH = OUT / "recheck.csv"
SUMMARY_PATH = OUT / "summary.json"
FIELDS = [
    "run_id", "task_id", "framework", "model_id", "original_status",
    "posthoc_status", "source_file", "source_sha256_before", "source_sha256_after",
    "posthoc_duts", "elapsed_ms", "error_count", "diagnostics", "compile_log",
]


def write_csv(rows: list[dict]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    temporary = CSV_PATH.with_suffix(".csv.tmp")
    with temporary.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(CSV_PATH)


def main() -> int:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with (ROOT / "experiments" / "results.csv").open("r", newline="", encoding="utf-8-sig") as stream:
        original_rows = list(csv.DictReader(stream))
    failed_rows = [row for row in original_rows if row["final_compile"] == "FAIL"]
    output_rows: list[dict] = []
    status_counts: dict[str, int] = {}

    for index, row in enumerate(failed_rows, start=1):
        source = ROOT / row["output_file"]
        if not source.is_file():
            result = {"status": "UNAVAILABLE", "error": "Original source file is missing"}
            source_hash = ""
        else:
            source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
            log_path = LOG_DIR / (row["run_id"] + ".json")
            result = compile_one(source, row["task_id"], log_path, timeout=150)

        status = result.get("status", "UNAVAILABLE")
        status_counts[status] = status_counts.get(status, 0) + 1
        diagnostics = " | ".join(
            f"{error.get('number', '')}: {error.get('text', '')}"
            for error in result.get("errors", [])
        )
        output_rows.append({
            "run_id": row["run_id"],
            "task_id": row["task_id"],
            "framework": row["framework"],
            "model_id": row["model_id"],
            "original_status": row["final_compile"],
            "posthoc_status": status,
            "source_file": row["output_file"],
            "source_sha256_before": source_hash,
            "source_sha256_after": hashlib.sha256(source.read_bytes()).hexdigest() if source.is_file() else "",
            "posthoc_duts": ";".join(result.get("posthoc_duts", [])),
            "elapsed_ms": result.get("elapsed_ms", ""),
            "error_count": len(result.get("errors", [])),
            "diagnostics": diagnostics or result.get("error", ""),
            "compile_log": str((LOG_DIR / (row["run_id"] + ".json")).relative_to(ROOT)).replace("\\", "/"),
        })
        write_csv(output_rows)
        print(json.dumps({
            "progress": f"{index}/{len(failed_rows)}",
            "run_id": row["run_id"],
            "status": status,
            "elapsed_ms": result.get("elapsed_ms"),
            "diagnostic_count": len(result.get("errors", [])),
        }, ensure_ascii=False), flush=True)

    unchanged = all(row["source_sha256_before"] == row["source_sha256_after"] for row in output_rows)
    summary = {
        "purpose": "Post-hoc recheck of original FAIL cells with corrected project adapter",
        "original_matrix_file": "experiments/results.csv",
        "original_failure_cells": len(failed_rows),
        "rechecked_cells": len(output_rows),
        "posthoc_status_counts": status_counts,
        "sources_unchanged": unchanged,
        "adapter_changes": [
            "Adds installed CODESYS Standard 3.5.22.0 (System) library for IEC standard symbols.",
            "Imports task-provided ST_Pump and ST_Recipe as DUTs when required.",
            "Builds the POU without binding a VAR_IN_OUT program to an empty task call.",
            "Strips Markdown code-fence wrappers from the compiler input view only.",
        ],
        "limitations": [
            "This pass does not change the original 120-cell experiment results or source files.",
            "PASS means offline CODESYS project compilation only; it is not runtime or functional verification.",
        ],
    }
    SUMMARY_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False), flush=True)
    return 0 if unchanged and len(output_rows) == len(failed_rows) else 1


if __name__ == "__main__":
    raise SystemExit(main())
