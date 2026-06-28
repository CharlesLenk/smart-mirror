(function($) {
    'use strict';

    const weatherCodeMap = new Map([
        [1000, "CLEAR_DAY"],
        [1100, "CLEAR_DAY"],
        [1101, "PARTLY_CLOUDY_DAY"],
        [1102, "CLOUDY"],
        [1001, "CLOUDY"],
        [4200, "RAIN"],
        [4001, "RAIN"]
      ]);

    function getDay(date) {
        let days =["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[date.getUTCDay()];
    }

    function toTitleCase(str) {
        str = str.toLowerCase().replace('day', '').split('_');
        for (var i = 0; i < str.length; i++) {
            str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
        }
        return str.join(' ');
    }

    $.extend({
        simpleWeather: function(options){
            options = $.extend({
                location: '',
                unit: 'f',
                apiKey: '',
                success: function(weather){},
                error: function(message){}
            }, options);

            let weatherUrl = "https://api.tomorrow.io/v4/weather/realtime?location=" + options.location + "&units=imperial&apikey=" + options.apiKey;
            let forcastUrl = "https://api.tomorrow.io/v4/weather/forecast?location=" + options.location + "&timesteps=1d&units=imperial&apikey=" + options.apiKey;
            let weather = {};

            $.ajax({
                type: 'GET',
                url: weatherUrl,
                dataType: 'json',
                success: function(result) {
                    if (result !== null) {
                        let compass = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N'];

                        let weatherIconName = weatherCodeMap.get(result.data.values.weatherCode);
                        weather.temp = Math.round(result.data.values.temperatureApparent);
                        weather.currently = toTitleCase(weatherIconName);

                        if (new Date(result.data.values.sunSetTime) < Date.now()) {
                            weather.icon = weatherIconName.replace("DAY", "NIGHT")
                        } else {
                            weather.icon = weatherIconName
                        };

                        weather.units = {
                            temp: options.unit.toUpperCase(),
                            distance: options.unit === "f" ? "mi" : "km",
                            speed: options.unit === "f" ? "mph" : "m/s",
                        };

                        weather.wind = {
                            direction: compass[Math.round(result.data.values.windDirection / 22.5)],
                            speed: Math.round(result.data.values.windSpeed)
                        };
                    } else {
                        options.error('There was a problem retrieving the latest weather information.');
                    }
                },
                error: function (error) {
                    console.error(error);
                    options.error('There was a problem retrieving the latest weather information.');
                }
            });
            $.ajax({
                type: 'GET',
                url: forcastUrl,
                dataType: 'json',
                success: function(result) {
                    if (result !== null) {
                        weather.high = Math.round(result.timelines.daily[0].values.temperatureApparentMax);
                        weather.low = Math.round(result.timelines.daily[0].values.temperatureApparentMin);
                        weather.forecast = [];
                        for (var i = 1; i < result.timelines.daily.length; i++) {
                            let forecast = {};
                            forecast.high = Math.round(result.timelines.daily[i].values.temperatureApparentMax);
                            forecast.low = Math.round(result.timelines.daily[i].values.temperatureApparentMin);
                            forecast.day = getDay(new Date(result.timelines.daily[i].time));
                            forecast.icon = weatherCodeMap.get(result.timelines.daily[i].values.weatherCodeMax);
                            weather.forecast.push(forecast);
                        }

                        options.success(weather);
                    } else {
                        options.error('There was a problem retrieving the latest weather information.');
                    }
                },
                error: function (error) {
                    console.error(error);
                    options.error('There was a problem retrieving the latest weather information.');
                }
            });
            return this;
        }
    });
})(jQuery);
