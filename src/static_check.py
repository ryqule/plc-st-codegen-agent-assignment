"""Conservative ST source precheck; this is not a compiler."""
from __future__ import annotations

import re

REQUIRED_TERMINATORS = {
    "FUNCTION_BLOCK": "END_FUNCTION_BLOCK",
    "PROGRAM": "END_PROGRAM",
    "FUNCTION": "END_FUNCTION",
}

def check_source(source: str) -> list[str]:
    errors: list[str] = []
    text = re.sub(r"\(\*.*?\*\)|//[^\n]*", " ", source, flags=re.S)
    upper = text.upper()
    openings = [(kw, end) for kw, end in REQUIRED_TERMINATORS.items()
                if re.search(rf"\b{kw}\b", upper)]
    if not openings:
        errors.append("No FUNCTION_BLOCK, PROGRAM, or FUNCTION declaration found.")
    for opener, closer in openings:
        if not re.search(rf"\b{closer}\b", upper):
            errors.append(f"Missing {closer}.")
    if "VAR" in upper and "END_VAR" not in upper:
        errors.append("VAR section has no END_VAR.")
    for token in ("IF", "CASE", "FOR", "WHILE", "REPEAT"):
        if re.search(rf"\b{token}\b", upper):
            end = {"IF":"END_IF", "CASE":"END_CASE", "FOR":"END_FOR",
                   "WHILE":"END_WHILE", "REPEAT":"UNTIL"}[token]
            if not re.search(rf"\b{end}\b", upper):
                errors.append(f"{token} has no matching {end} token.")
    return errors

def extract_st(text: str) -> str:
    match = re.search(r"```(?:st|iecst|structured\s*text)?\s*\n(.*?)```", text, flags=re.I | re.S)
    return match.group(1).strip() if match else text.strip()
