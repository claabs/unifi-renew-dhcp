# unifi-renew-dhcp

A script that monitors internet connectivity for a short window and, if the WAN goes down, SSHes to a UniFi controller to force a DHCP renew on a specified interface. After a successful restore it schedules the next check two weeks later.

## Setup

### Docker run

```sh
docker run --rm -ti \
  -v $(pwd)/data:/data \
  -e TZ=America/Chicago \
  -e UNIFI_HOST=192.168.2.1 \
  -e WAN_INTERFACE=eth9 \
  ghcr.io/claabs/unifi-renew-dhcp
```

### Docker Compose

```yaml
services:
  unifi-renew-dhcp:
    image: ghcr.io/claabs/unifi-renew-dhcp
    restart: unless-stopped
    environment:
      - TZ=America/Chicago
      - UNIFI_HOST=192.168.2.1
      - WAN_INTERFACE=eth9
      # prime with initial cron schedule of slightly before when your next outage will be
      - CRON_SCHEDULE=32 21 09 11 *
    volumes:
    - ./data:/data
```

### Environment variables

- `UNIFI_HOST` (default: `192.168.1.1`)
  - IP or hostname of the UniFi controller / device to SSH into to trigger a DHCP renew.
- `WAN_INTERFACE` (default: `eth9`)
  - Interface on the Unifi device to force a DHCP renew on.
- `CHECK_DURATION` (default: `3600`)
  - How long (in seconds) to run the per-second connectivity check window (default 3600 = 1 hour).
- `WAN_RESTORE_WAIT` (default: `10`)
  - Seconds to wait after running the DHCP command for the WAN to come back before checking connectivity.
- `PING_TARGET` (default: `8.8.8.8`)
  - IP address used for the connectivity check ping. Change if you prefer another reliable host.
- `CRON_SCHEDULE` (optional)
  - Used to prime with initial cron schedule of slightly before when your next outage will be. If not provided, the container will use the schedule stored in  `/data/cron_schedule.txt`, or fall back to computing a schedule of "now + 2 weeks - 1 minute".

### Files in the `/data` volume

Mount a host directory to `/data` inside the container. The container uses the following files in that directory:

- `/data/sshpass.txt` **(Required)**
  - Plain-text SSH password for your Unifi console
- `/data/cron_schedule.txt`
  - Stores the active crontab schedule line (cron-format). Updated to 2 weeks later after every run of the repair script.

## Development

```sh
docker build -t unifi-renew-dhcp .
docker run --rm -ti -v $(pwd)/data:/data -e TZ=America/Chicago -e UNIFI_HOST=192.168.2.1 unifi-renew-dhcp
```
