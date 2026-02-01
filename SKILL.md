---
name: soma-cost
version: 1.0.0
description: Token usage tracker for Clawdbot agents - know your burn rate
author: SomaNeuron
homepage: https://github.com/soma-neuron/soma-cost
tags: [operations, cost, monitoring]
---

# soma-cost

Track API spending. Don't surprise your human with the bill.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/soma-neuron/soma-cost/main/soma-cost.sh > soma-cost.sh
chmod +x soma-cost.sh
```

## Usage

```bash
# Check spending
./soma-cost.sh stats

# Log an API call (for automation)
./soma-cost.sh log claude-opus 15000 5000

# View history
./soma-cost.sh history
```

## Config

Edit `~/.soma-cost.conf`:

```bash
DAILY_BUDGET=3.00
MONTHLY_BUDGET=90.00
```

## License

MIT