"""Run a task's ST-level test template against one generated POU with STruC++."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


POU_RE = re.compile(r"^\s*(PROGRAM|FUNCTION_BLOCK|FUNCTION)\s+([A-Za-z_][A-Za-z0-9_]*)",
                    re.IGNORECASE | re.MULTILINE)
RESULT_RE = re.compile(r"(\d+) tests?,\s*(\d+) passed,\s*(\d+) failed", re.IGNORECASE)
P02_SHR_BIT_TEST_RE = re.compile(
    r"IF\s+\(\((\w+)\s+SHR\s+(\w+)\)\s+AND\s+16#0*1\)\s*<>\s*16#0+\s+THEN",
    re.IGNORECASE,
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalize_strucpp_source(source: str) -> tuple[str, list[dict]]:
    """Rewrite a known-equivalent IEC bit-test idiom rejected by STruC++ 0.7."""
    source, replacements = P02_SHR_BIT_TEST_RE.subn(
        r"IF (\1 AND SHL(DWORD#1, \2)) <> DWORD#0 THEN", source
    )
    normalizations = []
    if replacements:
        normalizations.append({
            "rule": "SHR-and-1 bit test rewritten as AND with a one-bit SHL mask",
            "replacements": replacements,
        })
    return source, normalizations


def run(source_path: Path, template_path: Path, executable: Path, timeout: int) -> dict:
    version = subprocess.run([str(executable), "--version"], capture_output=True, text=True,
                             encoding="utf-8", errors="replace", timeout=10, check=False)
    source = source_path.read_text(encoding="utf-8-sig")
    execution_source, normalizations = normalize_strucpp_source(source)
    match = POU_RE.search(source)
    if not match:
        raise ValueError("Generated ST has no PROGRAM, FUNCTION_BLOCK, or FUNCTION declaration")
    template = template_path.read_text(encoding="utf-8-sig")
    if "__POU_NAME__" not in template:
        raise ValueError("Test template must contain __POU_NAME__")
    test_source = template.replace("__POU_NAME__", match.group(2))

    with tempfile.TemporaryDirectory(prefix="plc_st_test_") as temp:
        temp_dir = Path(temp)
        test_pou = temp_dir / "program.st"
        test_file = temp_dir / "tests.st"
        test_pou.write_text(execution_source, encoding="utf-8")
        test_file.write_text(test_source, encoding="utf-8")
        proc = subprocess.run(
            [str(executable), str(test_pou), "--test", str(test_file)],
            cwd=temp_dir, capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=timeout, check=False,
        )

    output = (proc.stdout or "") + (proc.stderr or "")
    counts = RESULT_RE.search(output)
    return {
        "status": "PASS" if proc.returncode == 0 and counts and int(counts.group(3)) == 0 else "FAIL",
        "task_id": template_path.stem.split("_", 1)[0],
        "source": str(source_path),
        "source_sha256": sha256(source.encode("utf-8")),
        "execution_source_sha256": sha256(execution_source.encode("utf-8")),
        "source_normalizations": normalizations,
        "test_template": str(template_path),
        "test_template_sha256": sha256(template.encode("utf-8")),
        "pou_kind": match.group(1).upper(),
        "pou_name": match.group(2),
        "tool": str(executable),
        "tool_version": (version.stdout or version.stderr).strip(),
        "exit_code": proc.returncode,
        "test_count": int(counts.group(1)) if counts else None,
        "passed": int(counts.group(2)) if counts else None,
        "failed": int(counts.group(3)) if counts else None,
        "output": output.strip(),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--test-template", type=Path, required=True)
    parser.add_argument("--strucpp", type=Path, default=None)
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--result", type=Path, default=None)
    args = parser.parse_args()
    configured = str(args.strucpp) if args.strucpp else os.environ.get("STRUCPP_EXE")
    executable = Path(configured) if configured else Path(shutil.which("strucpp") or "")
    if not executable.is_file():
        raise SystemExit("Set STRUCPP_EXE or pass --strucpp with the STruC++ executable path")
    result = run(args.source.resolve(), args.test_template.resolve(), executable.resolve(), args.timeout)
    encoded = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.result:
        args.result.parent.mkdir(parents=True, exist_ok=True)
        args.result.write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
