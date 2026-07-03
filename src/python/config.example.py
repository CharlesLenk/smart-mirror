# Brightness configuration example. See readme.
#
# config.py is git-ignored, so your settings survive `git pull`. Any value you
# omit falls back to the default in brightness.py.

LATITUDE = 47.6062                  # degrees North (negative = South)
LONGITUDE = -122.3321               # degrees East  (negative = West)
TIMEZONE = "America/Los_Angeles"    # IANA timezone name

# Optional brightness tuning (0-255):
# MIN_BRIGHTNESS = 30               # night
# MAX_BRIGHTNESS = 150              # day
# FADE_WINDOW_MINUTES = 60          # total fade length, centered on sunrise/sunset
