# CODESYS offline compile validation

Environment: CODESYS V3.5 SP22 Patch 4, compiler/device description 3.5.22.40, CODESYS Control Win V3 x64 (device ID `0000 0004`). Each record contains the exact compiler result and raw CODESYS stdout/stderr. `manifest.json` binds each record to the SHA-256 of the source file used.

- `S08_pi_compile.json`: complete PROGRAM, PASS, 0 errors and 0 warnings.
- `P02_self_compile.json`: complete FUNCTION_BLOCK, PASS, 0 errors and 0 warnings.
- `S08_self_compile.json`: truncated PROGRAM, FAIL with C8 and C13; the generated source ends inside an `IF` block.

These are offline builds. They do not establish PLC download, scan-time behavior, functional test passage, or formal verification. Tests and PLCVerif remain unrun because no PLC runtime/verifier is configured.
