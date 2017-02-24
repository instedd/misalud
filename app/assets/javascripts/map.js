$(function() {
  var clinics = gon.clinics;
  if ($('#clinics-map').size() == 0) return;

  // Setup map
  var map = L.map('clinics-map', {sleepNote: false, sleepOpacity: 1}).setView([40.7128, -74.0059], 13);
  L.tileLayer('http://korona.geog.uni-heidelberg.de/tiles/roadsg/x={x}&y={y}&z={z}', {
      attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);

  // Linearly scale size based on times selected
  var selectedCounts = _.map(clinics, "selected_times");
  var maxSelected = _.max(selectedCounts);
  var minSelected = _.min(selectedCounts);
  const MAX_SIZE = 20;
  const MIN_SIZE = 5;
  var sizeScaleFn = function(clinic) {
    return (clinic.selected_times - minSelected) * (MAX_SIZE - MIN_SIZE) / (maxSelected - minSelected) + MIN_SIZE;
  };

  // HSV scale from 0 (red) to 120 (green) based on score
  const MIN_HUE = 0 / 360;
  const MAX_HUE = 120 / 360;
  const MIN_SCORE = 1;
  const MAX_SCORE = 5;
  const SATURATION = 1;
  const VALUE = 0.7;
  var colorScaleFn = function(clinic) {
    if (clinic.rated_times == 0) {
      return "#333333";
    } else {
      var hue = (clinic.avg_rating - MIN_SCORE) * (MAX_HUE - MIN_HUE) / (MAX_SCORE - MIN_SCORE) + MIN_HUE;
      var rgb = hsvToRgb(hue, SATURATION, VALUE);
      return rgbToHex(rgb[0], rgb[1], rgb[2]);
    }
  };

  // Popup template function
  var popupFn = _.template("\
    <b><%= clinic.name || clinic.short_name %></b>\
    <p>\
      <span>Visited: <%= clinic.selected_times %> times</span><br/>\
      <span>Rated: <%= clinic.rated_times %> times</span><br/>\
      <span>Avg rating: <%= clinic.rated_times > 0 ? _.round(clinic.avg_rating, 2) : 'N/A'%></span><br/>\
    </p> \
  ", {'variable': 'clinic'});

  // Draw markers
  var markers = _.map(gon.clinics, function(clinic) {
    var opts = {
      radius: sizeScaleFn(clinic),
      color: colorScaleFn(clinic),
      stroke: false,
      fillOpacity: 0.9
    };
    var text = popupFn(clinic);

    return L.circleMarker([clinic.latitude, clinic.longitude], opts)
            .bindPopup(text);
  });

  var markersLayer = L.featureGroup(markers).addTo(map);
  map.fitBounds(markersLayer.getBounds());
});
