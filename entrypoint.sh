#!/bin/sh

set -e

# Load saved schedule or use provided/default schedule
SAVED_CRON_SCHEDULE=$(cat /data/cron_schedule.txt 2>/dev/null || echo "")
if [ -n "$CRON_SCHEDULE" ]; then
    INITIAL_CRON_SCHEDULE=$CRON_SCHEDULE
else
    INITIAL_CRON_SCHEDULE=$(date -d "now + 2 weeks - 1 minute" "+%M %H %d %m *")
fi

CRON_SCHEDULE=${SAVED_CRON_SCHEDULE:-$INITIAL_CRON_SCHEDULE}

echo "Schedule: $CRON_SCHEDULE"

# Save the schedule for container restarts
echo "$CRON_SCHEDULE" > /data/cron_schedule.txt

# Set up cron schedule
echo "$CRON_SCHEDULE /app/monitor.sh" | crontab -

# Start monitoring immediately if this is the first run (no saved schedule)
if [ -z "$SAVED_CRON_SCHEDULE" ]; then
    echo "Starting initial monitor"
    /app/monitor.sh &
fi

# Start cron daemon
echo "Starting cron daemon..."
/usr/sbin/crond -f -l 8
