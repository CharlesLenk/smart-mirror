# Smart Mirror

## Setup

1. Install PI OS (the steps below are for "Trixie").
2. Clone this project into your home directory.
3. Copy config.example.js and your your Tomorrow.io API key, and your latitude and longitude.
    ```
    cp config.example.js config.js
    ```
4. Rotate the display in the UI through Preferences > Control Centre > Screens.
5. Add a keyboard command to hide the mouse pointer to `~/.config/labwc/rc.xml`:

    ```
    <?xml version="1.0"?>
    <labwc_config>
    <keyboard>
        <keybind key="A-W-h">
        <action name="HideCursor" />
        <action name="WarpCursor" x="-1" y="-1" />
        </keybind>
    </keyboard>
    </labwc_config>
    ```

6. Add the following to `~/.config/labwc/autostart`:

    ```
    wtype -M alt -M logo h -m alt -m logo || true
    git -C ~/smart-mirror/ pull || true
    chromium ~/smart-mirror/src/index.html --incognito --noerrdialogs --kiosk &
    ```
    This will:

    1. Execute the keyboard command to hide the cursor.
    2. Pull the most recent version of this project.
    3. Start Chromium in kiosk mode

    The `|| true` on the first two lines is deliberate: if the cursor-hide or
    the `git pull` fails (e.g. no network at boot), the mirror still launches
    instead of leaving a blank screen.

7. If you're using the stock raspberry PI display with touchscreen, add the following to `/boot/firmware/config.txt`:

    ```
    dtoverlay=rpi-backlight
    disable_touchscreen=1
    ```
    To control the backlight, set a numeric value in the brightness file. For example:

    ```
    echo 32 | sudo tee /sys/class/backlight/rpi_backlight/brightness
    ```

## Auto-dim the display (optional)

Fades the brightness between day and night levels based on local
sunrise/sunset. Full details (permissions, configuration) are in
`src/python/README.md`.

1. Install the script's dependencies:

    ```
    cd ~/smart-mirror/src/python
    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    ```

2. Set your location in `config.py` (git-ignored, so it survives `git pull`):

    ```
    cp config.example.py config.py
    ```

    Then edit `LATITUDE`, `LONGITUDE`, and `TIMEZONE` in `config.py`.

3. Run it every minute from root's crontab (`sudo crontab -e`). The hours
   `0,4-23` skip the overnight off window below, so the script never switches
   the backlight back on while the display is meant to be off:

    ```
    * 0,4-23 * * * ~/smart-mirror/src/python/.venv/bin/python ~/smart-mirror/src/python/brightness.py
    ```

## Power the display off overnight (optional)

Fully powers the panel off (not just dims it) between 1am and 4am by having the
compositor disable and re-enable the display output.

1. Install `wlr-randr`:

    ```
    sudo apt install -y wlr-randr
    ```

2. Find your display's output name (the stock 7" display is usually `DSI-1`):

    ```
    wlr-randr
    ```

3. Add these lines to your own crontab (`crontab -e` — not root's, since the
   display belongs to your Wayland session). Replace `DSI-1` with your output
   name if different:

    ```
    0 1 * * * XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wlr-randr --output DSI-1 --off
    0 4 * * * XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wlr-randr --output DSI-1 --on
    ```

    `1000` is the default user id (check with `id -u`) and `wayland-0` is the
    usual display (check with `echo $WAYLAND_DISPLAY` inside the session).
