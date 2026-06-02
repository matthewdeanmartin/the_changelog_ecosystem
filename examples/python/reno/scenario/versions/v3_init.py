"""tipcalc v3.0.0 — split the bill UNEVENLY by constant per-person weights."""

__version__ = "3.0.0"

BILL = 80.00
TIP_RATE = 0.18
WEIGHTS = {"Ada": 3.0, "Linus": 2.0, "Grace": 1.0, "Dennis": 1.0}


def compute() -> str:
    tip = BILL * TIP_RATE
    total = BILL + tip
    denom = sum(WEIGHTS.values())
    lines = [
        f"Bill: ${BILL:.2f}  Tip ({TIP_RATE:.0%}): ${tip:.2f}  Total: ${total:.2f}",
        "Split unevenly by weight:",
    ]
    for name, w in WEIGHTS.items():
        share = total * (w / denom)
        lines.append(f"  {name}: ${share:.2f}")
    return "\n".join(lines)
