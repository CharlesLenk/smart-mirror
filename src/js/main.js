'use strict';

/*
 * Orchestration: clock and periodic weather refresh with offline caching.
 *
 * Depends on globals from config.js: latitude, longitude, tomorrowIoApiKey.
 */

const WEATHER_REFRESH_MS = 10 * 60 * 1000;     // 10 minutes
const RELOAD_INTERVAL_MS = 24 * 60 * 60 * 1000; // reload once a day
const CACHE_KEY = 'smartmirror.weather';

// Surface unexpected errors instead of freezing on a silent blank screen.
function reportError(detail) {
    console.error('Unhandled error', detail);
    const status = document.getElementById('status');
    if (status) {
        status.textContent = 'Display error';
    }
}
window.addEventListener('error', (event) => reportError(event.error || event.message));
window.addEventListener('unhandledrejection', (event) => reportError(event.reason));

document.addEventListener('DOMContentLoaded', () => {
    startClock();

    refreshWeather();
    setInterval(refreshWeather, WEATHER_REFRESH_MS);

    // Periodically reload to shed any memory growth over a long uptime.
    setTimeout(() => location.reload(), RELOAD_INTERVAL_MS);
});

function updateDate() {
    const now = new Date();
    document.getElementById('date').textContent =
        new Intl.DateTimeFormat('en', { weekday: 'long', month: 'long', day: 'numeric' }).format(now);
    document.getElementById('time').textContent =
        new Intl.DateTimeFormat('en', { hour: 'numeric', minute: 'numeric', hour12: true }).format(now);
}

// Re-align to the minute on every tick. The displayed minute is never stale, and prevents clock drift
function startClock() {
    updateDate();
    const msToNextMinute = 60000 - (Date.now() % 60000);
    setTimeout(startClock, msToNextMinute);
}

async function refreshWeather() {
    try {
        const weather = await getWeather(latitude, longitude, tomorrowIoApiKey);
        cacheWeather(weather);
        renderWeather(weather);
        setStatus('');
    } catch (error) {
        console.error(error);
        const cached = loadCachedWeather();
        if (cached) {
            renderWeather(cached.weather);
            setStatus('Weather get failed; Data from ' + formatAge(cached.savedAt));
        } else {
            renderWeatherError('Weather unavailable');
        }
    }
}

function cacheWeather(weather) {
    try {
        localStorage.setItem(CACHE_KEY, JSON.stringify({ savedAt: Date.now(), weather }));
    } catch (error) {
        console.error('Could not cache weather', error);
    }
}

function loadCachedWeather() {
    try {
        const raw = localStorage.getItem(CACHE_KEY);
        return raw ? JSON.parse(raw) : null;
    } catch (error) {
        console.error('Could not read cached weather', error);
        return null;
    }
}

function formatAge(ms) {
    const minutes = getMinutesSince(ms);
    if (minutes < 60) return minutes + ' minute' + (minutes === 1 ? '' : 's') + ' ago';
    const hours = Math.round(minutes / 60);
    if (hours < 24) return hours + ' hour' + (hours === 1 ? '' : 's') + ' ago';
    const days = Math.round(hours / 24);
    return days + ' day' + (days === 1 ? '' : 's') + ' ago';
}

function setStatus(text) {
    document.getElementById('status').textContent = text;
}
