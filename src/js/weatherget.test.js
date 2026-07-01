'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

const {
    getWeather,
    conditionForCode,
    pickIcon,
    dayName,
    UNKNOWN_CONDITION,
} = require('./weatherget.js');

// --- pure helpers ---

test('conditionForCode maps a known code to its icon + name', () => {
    assert.deepEqual(conditionForCode(8000), { icon: 'THUNDER_RAIN', name: 'Thunderstorm' });
    assert.deepEqual(conditionForCode(4200), { icon: 'SHOWERS_DAY', name: 'Light Rain' });
});

test('conditionForCode falls back to UNKNOWN for unmapped codes', () => {
    assert.equal(conditionForCode(9999), UNKNOWN_CONDITION);
    assert.equal(conditionForCode(0), UNKNOWN_CONDITION);
    assert.equal(UNKNOWN_CONDITION.name, 'Unknown');
    assert.equal(UNKNOWN_CONDITION.icon, 'CLOUDY');
});

test('pickIcon swaps _DAY for _NIGHT only at night', () => {
    assert.equal(pickIcon('CLEAR_DAY', false), 'CLEAR_DAY');
    assert.equal(pickIcon('CLEAR_DAY', true), 'CLEAR_NIGHT');
    assert.equal(pickIcon('PARTLY_CLOUDY_DAY', true), 'PARTLY_CLOUDY_NIGHT');
    // Names without _DAY are unchanged.
    assert.equal(pickIcon('CLOUDY', true), 'CLOUDY');
    assert.equal(pickIcon('THUNDER_RAIN', true), 'THUNDER_RAIN');
});

test('dayName returns the 3-letter weekday', () => {
    // 2026-06-29 is a Monday.
    assert.equal(dayName(new Date('2026-06-29T12:00:00Z')), 'Mon');
});

// --- getWeather (with a mocked fetch) ---

function makeResponses({ realtimeValues, daily }) {
    const realtime = { data: { values: realtimeValues } };
    const forecast = { timelines: { daily } };
    return (url) => Promise.resolve({
        ok: true,
        json: () => Promise.resolve(url.includes('realtime') ? realtime : forecast),
    });
}

function dailyEntry(time, { codeMax, max, min, sunrise, sunset }) {
    return {
        time,
        values: {
            weatherCodeMax: codeMax,
            temperatureApparentMax: max,
            temperatureApparentMin: min,
            sunriseTime: sunrise,
            sunsetTime: sunset,
        },
    };
}

test('getWeather normalizes realtime + forecast into the weather object', async () => {
    global.fetch = makeResponses({
        realtimeValues: {
            temperatureApparent: 72.4,
            weatherCode: 8000,
            windDirection: 200, // 200 / 22.5 ≈ 9 -> SSW
            windSpeed: 11.6,
        },
        daily: [
            // Today: sunrise/sunset bracket "now" so it's daytime.
            dailyEntry(new Date().toISOString(), {
                codeMax: 1000, max: 75.2, min: 55.1,
                sunrise: new Date(Date.now() - 3600000).toISOString(),
                sunset: new Date(Date.now() + 3600000).toISOString(),
            }),
            dailyEntry('2026-06-30T12:00:00Z', { codeMax: 4200, max: 70, min: 52 }),
            dailyEntry('2026-07-01T12:00:00Z', { codeMax: 5000, max: 40, min: 30 }),
            dailyEntry('2026-07-02T12:00:00Z', { codeMax: 9999, max: 65, min: 50 }),
        ],
    });

    const w = await getWeather('47.6,-122.3', 'KEY');

    assert.equal(w.temp, 72);                  // rounded
    assert.equal(w.currently, 'Thunderstorm'); // display name, not the skycon id
    assert.equal(w.icon, 'THUNDER_RAIN');
    assert.equal(w.isNight, false);
    assert.deepEqual(w.units, { temp: 'F', speed: 'mph' });
    assert.equal(w.wind.direction, 'SSW');
    assert.equal(w.wind.speed, 12);
    assert.equal(w.high, 75);
    assert.equal(w.low, 55);

    assert.equal(w.forecast.length, 3);        // days[1..], today excluded
    assert.equal(w.forecast[0].icon, 'SHOWERS_DAY');
    assert.equal(w.forecast[1].icon, 'SNOW');
    assert.equal(w.forecast[2].icon, 'CLOUDY'); // 9999 -> unknown fallback icon
});

test('getWeather picks the night icon after sunset', async () => {
    global.fetch = makeResponses({
        realtimeValues: { temperatureApparent: 60, weatherCode: 1000, windDirection: 0, windSpeed: 0 },
        daily: [
            dailyEntry(new Date().toISOString(), {
                codeMax: 1000, max: 60, min: 50,
                // Both sunrise and sunset already in the past -> night.
                sunrise: new Date(Date.now() - 7200000).toISOString(),
                sunset: new Date(Date.now() - 3600000).toISOString(),
            }),
        ],
    });

    const w = await getWeather('47.6,-122.3', 'KEY');
    assert.equal(w.isNight, true);
    assert.equal(w.icon, 'CLEAR_NIGHT');
});

test('getWeather rejects on a non-OK response', async () => {
    global.fetch = () => Promise.resolve({ ok: false, status: 500, json: () => Promise.resolve({}) });
    await assert.rejects(getWeather('x', 'y'), /Weather request failed: 500/);
});
