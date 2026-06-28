$(document).ready(function () {
    updateDate();
    setInterval(updateDate, 15000);

    initWeather();
    updateWeather(gpsLocation, tomorrowIoApiKey);
    setInterval(function() {
        updateWeather(gpsLocation, tomorrowIoApiKey);
    }, 600000);
});

function updateDate() {
    let date = $('#date');
    date.text(Intl.DateTimeFormat('en', { weekday: 'long', month: 'long', day: 'numeric' }).format(new Date()));
    
    let time = $('#time');
    time.text(Intl.DateTimeFormat('en', { hour: `numeric`, minute: `numeric`, hour12: true }).format(new Date()));
}

