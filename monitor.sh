#!/bin/sh

set -e

UNIFI_HOST=${UNIFI_HOST:-"192.168.1.1"}
echo "UNIFI_HOST is set to: $UNIFI_HOST"
WAN_INTERFACE=${WAN_INTERFACE:-"eth9"}
echo "WAN_INTERFACE is set to: $WAN_INTERFACE"
WAN_RESTORE_WAIT=${WAN_RESTORE_WAIT:-10}
echo "WAN_RESTORE_WAIT is set to: $WAN_RESTORE_WAIT"
CHECK_DURATION=${CHECK_DURATION:-3600}
echo "CHECK_DURATION is set to: $CHECK_DURATION"
PING_TARGET=${PING_TARGET:-"8.8.8.8"}
echo "PING_TARGET is set to: $PING_TARGET"


# Function to check internet connectivity
check_internet() {
    ping -c 1 "$PING_TARGET" > /dev/null 2>&1
    return $?
}

# Function to update crontab for next run (2 weeks minus 1 minute from now)
update_crontab() {
    next_run=$(date -d "now + 2 weeks - 1 minute" "+%M %H %d %m *")
    echo "$next_run /app/monitor.sh" | crontab -
    # Save the new schedule
    echo "$next_run" > /data/cron_schedule.txt
}

echo "Starting internet connectivity monitoring for ${CHECK_DURATION} seconds..."

start_time=$(date +%s)
end_time=$((start_time + CHECK_DURATION))

while [ $(date +%s) -lt $end_time ]; do
    if ! check_internet; then
        echo "Internet connection lost. Renewing DHCP lease..."

        # Update crontab for next run
        update_crontab
        
        # Run the DHCP renewal command
        sshpass -f /data/sshpass.txt ssh -o StrictHostKeyChecking=no root@"$UNIFI_HOST" "/usr/bin/busybox-legacy/udhcpc --interface $WAN_INTERFACE --script /usr/share/ubios-udapi-server/ubios-udhcpc-script --decline-script /usr/share/ubios-udapi-server/ubios-udhcpc-decline-script"
        
        # Wait a bit for the connection to be restored
        sleep $WAN_RESTORE_WAIT
        
        if check_internet; then
            echo "Internet connection restored!"
            exit 0
        else
            echo "Failed to restore internet connection!"
            exit 1
        fi
        
    fi
    sleep 1
done

echo "Monitoring period ended without detecting internet failure."
exit 0