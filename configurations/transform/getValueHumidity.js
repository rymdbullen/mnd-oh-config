(function(i) {
    var relative_humidity = JSON.parse(i).current_observation.relative_humidity;
    return relative_humidity.replace("%","");
})(input)
