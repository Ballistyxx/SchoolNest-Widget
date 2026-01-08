#!/bin/bash

# Script to fetch and parse school schedule from Sparrows website
# This extracts the schedule JSON from the HTML and saves it locally

SCHEDULE_URL="https://sparrows.school/phs"
SCHEDULE_DIR="$HOME/.local/share/schoolnest"
SCHEDULE_FILE="$SCHEDULE_DIR/schedule.json"
RELOAD_TRIGGER="$SCHEDULE_DIR/.reload_trigger"

# Create directory if it doesn't exist
mkdir -p "$SCHEDULE_DIR"

# Fetch the page
echo "Fetching schedule from $SCHEDULE_URL..."
HTML_CONTENT=$(curl -s "$SCHEDULE_URL")

if [ -z "$HTML_CONTENT" ]; then
    echo "Error: Failed to fetch schedule"
    exit 1
fi

# Extract the schedule JSON from the embedded script
# The data is in Next.js hydration format with escaped quotes
# Extract the schedule object with all periods
SCHEDULE_DATA=$(echo "$HTML_CONTENT" | grep -oP 'schedule\\":\{[^}]*periods\\":\[.*?\]\}')

if [ -z "$SCHEDULE_DATA" ]; then
    echo "Error: Failed to parse schedule from HTML"
    # On days off, the website may not have schedule data
    # Write an empty schedule with today's date to indicate "no school"
    CURRENT_DATE=$(date +%Y-%m-%d)
    echo "{\"fetched_date\":\"$CURRENT_DATE\",\"schedule\":null}" > "$SCHEDULE_FILE"
    echo "No schedule found (likely a day off) - saved empty schedule"
    exit 0
fi

# Remove the escaped backslashes and convert to proper JSON
# The data has \" which needs to become "
CLEAN_JSON=$(echo "$SCHEDULE_DATA" | sed 's/\\"/"/g')

# Add the fetch date to track when this was last updated
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H:%M:%S)

# Wrap in a proper JSON object with date metadata
echo "{\"fetched_date\":\"$CURRENT_DATE\",\"fetched_time\":\"$CURRENT_TIME\",\"$CLEAN_JSON}" > "$SCHEDULE_FILE"

# Touch reload trigger to notify the widget to reload
touch "$RELOAD_TRIGGER"

echo "Schedule saved to $SCHEDULE_FILE"

# Display the schedule for verification
if command -v jq &> /dev/null; then
    echo ""
    echo "Current schedule (fetched $CURRENT_DATE at $CURRENT_TIME):"
    jq '.' "$SCHEDULE_FILE"
else
    echo ""
    echo "Schedule file contents:"
    cat "$SCHEDULE_FILE"
fi
