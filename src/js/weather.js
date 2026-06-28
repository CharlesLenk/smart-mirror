let skycons = new Skycons({"color": "white"});

function initWeather() {
    let html = '';
    for (var i = 0; i < 4; i++) {
        let name = "weather-row-" + i + "-";
        html += '<tr>';
        html += '<td id="' + (name + "day") + '"></td>';
        html += '<td><canvas id="' + (name + "icon-forecast") + '" width="50" height="50"></canvas></td>';
        html += '<td id="' + (name + "high") + '"></td>';
        html += '<td class="low" id="' + (name + "low") + '"></td>';
        html += '</tr>';
    }
    $("#weatherTable").html(html);
}

function updateWeather(location, apiKey) {
    $.simpleWeather({
        location: location,
        apiKey: apiKey,
        unit: 'f',
        success: function (weather) {
            $("#temperature").html(weather.temp + '&deg;' + weather.units.temp.toUpperCase());
            let html = '<div>' + weather.currently + '</div>';
            html += '<div>' + weather.wind.direction + ' ' + weather.wind.speed + ' ' + weather.units.speed + '</div>';
            html += '<div><i class="fa fa-angle-up"></i>  High ' + weather.high + ' <i class="fa fa-angle-down"></i> Low ' + weather.low + '</div>';
            $("#weatherDynamic").html(html);
            
            for (var i = 0; i < weather.forecast.length; i++) {
                let name = "weather-row-" + i + "-";
                $("#" + name + "day").text(weather.forecast[i].day);
                $("#" + name + "high").text(weather.forecast[i].high);
                $("#" + name + "low").text(weather.forecast[i].low);
                skycons.set(name + "icon-forecast", weather.forecast[i].icon);
            }
            skycons.set("weather-icon", weather.icon);
            skycons.play();
        },
        error: function (error) {
            console.error(error);
            $("#weatherDynamic").html('<p>' + error + '</p>');
        }
    });
}
