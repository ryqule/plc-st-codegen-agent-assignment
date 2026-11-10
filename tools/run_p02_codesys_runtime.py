"""Build and optionally execute the P02 scan tests on CODESYS Control Win."""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROFILE = "CODESYS V3.5 SP22 Patch 4"
DEVICE_NAME = "CODESYS Control Win V3 x64"
DEVICE_ID = "0000 0004"


def find_codesys() -> Path:
    configured = os.environ.get("CODESYS_EXE")
    candidates = [Path(configured)] if configured else []
    programs = Path(os.environ.get("ProgramFiles", r"C:\Program Files"))
    candidates.extend(sorted(programs.glob("CODESYS*/CODESYS/Common/CODESYS.exe"), reverse=True))
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    raise FileNotFoundError("CODESYS.exe not found; set CODESYS_EXE")


def split_pou(source: str) -> dict:
    source = source.lstrip("\ufeff")
    lines = [line for line in source.replace("\r\n", "\n").replace("\r", "\n").splitlines()
             if not re.match(r"^\s*```(?:st|iecst|structured\s+text)?\s*$", line, re.I)]
    header = re.compile(r"^\s*(PROGRAM|FUNCTION_BLOCK|FUNCTION)\s+([A-Za-z_]\w*)"
                        r"(?:\s*:\s*(.+?))?\s*$", re.I)
    start = next((i for i, line in enumerate(lines) if header.match(line)), None)
    if start is None:
        raise ValueError("No ST POU header found")
    match = header.match(lines[start])
    kind, name, return_type = match.group(1).upper(), match.group(2), match.group(3)
    if kind == "FUNCTION" and not return_type:
        raise ValueError("FUNCTION POU must declare a return type")
    var_open = re.compile(r"^\s*VAR(?:_[A-Z_]+)?(?:\s+.*)?\s*$", re.I)
    var_close = re.compile(r"^\s*END_VAR\s*;?\s*$", re.I)
    declaration_end = start + 1
    cursor = declaration_end
    while cursor < len(lines):
        while cursor < len(lines) and not lines[cursor].strip():
            cursor += 1
        if cursor >= len(lines) or not var_open.match(lines[cursor]) or var_close.match(lines[cursor]):
            break
        end = cursor + 1
        while end < len(lines) and not var_close.match(lines[end]):
            end += 1
        if end >= len(lines):
            raise ValueError("VAR block is missing END_VAR")
        declaration_end = end + 1
        cursor = declaration_end
    declaration = "\n".join(lines[start:declaration_end]).strip() + "\n"
    implementation = "\n".join(lines[declaration_end:]).strip() + "\n"
    terminator = re.compile(r"^\s*END_(?:PROGRAM|FUNCTION_BLOCK|FUNCTION)\s*;?\s*$", re.I)
    body = implementation.splitlines()
    while body and not body[-1].strip():
        body.pop()
    while body and terminator.match(body[-1]):
        body.pop()
        while body and not body[-1].strip():
            body.pop()
    return {"kind": kind, "name": name, "return_type": return_type,
            "declaration": declaration, "implementation": "\n".join(body).strip() + "\n"}


def split_pous(source: str) -> list[dict]:
    """Split model output containing several top-level IEC POUs."""
    lines = source.lstrip("\ufeff").replace("\r\n", "\n").replace("\r", "\n").splitlines()
    header = re.compile(r"^\s*(PROGRAM|FUNCTION_BLOCK|FUNCTION)\s+[A-Za-z_]\w*"
                        r"(?:\s*:\s*.+?)?\s*$", re.I)
    starts = [index for index, line in enumerate(lines) if header.match(line)]
    if not starts:
        raise ValueError("No ST POU declarations found")
    result = []
    for start in starts:
        line = lines[start].strip()
        kind = re.match(r"(PROGRAM|FUNCTION_BLOCK|FUNCTION)\b", line, re.I).group(1).upper()
        end_token = "END_" + kind
        end_re = re.compile(r"^\s*" + end_token + r"\s*;?\s*$", re.I)
        end = next((index for index in range(start + 1, len(lines)) if end_re.match(lines[index])), None)
        if end is None:
            raise ValueError("Missing " + end_token + " for " + line)
        result.append(split_pou("\n".join(lines[start:end + 1])))
    names = [item["name"].lower() for item in result]
    if len(names) != len(set(names)):
        raise ValueError("Duplicate POU names in generated source")
    return result


def runscript_source(pous: list[dict], runner: dict, project_path: Path, result_path: Path,
                     run_runtime: bool, timeout_ms: int) -> str:
    values = {
        "SOURCE_POUS": pous,
        "RUNNER_DECL": runner["declaration"], "RUNNER_IMPL": runner["implementation"],
        "PROJECT_PATH": str(project_path.resolve()), "RESULT_PATH": str(result_path.resolve()),
        "RUN_RUNTIME": run_runtime, "RUNTIME_TIMEOUT_MS": timeout_ms,
    }
    embedded = "\n".join("%s = %r" % (key, value) for key, value in values.items())
    body = r'''# IronPython script executed by CODESYS.
import io, json, re, traceback
from scriptengine import *
__EMBEDDED__

result = {"status":"ERROR", "compile_errors":[], "compile_warnings":[], "runtime":{}}
project = None
online_app = None
gateway = None
try:
    project = projects.create(PROJECT_PATH)
    devices = device_repository.get_all_devices("__DEVICE_NAME__", None)
    matches = [item for item in devices if item.device_id.id == "__DEVICE_ID__"]
    if not matches:
        raise Exception("Installed CODESYS Control Win x64 device description is unavailable")
    device_info = sorted(matches, key=lambda item: tuple(int(x) for x in str(item.device_id.version).split(".")), reverse=True)[0]
    project.add("Device", device_info.device_id)
    app = list(project.find("Application", True))[0]
    for source_pou in SOURCE_POUS:
        kind = source_pou["kind"]
        name = source_pou["name"]
        if kind == "PROGRAM":
            pou = app.create_pou(name, PouType.Program, ImplementationLanguages.st)
        elif kind == "FUNCTION_BLOCK":
            pou = app.create_pou(name, PouType.FunctionBlock, ImplementationLanguages.st)
        else:
            pou = app.create_function(name, source_pou["return_type"], ImplementationLanguages.st)
        pou.textual_declaration.replace(source_pou["declaration"])
        pou.textual_implementation.replace(source_pou["implementation"])
    runner = app.create_pou("P02RuntimeTest", PouType.Program, ImplementationLanguages.st)
    runner.textual_declaration.replace(RUNNER_DECL)
    runner.textual_implementation.replace(RUNNER_IMPL)
    libs = [lib for lib in librarymanager.get_all_libraries()
            if str(lib.title) == "Standard" and str(lib.company) == "System" and str(lib.version) == "3.5.22.0"]
    if not libs:
        raise Exception("Standard (System) 3.5.22.0 library is unavailable")
    app.get_library_manager().add_library(libs[0])
    task_config = app.create_task_configuration()
    task = task_config.create_task("MainTask")
    task.kind_of_task = KindOfTask.Cyclic
    task.interval = "t#50ms"
    task.pous.add("P02RuntimeTest")
    for reference in app.get_library_manager().references:
        if getattr(reference, "is_placeholder", False) and reference.placeholder_name == "IoStandard":
            reference.default_resolution = "IoStandard, 3.5.22.0 (System)"
    project.save()
    for category in system.get_message_categories(False):
        system.clear_messages(category)
    app.rebuild()
    for category in system.get_message_categories():
        category_name = str(system.get_message_category_description(category))
        for message in system.get_message_objects(category, Severity.FatalError | Severity.Error):
            result["compile_errors"].append({"category":category_name, "text":str(message.text)})
        for message in system.get_message_objects(category, Severity.Warning):
            result["compile_warnings"].append({"category":category_name, "text":str(message.text)})
    result["target"] = {"name":"__DEVICE_NAME__", "id":"__DEVICE_ID__", "version":str(device_info.device_id.version)}
    if result["compile_errors"]:
        result["status"] = "COMPILE_FAIL"
    else:
        result["status"] = "COMPILE_PASS"
        if RUN_RUNTIME:
            try:
                drivers = list(online.gateway_drivers.find_with_name("TCP/IP"))
                if not drivers:
                    raise Exception("CODESYS TCP/IP gateway driver is unavailable")
                gateway = online.gateways.add_new_gateway(
                    "Codex P02 runtime test", {"IP-Address":"localhost", "Port":1217}, drivers[0])
                targets = gateway.perform_network_scan()
                target = None
                for candidate in targets:
                    if str(candidate.device_id.id) == "__DEVICE_ID__":
                        target = candidate
                        break
                if target is None:
                    raise Exception("Control Win runtime was not found by the local CODESYS Gateway")
                device = [obj for obj in project.find("Device", True) if obj.is_device][0]
                device.set_gateway_and_address(gateway, target.address)
                project.save()
                online_app = online.create_online_application(app)
                online_app.login(OnlineChangeOption.Try, False)
                if online_app.application_state != ApplicationState.run:
                    online_app.start()
                done = False
                max_polls = max(1, int(RUNTIME_TIMEOUT_MS / 100))
                for attempt in range(0, max_polls):
                    system.delay(100)
                    value = str(online_app.read_value("P02RuntimeTest.test_done")).strip().upper()
                    if value == "TRUE":
                        done = True
                        break
                expressions = ["P02RuntimeTest.test_done", "P02RuntimeTest.passed",
                               "P02RuntimeTest.failed", "P02RuntimeTest.first_failed_case"]
                fields = ("case_pass", "actual_hasChanged", "actual_hasRisingEdges",
                          "actual_risingBits", "actual_noOfRisingBits", "actual_hasFallingEdges",
                          "actual_fallingBits", "actual_noOfFallingBits")
                for index in range(1, 6):
                    for field in fields:
                        expressions.append("P02RuntimeTest.%s[%d]" % (field, index))
                vals = online_app.read_values(expressions)
                value_map = dict(zip(expressions, vals))
                case_results = []
                case_passes = []
                for index in range(1, 6):
                    case_result = {"case":index}
                    for field in fields:
                        key = "P02RuntimeTest.%s[%d]" % (field, index)
                        case_result[field] = value_map.get(key)
                    case_passes.append(str(case_result["case_pass"]).strip().upper() in ("TRUE", "1"))
                    case_results.append(case_result)
                result["runtime"] = {"state":"COMPLETED" if done else "TIMEOUT",
                                      "passed":value_map.get("P02RuntimeTest.passed"),
                                      "failed":value_map.get("P02RuntimeTest.failed"),
                                      "first_failed_case":value_map.get("P02RuntimeTest.first_failed_case"),
                                      "case_results":case_results}
                pass_count = int(str(value_map.get("P02RuntimeTest.passed", "0")).split("#")[-1])
                fail_count = int(str(value_map.get("P02RuntimeTest.failed", "0")).split("#")[-1])
                if done and fail_count == 0 and pass_count == 5 and all(case_passes):
                    result["status"] = "RUNTIME_PASS"
                elif done:
                    result["status"] = "RUNTIME_FAIL"
                else:
                    result["status"] = "RUNTIME_TIMEOUT"
            except Exception as error:
                result["status"] = "RUNTIME_UNAVAILABLE"
                result["runtime"] = {"state":"UNAVAILABLE", "error":str(error), "traceback":traceback.format_exc()}
finally:
    if online_app is not None:
        try:
            if online_app.application_state == ApplicationState.run:
                online_app.stop()
        except Exception:
            pass
        try:
            online_app.logout()
        except Exception:
            pass
    if gateway is not None:
        try:
            online.gateways.remove_gateway(gateway.guid)
        except Exception:
            pass
    if project is not None:
        try:
            project.save()
            project.close()
        except Exception:
            pass
with io.open(RESULT_PATH, "w", encoding="utf-8") as stream:
    json.dump(result, stream, ensure_ascii=False, indent=2)
print(json.dumps(result, ensure_ascii=False))
if result["status"] not in ("COMPILE_PASS", "RUNTIME_PASS"):
    system.exit(1)
'''
    for key, value in values.items():
        body = body.replace("__" + key + "__", repr(value) if not isinstance(value, bool) else str(value))
    return (body.replace("__EMBEDDED__", embedded)
                .replace("__DEVICE_NAME__", DEVICE_NAME)
                .replace("__DEVICE_ID__", DEVICE_ID))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=ROOT / "st/runs/self/deepseek/P02_attempt1.st")
    parser.add_argument("--driver", type=Path, default=ROOT / "tests/structured_text/P02_runtime_driver.st")
    parser.add_argument("--output-dir", type=Path, default=None)
    parser.add_argument("--profile", default=DEFAULT_PROFILE)
    parser.add_argument("--run", action="store_true", help="download and execute on Control Win runtime")
    parser.add_argument("--timeout", type=int, default=300, help="CODESYS process timeout in seconds")
    args = parser.parse_args()
    stamp = __import__("datetime").datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = (args.output_dir or ROOT / "experiments/local_runs/codesys_runtime" / ("P02_" + stamp)).resolve()
    try:
        output_dir.relative_to((ROOT / "experiments/local_runs").resolve())
    except ValueError:
        raise SystemExit("--output-dir must be under experiments/local_runs")
    if output_dir.exists() and any(output_dir.iterdir()):
        raise SystemExit("Output directory is not empty; choose a new local_runs path")
    output_dir.mkdir(parents=True, exist_ok=True)
    source_pous = split_pous(args.source.read_text(encoding="utf-8-sig"))
    runner = split_pou(args.driver.read_text(encoding="utf-8-sig"))
    if not any(pou["kind"] == "FUNCTION_BLOCK" and pou["name"] == "FB_DualWordEdgeDetection"
               for pou in source_pous) or runner["kind"] != "PROGRAM":
        raise SystemExit("P02 runtime smoke test requires FB_DualWordEdgeDetection and a PROGRAM driver")
    project_path = output_dir / "P02RuntimeTest.project"
    script_path = output_dir / "codesys_test.py"
    result_path = output_dir / "result.json"
    script_path.write_text(runscript_source(source_pous, runner, project_path, result_path,
                                            args.run, timeout_ms=10000), encoding="utf-8")
    executable = find_codesys()
    # CODESYS parses the quoted profile and runscript values from one Windows
    # command line. Passing each quoted token as a Python argv item leaves the
    # embedded quote characters in the value, so preserve the native syntax.
    command = '"%s" --profile="%s" --runscript="%s" --noUI' % (
        executable, args.profile, script_path)
    try:
        process = subprocess.run(command, cwd=str(ROOT), capture_output=True,
                                 text=True, encoding="utf-8", errors="replace",
                                 timeout=args.timeout, check=False)
    except subprocess.TimeoutExpired as exc:
        (output_dir / "stdout.txt").write_text(str(exc.stdout or ""), encoding="utf-8")
        (output_dir / "stderr.txt").write_text(str(exc.stderr or ""), encoding="utf-8")
        print(json.dumps({"status":"CODESYS_PROCESS_TIMEOUT", "output_dir":str(output_dir)}, indent=2))
        return 2
    (output_dir / "stdout.txt").write_text(process.stdout or "", encoding="utf-8")
    (output_dir / "stderr.txt").write_text(process.stderr or "", encoding="utf-8")
    if not result_path.is_file():
        print(json.dumps({"status":"NO_RESULT", "exit_code":process.returncode,
                          "output_dir":str(output_dir), "stderr":(process.stderr or "")[-3000:]}, indent=2))
        return 2
    result = json.loads(result_path.read_text(encoding="utf-8"))
    result["source"] = str(args.source.resolve())
    result["source_sha256"] = __import__("hashlib").sha256(args.source.read_bytes()).hexdigest()
    result["source_pous"] = [pou["name"] for pou in source_pous]
    result["driver"] = str(args.driver.resolve())
    result["driver_sha256"] = __import__("hashlib").sha256(args.driver.read_bytes()).hexdigest()
    result["project"] = str(project_path)
    result["run_requested"] = args.run
    result["codesys_return_code"] = process.returncode
    result["codesys_stdout"] = (process.stdout or "")[-5000:]
    result["codesys_stderr"] = (process.stderr or "")[-5000:]
    result_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key:value for key,value in result.items()
                      if key not in ("codesys_stdout", "codesys_stderr")}, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "COMPILE_PASS" and not args.run else (0 if result["status"] == "RUNTIME_PASS" else 1)


if __name__ == "__main__":
    raise SystemExit(main())
