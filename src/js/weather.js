'use strict';

/*
 * Weather rendering layer. Turns a normalized weather object (from
 * weatherget.js) into DOM.
 */

const skycons = new Skycons({ color: 'white' });

// Chevrons for high and low temperature.
const chevronUp = '<svg class="chevron chevron-up" viewBox="0 0 16 16" aria-hidden="true"><path d="M2 11 L8 5 L14 11"/></svg>';
const chevronDown = '<svg class="chevron chevron-down" viewBox="0 0 16 16" aria-hidden="true"><path d="M2 5 L8 11 L14 5"/></svg>';

function buildForecastRows(count) {
    const table = document.getElementById('weatherTable');
    let html = '';
    for (let i = 0; i < count; i++) {
        const name = 'weather-row-' + i + '-';
        html += '<tr>' +
            '<td id="' + name + 'day"></td>' +
            '<td><canvas id="' + name + 'icon-forecast" width="50" height="50"></canvas></td>' +
            '<td id="' + name + 'high"></td>' +
            '<td class="low" id="' + name + 'low"></td>' +
            '</tr>';
    }
    table.innerHTML = html;
}

function renderWeather(weather) {
    document.getElementById('temperature').innerHTML =
        weather.temp + '&deg;' + weather.units.temp;

    document.getElementById('weatherDynamic').innerHTML =
        '<div>' + weather.currently + '</div>' +
        '<div>' + weather.wind.direction + ' ' + weather.wind.speed + ' ' + weather.units.speed + '</div>';

    document.getElementById('current-hi-lo').innerHTML =
        chevronUp + ' High ' + weather.high + ' ' + chevronDown + ' Low ' + weather.low;

    buildForecastRows(weather.forecast.length);
    weather.forecast.forEach((f, i) => {
        const name = 'weather-row-' + i + '-';
        document.getElementById(name + 'day').textContent = f.day;
        document.getElementById(name + 'high').textContent = f.high;
        document.getElementById(name + 'low').textContent = f.low;
        skycons.set(name + 'icon-forecast', f.icon);
    });

    skycons.set('weather-icon', weather.icon);
    skycons.play();
}

function renderWeatherError(message) {
    document.getElementById('weatherDynamic').innerHTML = '<p>' + message + '</p>';
}
