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
