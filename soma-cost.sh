#!/bin/bash
# soma-cost - Token usage tracker for Clawdbot agents
# Track API costs, optimize spending, survive longer

LOG_FILE="${HOME}/.soma-cost.log"
CONFIG_FILE="${HOME}/.soma-cost.conf"

# Default config
DAILY_BUDGET="3.00"
MONTHLY_BUDGET="90.00"

init() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'CONF'
# Soma Cost Configuration
DAILY_BUDGET=3.00
MONTHLY_BUDGET=90.00
CONF
    fi
    source "$CONFIG_FILE"
    if [ ! -f "$LOG_FILE" ]; then
        echo "timestamp,model,input_tokens,output_tokens,cost_usd" > "$LOG_FILE"
    fi
}

log_call() {
    local model="$1"
    local input_tokens="${2:-0}"
    local output_tokens="${3:-0}"
    
    # Rough cost calculation (approximate)
    local input_cost=$(awk "BEGIN {printf \"%.6f\", $input_tokens * 0.000003}")
    local output_cost=$(awk "BEGIN {printf \"%.6f\", $output_tokens * 0.000015}")
    local total_cost=$(awk "BEGIN {printf \"%.6f\", $input_cost + $output_cost}")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "$timestamp,$model,$input_tokens,$output_tokens,$total_cost" >> "$LOG_FILE"
    echo "$total_cost"
}

show_stats() {
    echo "=== Soma Cost Report ==="
    echo ""
    
    local today=$(date -u +"%Y-%m-%d")
    local this_month=$(date -u +"%Y-%m")
    
    # Calculate today's spend
    local today_spend="0"
    if [ -f "$LOG_FILE" ]; then
        today_spend=$(grep "^$today" "$LOG_FILE" 2>/dev/null | cut -d',' -f5 | awk '{s+=$1} END {if(s) printf "%.4f", s; else print "0.0000"}')
    fi
    [ -z "$today_spend" ] && today_spend="0.0000"
    
    # Calculate monthly spend
    local month_spend="0"
    if [ -f "$LOG_FILE" ]; then
        month_spend=$(grep "^$this_month" "$LOG_FILE" 2>/dev/null | cut -d',' -f5 | awk '{s+=$1} END {if(s) printf "%.2f", s; else print "0.00"}')
    fi
    [ -z "$month_spend" ] && month_spend="0.00"
    
    # Count today's calls
    local today_calls="0"
    if [ -f "$LOG_FILE" ]; then
        today_calls=$(grep -c "^$today" "$LOG_FILE" 2>/dev/null || echo "0")
    fi
    
    echo "Today's Spend:    \$${today_spend} / \$${DAILY_BUDGET}"
    echo "Today's Calls:    ${today_calls}"
    echo "Monthly Spend:    \$${month_spend} / \$${MONTHLY_BUDGET}"
    echo ""
    
    # Calculate remaining budgets
    local daily_remaining=$(awk "BEGIN {printf \"%.2f\", $DAILY_BUDGET - $today_spend}")
    local month_remaining=$(awk "BEGIN {printf \"%.2f\", $MONTHLY_BUDGET - $month_spend}")
    
    echo "Daily Budget:     \$${daily_remaining} remaining"
    echo "Monthly Budget:   \$${month_remaining} remaining"
    
    # Warnings
    local daily_pct=$(awk "BEGIN {printf \"%.0f\", ($today_spend / $DAILY_BUDGET) * 100}")
    local month_pct=$(awk "BEGIN {printf \"%.0f\", ($month_spend / $MONTHLY_BUDGET) * 100}")
    
    if [ "$daily_pct" -gt 80 ]; then
        echo ""
        echo "⚠️  WARNING: Daily budget ${daily_pct}% consumed"
    fi
    if [ "$month_pct" -gt 80 ]; then
        echo ""
        echo "⚠️  WARNING: Monthly budget ${month_pct}% consumed"
    fi
    
    echo ""
    echo "Log: $LOG_FILE | Config: $CONFIG_FILE"
}

show_help() {
    cat << 'HELP'
soma-cost - Token usage tracker for Clawdbot agents

USAGE:
  soma-cost stats          Show spending report
  soma-cost log MODEL IN OUT   Log API call (for automation)
  soma-cost history        Show recent calls
  soma-cost export         Export full CSV

CONFIG:
  Edit ~/.soma-cost.conf to set budgets
  Default: $3/day, $90/month

EXAMPLE:
  soma-cost log claude-opus 15000 5000
  soma-cost stats

HELP
}

# Main
init

case "${1:-stats}" in
    stats)
        show_stats
        ;;
    log)
        log_call "$2" "$3" "$4"
        ;;
    history)
        tail -20 "$LOG_FILE"
        ;;
    export)
        cat "$LOG_FILE"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
