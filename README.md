# Smart Mirror

## Setup

1. Install PI OS (the steps below are for "Trixie").
2. Clone this project into your home directory.
3. Create `~/smart-mirror/src/js/secrets.js`:
    ```
    let tomorrowIoApiKey = 'Your API key';
    let gpsLocation = '47.6061,-122.3328'; // Update with the coordinates you want weather for
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
    wtype -M alt -M logo h -m alt -m logo &&
    git -C ~/smart-mirror/ pull &&
    chromium ~/smart-mirror/src/index.html --incognito --noerrdialogs --kiosk &
    ```
    This will:

    1. Execute the keyboard command to hide the cursor.
    2. Clone the most recent version of this project.
    3. Start Chromium in kiosk mode

7. If you're using the stock raspberry PI display with touchscreen, add the following to `/boot/firmware/config.txt`:

    ```
    dtoverlay=rpi-backlight
    disable_touchscreen=1
    ```
    To control the backlight, set a numeric value in the brightness file. For example:

    ```
    echo 32 | sudo tee /sys/class/backlight/rpi_backlight/brightness
    ```
