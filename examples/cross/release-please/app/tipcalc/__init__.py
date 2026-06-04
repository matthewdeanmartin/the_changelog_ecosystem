"""Restaurant tip calculator — all-constants fixture for changelog experiments.

The experiment driver swaps this file between three versions to simulate a real
project's evolution. Each version is self-contained, takes no input, and prints
to stdout so the *app* is boring and the *tooling* is what we observe.

This file ships as the v1.0.0 implementation. run_experiment.sh overwrites it
with the v2.0.0 and v3.0.0 variants (kept in scenario/versions/) at the right
life-cycle stage.
"""

__version__ = "1.0.0"

# --- constants (the whole app is constants on purpose) ---
BILL = 80.00
TIP_RATE = 0.18


def compute() -> str:
    tip = BILL * TIP_RATE
    total = BILL + tip
    return f"Bill: ${BILL:.2f}  Tip ({TIP_RATE:.0%}): ${tip:.2f}  Total: ${total:.2f}"
