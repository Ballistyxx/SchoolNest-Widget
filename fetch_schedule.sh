#!/bin/bash

# Script to fetch and parse school schedule from Sparrows website
# This extracts the schedule JSON from the HTML and saves it locally

SCHEDULE_URL="https://sparrows.school/phs"
SCHEDULE_DIR="$HOME/.local/share/schoolnest"
SCHEDULE_FILE="$SCHEDULE_DIR/schedule.json"

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
    exit 1
fi

# Remove the escaped backslashes and convert to proper JSON
# The data has \" which needs to become "
CLEAN_JSON=$(echo "$SCHEDULE_DATA" | sed 's/\\"/"/g')

# Wrap in a proper JSON object (just add opening brace)
echo "{\"$CLEAN_JSON}" > "$SCHEDULE_FILE"

echo "Schedule saved to $SCHEDULE_FILE"

# Display the schedule for verification
if command -v jq &> /dev/null; then
    echo ""
    echo "Current schedule:"
    jq '.' "$SCHEDULE_FILE"
else
    echo ""
    echo "Schedule file contents:"
    cat "$SCHEDULE_FILE"
fi
