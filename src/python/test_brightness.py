import brightness
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

from brightness import find_backlight_dir, get_sun_times, target_brightness, write_brightness

TZ = timezone.utc
SUNRISE = datetime(2026, 6, 29, 6, 0, tzinfo=TZ)
SUNSET = datetime(2026, 6, 29, 20, 0, tzinfo=TZ)
MIN_B, MAX_B, FADE_WINDOW = 30, 150, 60  # 60-min window => 30 min each side
HALF = timedelta(minutes=FADE_WINDOW // 2)


def tb(now):
    return target_brightness(now, SUNRISE, SUNSET, MIN_B, MAX_B, FADE_WINDOW)


def test_deep_night_before_dawn_is_min():
    assert tb(datetime(2026, 6, 29, 3, 0, tzinfo=TZ)) == MIN_B


def test_midday_is_max():
    assert tb(datetime(2026, 6, 29, 12, 0, tzinfo=TZ)) == MAX_B


def test_after_sunset_window_is_min():
    assert tb(datetime(2026, 6, 29, 23, 0, tzinfo=TZ)) == MIN_B


def test_sunrise_window_start_is_min():
    assert tb(SUNRISE - HALF) == MIN_B


def test_sunrise_window_end_is_max():
    assert tb(SUNRISE + HALF) == MAX_B


def test_exact_sunrise_is_midpoint():
    assert tb(SUNRISE) == (MIN_B + MAX_B) // 2  # 90


def test_exact_sunset_is_midpoint():
    assert tb(SUNSET) == (MIN_B + MAX_B) // 2  # 90


def test_sunset_window_end_is_min():
    assert tb(SUNSET + HALF) == MIN_B


def test_quarter_into_sunrise_window():
    # 15 min into a 60-min window = 25% of the way from 30 to 150 = 60
    assert tb(SUNRISE - HALF + timedelta(minutes=15)) == 60


def test_never_exceeds_bounds():
    for hour in range(24):
        v = tb(datetime(2026, 6, 29, hour, 0, tzinfo=TZ))
        assert MIN_B <= v <= MAX_B


def test_get_sun_times_seattle_summer():
    # Seattle: ~47.6062 N, 122.3321 W
    sunrise, sunset = get_sun_times(
        date(2026, 6, 29), 47.6062, -122.3321, "America/Los_Angeles"
    )
    assert sunrise.tzinfo is not None
    assert sunset.tzinfo is not None
    assert sunrise < sunset
    assert sunrise.date() == date(2026, 6, 29)
    # Midsummer Seattle sunrise is very early (before 06:00 local).
    assert sunrise.hour < 6


def test_find_backlight_dir_detects_brightness_file(tmp_path):
    bl = tmp_path / "rpi_backlight"
    bl.mkdir()
    (bl / "brightness").write_text("100")
    assert find_backlight_dir(base=str(tmp_path)) == bl


def test_find_backlight_dir_returns_none_when_absent(tmp_path):
    assert find_backlight_dir(base=str(tmp_path)) is None


def test_write_brightness_writes_integer(tmp_path):
    (tmp_path / "brightness").write_text("0")
    write_brightness(90, tmp_path)
    assert (tmp_path / "brightness").read_text().strip() == "90"


def test_main_falls_back_to_max_on_error(tmp_path, monkeypatch):
    target = tmp_path / "brightness"
    target.write_text("0")
    # Backlight is found...
    monkeypatch.setattr(brightness, "find_backlight_dir", lambda: tmp_path)
    # ...but sun-time lookup blows up.
    def boom(*a, **k):
        raise RuntimeError("no sun today")
    monkeypatch.setattr(brightness, "get_sun_times", boom)

    brightness.main()

    assert target.read_text().strip() == str(brightness.MAX_BRIGHTNESS)
