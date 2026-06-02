"""Restaurant tip calculator — all-constants fixture for changelog experiments.

v1.0.0: Computes a tip and total for a single restaurant bill.
"""

__version__ = "1.0.0"

BILL = 80.00
TIP_RATE = 0.18


def compute() -> str:
    tip = BILL * TIP_RATE
    total = BILL + tip
    return f"Bill: ${BILL:.2f}  Tip ({TIP_RATE:.0%}): ${tip:.2f}  Total: ${total:.2f}"
