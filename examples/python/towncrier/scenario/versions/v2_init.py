"""tipcalc v2.0.0 — split the bill EVENLY among a constant number of diners.

Drop-in replacement for tipcalc/__init__.py at life-cycle stage 3.
"""

__version__ = "2.0.0"

BILL = 80.00
TIP_RATE = 0.18
DINERS = 4


def compute() -> str:
    tip = BILL * TIP_RATE
    total = BILL + tip
    per_person = total / DINERS
    return (
        f"Bill: ${BILL:.2f}  Tip ({TIP_RATE:.0%}): ${tip:.2f}  "
        f"Total: ${total:.2f}  Split evenly {DINERS} ways: ${per_person:.2f} each"
    )
