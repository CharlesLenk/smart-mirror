# Sunset Display Dimmer

Fades the Raspberry Pi official 7″ display between a night and day brightness
based on local sunrise/sunset times. Runs once per minute via cron.

## How it works

- Daytime: brightness held at `MAX_BRIGHTNESS` (150).
- Nighttime: brightness held at `MIN_BRIGHTNESS` (30).
- Around sunrise/sunset: brightness fades linearly over a window of
  `FADE_WINDOW_MINUTES` (**60**), **centered on the event** — so by default the
  fade runs from 30 minutes before sunrise/sunset to 30 minutes after.

Sunrise/sunset are computed locally from your latitude/longitude using the
`astral` library — no internet connection required at runtime.

## Install

```bash
sudo apt update && sudo apt install -y python3-venv
cd /home/pi/brightness-script        # wherever you put it
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## Configure

Copy the example config and edit it. `config.py` is git-ignored, so your
settings survive `git pull`:

```bash
cp config.example.py config.py
```

Any value you set in `config.py` overrides the default in `brightness.py`;
anything you omit keeps its default. It ships with **Seattle** coordinates:

| Constant         | Default                 | Meaning                                    |
|------------------|-------------------------|--------------------------------------------|
| `LATITUDE`       | `47.6062`               | Latitude in degrees North (− = South)      |
| `LONGITUDE`      | `-122.3321`             | Longitude in degrees East (− = West)       |
| `TIMEZONE`       | `America/Los_Angeles`   | IANA timezone name                         |
| `MIN_BRIGHTNESS` | `30`                    | Night brightness (0–255)                   |
| `MAX_BRIGHTNESS` | `150`                   | Day brightness (0–255)                     |
| `FADE_WINDOW_MINUTES` | `60`               | Total fade length, centered on sunrise/sunset |

## Run it every minute (cron)

Writing the backlight requires root, so use root's crontab:

```bash
sudo crontab -e
```

Add (adjust the paths to where you cloned the project):

```
* * * * * /home/pi/brightness-script/.venv/bin/python /home/pi/brightness-script/brightness.py
```

## Run as a non-root user (optional)

Instead of root's crontab, grant the `video` group write access to the backlight
with a udev rule:

```bash
echo 'SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' | sudo tee /etc/udev/rules.d/90-backlight.rules
sudo udevadm control --reload && sudo udevadm trigger
```

Make sure your user is in the `video` group (`sudo usermod -aG video $USER`,
then re-login), and put the cron line in your own `crontab -e`.

## Test

Tests need the dev dependencies (`pytest`), which are kept out of the runtime
`requirements.txt`:

```bash
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/pytest test_brightness.py -v
```

## Manual one-off run

```bash
sudo .venv/bin/python brightness.py
```

On a machine with no backlight (e.g. your laptop) this prints
`No backlight directory found under /sys/class/backlight` and exits cleanly.
