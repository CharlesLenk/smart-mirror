import glob
import sys
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from astral import LocationInfo
from astral.sun import sun

try:
    import config as _user_config
except ImportError:
    _user_config = None


def _cfg(name, default):
    return getattr(_user_config, name, default)


LATITUDE = _cfg("LATITUDE", 47.62)
LONGITUDE = _cfg("LONGITUDE", -122.34)
TIMEZONE = _cfg("TIMEZONE", "America/Los_Angeles")
MIN_BRIGHTNESS = _cfg("MIN_BRIGHTNESS", 30)
MAX_BRIGHTNESS = _cfg("MAX_BRIGHTNESS", 180)
FADE_WINDOW_MINUTES = _cfg("FADE_WINDOW_MINUTES", 60)


def target_brightness(now, sunrise, sunset, min_b, max_b, fade_window_minutes):
    """Brightness fades linearly across a window centered on sunrise (min->max) and sunset (max->min).
    `fade_window_minutes` is the total length of that window, split evenly before and after the event
    (e.g. 60 => the fade runs from 30 minutes before to 30 minutes after). Clamped to [min_b, max_b]."""
    half = timedelta(minutes=fade_window_minutes / 2)
    sunrise_start, sunrise_end = sunrise - half, sunrise + half
    sunset_start, sunset_end = sunset - half, sunset + half

    if now < sunrise_start:
        value = min_b
    elif now <= sunrise_end:
        frac = (now - sunrise_start) / (sunrise_end - sunrise_start)
        value = min_b + frac * (max_b - min_b)
    elif now < sunset_start:
        value = max_b
    elif now <= sunset_end:
        frac = (now - sunset_start) / (sunset_end - sunset_start)
        value = max_b - frac * (max_b - min_b)
    else:
        value = min_b

    return int(round(max(min_b, min(max_b, value))))


def get_sun_times(date, lat=LATITUDE, lon=LONGITUDE, tz_name=TIMEZONE):
    """Return (sunrise, sunset) as tz-aware datetimes for `date`."""
    tz = ZoneInfo(tz_name)
    location = LocationInfo(latitude=lat, longitude=lon)
    s = sun(location.observer, date=date, tzinfo=tz)
    return s["sunrise"], s["sunset"]


def find_backlight_dir(base="/sys/class/backlight"):
    """First backlight directory containing a 'brightness' file, or None."""
    matches = sorted(glob.glob(str(Path(base) / "*" / "brightness")))
    if not matches:
        return None
    return Path(matches[0]).parent


def write_brightness(value, backlight_dir):
    """Write an integer brightness to the backlight 'brightness' file."""
    (Path(backlight_dir) / "brightness").write_text(str(int(value)))


def main():
    backlight_dir = find_backlight_dir()
    if backlight_dir is None:
        print("No backlight directory found under /sys/class/backlight",
              file=sys.stderr)
        return
    try:
        now = datetime.now(ZoneInfo(TIMEZONE))
        sunrise, sunset = get_sun_times(now.date())
        value = target_brightness(
            now, sunrise, sunset,
            MIN_BRIGHTNESS, MAX_BRIGHTNESS, FADE_WINDOW_MINUTES,
        )
    except Exception as exc:
        print(f"Falling back to max brightness: {exc}", file=sys.stderr)
        value = MAX_BRIGHTNESS
    write_brightness(value, backlight_dir)


if __name__ == "__main__":
    main()
