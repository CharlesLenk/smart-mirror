'use strict';

/*
 * Weather data layer. Fetches current conditions + daily forecast from
 * Tomorrow.io and returns a normalized weather object. No jQuery.
 *
 * getWeather(location, apiKey) -> Promise<weather>
 *
 * weather = {
 *   temp, currently, icon, isNight,
 *   units: { temp, speed },
 *   wind:  { direction, speed },
 *   high, low,
 *   forecast: [ { day, high, low, icon }, ... ]
 * }
 */

// Tomorrow.io weather codes -> { icon, name }. `icon` is a Skycons icon name
// (names ending in _DAY are swapped to _NIGHT after sunset, see pickIcon);
// `name` is the human-readable label shown to the user.
const UNKNOWN_CONDITION = { icon: 'CLOUDY', name: 'Unknown' };

const WEATHER_CODE_MAP = new Map([
    [1000, { icon: 'CLEAR_DAY', name: 'Clear' }],
    [1100, { icon: 'CLEAR_DAY', name: 'Mostly Clear' }],
    [1101, { icon: 'PARTLY_CLOUDY_DAY', name: 'Partly Cloudy' }],
    [1102, { icon: 'CLOUDY', name: 'Mostly Cloudy' }],
    [1001, { icon: 'CLOUDY', name: 'Cloudy' }],
    [2000, { icon: 'FOG', name: 'Fog' }],
    [2100, { icon: 'FOG', name: 'Light Fog' }],
    [4000, { icon: 'SHOWERS_DAY', name: 'Drizzle' }],
    [4001, { icon: 'RAIN', name: 'Rain' }],
    [4200, { icon: 'SHOWERS_DAY', name: 'Light Rain' }],
    [4201, { icon: 'RAIN', name: 'Heavy Rain' }],
    [5000, { icon: 'SNOW', name: 'Snow' }],
    [5001, { icon: 'SNOW', name: 'Flurries' }],
    [5100, { icon: 'SNOW', name: 'Light Snow' }],
    [5101, { icon: 'SNOW', name: 'Heavy Snow' }],
    [6000, { icon: 'SLEET', name: 'Freezing Drizzle' }],
    [6001, { icon: 'SLEET', name: 'Freezing Rain' }],
    [6200, { icon: 'SLEET', name: 'Light Freezing Rain' }],
    [6201, { icon: 'SLEET', name: 'Heavy Freezing Rain' }],
    [7000, { icon: 'SLEET', name: 'Ice Pellets' }],
    [7101, { icon: 'SLEET', name: 'Heavy Ice Pellets' }],
    [7102, { icon: 'SLEET', name: 'Light Ice Pellets' }],
    [8000, { icon: 'THUNDER_RAIN', name: 'Thunderstorm' }],
]);

const COMPASS = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N'];

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function conditionForCode(code) {
    return WEATHER_CODE_MAP.get(code) || UNKNOWN_CONDITION;
}

// Swap a daytime Skycons name for its night variant after sunset.
function pickIcon(iconName, isNight) {
    return isNight ? iconName.replace('_DAY', '_NIGHT') : iconName;
}

function dayName(date) {
    return DAY_NAMES[date.getDay()];
}

const FETCH_TIMEOUT_MS = 15000;

async function fetchJson(url) {
    // Abort a hung request so a stalled connection can't wedge a refresh cycle.
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    try {
        const response = await fetch(url, { signal: controller.signal });
        if (!response.ok) {
            throw new Error('Weather request failed: ' + response.status);
        }
        return await response.json();
    } finally {
        clearTimeout(timer);
    }
}

async function getWeather(location, apiKey) {
    const base = 'https://api.tomorrow.io/v4/weather';
    const realtimeUrl = base + '/realtime?location=' + encodeURIComponent(location) +
        '&units=imperial&apikey=' + encodeURIComponent(apiKey);
    const forecastUrl = base + '/forecast?location=' + encodeURIComponent(location) +
        '&timesteps=1d&units=imperial&apikey=' + encodeURIComponent(apiKey);

    // Fire both together but wait for BOTH before building the result, so
    // there is no race over which response lands first.
    const [realtime, forecast] = await Promise.all([
        fetchJson(realtimeUrl),
        fetchJson(forecastUrl),
    ]);

    const cur = realtime.data.values;
    const days = forecast.timelines.daily;
    const today = days[0].values;

    // Determine day/night from today's sunrise/sunset when available,
    // otherwise default to daytime.
    const now = new Date();
    const sunrise = today.sunriseTime ? new Date(today.sunriseTime) : null;
    const sunset = today.sunsetTime ? new Date(today.sunsetTime) : null;
    const isNight = (sunrise && sunset)
        ? (now < sunrise || now > sunset)
        : false;

    const current = conditionForCode(cur.weatherCode);

    const weather = {
        temp: Math.round(cur.temperatureApparent),
        currently: current.name,
        icon: pickIcon(current.icon, isNight),
        isNight: isNight,
        units: { temp: 'F', speed: 'mph' },
        wind: {
            direction: COMPASS[Math.round(cur.windDirection / 22.5)],
            speed: Math.round(cur.windSpeed),
        },
        high: Math.round(today.temperatureApparentMax),
        low: Math.round(today.temperatureApparentMin),
        forecast: [],
    };

    for (let i = 1; i < days.length; i++) {
        const v = days[i].values;
        weather.forecast.push({
            day: dayName(new Date(days[i].time)),
            high: Math.round(v.temperatureApparentMax),
            low: Math.round(v.temperatureApparentMin),
            icon: conditionForCode(v.weatherCodeMax).icon,
        });
    }

    return weather;
}

// Export for Node-based tests; ignored in the browser (no `module` global).
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        getWeather,
        conditionForCode,
        pickIcon,
        dayName,
        WEATHER_CODE_MAP,
        UNKNOWN_CONDITION,
    };
}
