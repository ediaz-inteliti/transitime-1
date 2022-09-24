<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%-- Shows real-time schedule adherence, for all vehicles, in a map.  --%>    
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@page import="org.transitclock.web.WebConfigParams"%>

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<%@include file="/template/includes.jsp" %>
<title><fmt:message key="div.ScheduleAdherenceMap" /></title>

  <!-- So that get proper sized map on iOS mobile device -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  
  <link rel="stylesheet" href="css/mapUi.css" />
  <link rel="stylesheet" href="https://cdn.leafletjs.com/leaflet-0.7.3/leaflet.css" />
  <script src="https://cdn.leafletjs.com/leaflet-0.7.3/leaflet.js"></script>
    <script type="text/javascript" src="//leaflet.github.io/Leaflet.label/leaflet.label.js"></script>
  <link rel="stylesheet" href="//leaflet.github.io/Leaflet.label/leaflet.label.css" />
    <script src="javascript/leafletRotatedMarker.js"></script>
  <script src="javascript/mapUiOptions.js"></script>

<style>
html, body, #map { 
	height: 100%; width: 100%; padding: 0px; margin: 0px;
}
.modal {
    position: absolute; /* Stay in place */
    z-index: 100000; /* Sit on top */
    padding-top: 10px; /* Location of the box */
    padding-left: 10px; /* Location of the box */
    left: 50px;
    top: 25px;
    width: 250px; /* Full width */
    height: 310px; /* Full height */
    overflow: auto; /* Enable scroll if needed */
    background: white;
}

.circle_early {
  width:20px;
  height: 20px;
  border-radius: 50%;
  background-color: #E84D5F;
}

.circle_ontime {
  width:20px;
  height: 20px;
  border-radius: 50%;
  background-color: #6FD656;
}

.circle_late {
  width:20px;
  height: 20px;
  border-radius: 50%;
  background-color: #F0DB56;
}

.bus {
   width:20px; /*width of your image*/
   height:20px; /*height of your image*/
   background-image:url('images/bus-24.png');
   margin:0; /* If you want no margin */
   padding:0; /*if your want to padding */
}
</style>

<script>
var earlyTime = 60000;  // 30 seconds
var lateTime = -180000; // 3 minutes
var showOnlyPredictedVehicles = false;
var routeOptions = {
		color: '#0080FF',
		weight: 1,
		opacity: 1.0,
		clickable: false
	};

var vehiclePopupOptions = {
		offset: L.point(0,-2), 
		closeButton: false
	};

var map;

// Global so can keep track and delete all vehicles at once
var vehicleLayer;

function setEarlyAndLateTime() {
	earlyTime = document.getElementById("earlyTimeInput").value * 1000;
	lateTime = document.getElementById("lateTimeInput").value * -1000;
}

function onClickShowOnlyPredictedVehicles() {
	  var checkBox = document.getElementById("showOnlyPredictedVehicles");
	  if (checkBox.checked == true){
		  showOnlyPredictedVehicles = true;
		  getAndProcessSchAdhData();
	  } else {
		  showOnlyPredictedVehicles = false;
		  getAndProcessSchAdhData();
	  }
	}

/** 
 * Returns content for vehicle popup window. For showing vehicle ID and 
 * schedule adherence.
 */
function getVehiclePopupContent(vehicle) {
	var vehicleName = (vehicle.vehicleName == '' || vehicle.vehicleName == 'undefined' || 
			vehicle.vehicleName === undefined) ? vehicle.id : vehicle.vehicleName;
	var content =
		"<b><fmt:message key="div.Vehicle" />:</b> " + vehicleName
		+ "<br/><b><fmt:message key="div.droute" />:</b> " + vehicle.routeName;
	if (vehicle.headsign)
		content += "<br/><b><fmt:message key="div.dto" />:</b> " + vehicle.headsign;
	if (vehicle.schAdhStr)
		content += "<br/><b><fmt:message key="div.dschadh" />:</b> " + vehicle.schAdhStr;
	if (vehicle.block)
		content += "<br/><b><fmt:message key="div.dblock" />:</b> " + vehicle.block;
	if (vehicle.driver)
		content += "<br/><b><fmt:message key="div.ddriver" />:</b> " + vehicle.driver;
	
	return content;
}

/**
 * Reads in and processes schedule adherence data
 */
function getAndProcessSchAdhData() {
	// Do API call to get schedule adherence data
	$.getJSON(apiUrlPrefix + "/command/vehiclesDetails?onlyAssigned=false",
			// Process data
			function(jsonData) {
				var newVehicleLayer = L.featureGroup();
				
				// Add new vehicles
				var len = jsonData.vehicles.length;
				while (len--) {
					var vehicle = jsonData.vehicles[len];
					if(showOnlyPredictedVehicles) {
						if(!vehicle.schAdh) {
							continue;
						}
					}
					
					
					// If no schedule adherence info for vehicle skip it
					//if (!vehicle.schAdh)
					//	continue;

					// Use different color for rim of circle depending on
					// direction. This way can kind of see which direction
					// vehicle is going in without needing an obtrusive
					// arrow or such.
					var directionColor = '#0a0';
					if (vehicle.direction == "1")
						directionColor = '#00f';
					
					// For determining gradiation of how early/late a vehicle is
					
					var maxEarly = 360000;  // 6 minutes
				    var maxLate = -1800000;  // 30 minutes
				    var msecPerRadiusPixels = 33000;
				    
					// Determine radius and color for vehicle depending on how early/late it is
					var radius;
					var fillColor;
					var fillOpacity;
					if (vehicle.schAdh < lateTime) {
						// Vehicle is late
						radius = 10 - (Math.max(maxLate, vehicle.schAdh) - lateTime)/msecPerRadiusPixels;
						fillColor = '#F0DB56';
						fillOpacity = 1.0;
						//fillColor = '#E6D83E';
						//fillOpacity = 0.5;
					} else if (vehicle.schAdh > earlyTime) { 
						// Vehicle is early. Since early is worse make radius 
						// of larger by using msecPerRadiusPixels/2
						radius = 10 + (Math.min(maxEarly, vehicle.schAdh) - earlyTime)/(msecPerRadiusPixels/2);
						fillColor = '#E84D5F';
						fillOpacity = 1.0;
						//fillColor = '#E34B71';
						//fillOpacity = 0.5;
					} else if (!vehicle.schAdh) {
						
					} else {
						// Vehicle is ontime
						radius = 10;
						fillColor = '#6FD656';
						fillOpacity = 1.0;
						//fillColor = '#37E627'; 
						//fillOpacity = 0.5;
					}
					
					// Specify options on how circle is be drawn. Depends
					// on how early/late a vehicle is
					var vehicleMarkerOptions = {
						// Specify look of the rim of the circle
					    color: directionColor,
					    weight: 1,
					    opacity: 1.0,

					    // Set size and color of circle depending on how
					    // early or late the vehicle is
					    radius: radius,
					    fillColor: fillColor,					    
					    fillOpacity: fillOpacity,
					};
					
					var vehicleName = (vehicle.vehicleName == '' 
							|| vehicle.vehicleName == 'undefined' 
							|| vehicle.vehicleName === undefined) ? vehicle.id : vehicle.vehicleName;
					//if (vehicle.schAdhStr)
						//vehicleName += " " + vehicle.schAdhStr;
					
					// Create circle for vehicle showing schedule adherence
					if(!vehicle.schAdh) {
						var vehicleMarker = L.marker([vehicle.loc.lat, vehicle.loc.lon],
								"")
								.setIcon(getIconForVehicle(vehicle))
								.bindLabel(vehicleName, {noHide: true, className: "my-label", offset: [12, -14] });
								//.addTo(map);
						newVehicleLayer.addLayer(vehicleMarker);
					} else {
						var vehicleMarker = 
							L.circleMarker([vehicle.loc.lat, vehicle.loc.lon], 
									vehicleMarkerOptions).bindLabel(vehicleName, {noHide: true, className: "my-label", offset: [12, -14] });
						newVehicleLayer.addLayer(vehicleMarker);
					}
					
					// Store vehicle data obtained via AJAX with stopMarker so it can be used in popup
					vehicleMarker.vehicle = vehicle;
					
					vehicleName = (vehicle.vehicleName == '' || vehicle.vehicleName == 'undefined' || 
							vehicle.vehicleName === undefined) ? vehicle.id : vehicle.vehicleName;
					// Create popup window for vehicle when clicked on
					vehicleMarker.on('click', function(e) {
						var content = getVehiclePopupContent(this.vehicle);
						var latlng = L.latLng(this.vehicle.loc.lat,
								this.vehicle.loc.lon);
						// Create popup and associate it with the vehicleMarker
						// so can later update the content.
						this.popup = L.popup(vehiclePopupOptions, this)
							.setLatLng(latlng)
							.setContent(content).openOn(map);
					});	

				} // End of while loop
				
				// Remove old vehicles
				if (vehicleLayer) {
					map.removeLayer(vehicleLayer);
				}
				
				// Add all the vehicles at once
				newVehicleLayer.addTo(map);
				
				// Remember the vehicle layer so can remove all the old 
				// vehicles next time updating the map
				vehicleLayer = newVehicleLayer;
			});
}

/**
 * Determines which icon to use to represent vehicle, such as a streetcar icon,
 * a bus icon, or an icon to represent a layover.
 */
 function getIconForVehicle(vehicleData) {
	// Determine which icon to use. Vehicles types defined per route
	// as indicated in the GTFS spec at https://developers.google.com/transit/gtfs/reference#routes_fields
	var vehicleIcon = busIcon;
	if (vehicleData.vehicleType == "0")
		vehicleIcon = streetcarIcon;
	else if (vehicleData.vehicleType == "1")
		vehicleIcon = subwayIcon;
	else if (vehicleData.vehicleType == "2")
		vehicleIcon = railIcon;
	else if (vehicleData.vehicleType == "4")
		vehicleIcon = ferryIcon;

	// Indicate layovers specially
	/*
	if (vehicleData.layover)
		vehicleIcon = layoverIcon;
	*/
	
	// Return the result
	return vehicleIcon;
}

/**
 * Reads in route data obtained via AJAX and draws route on map.
 */
function routeConfigCallback(routeData, status) {
	// So can make sure routes are drawn below the stops
	var routeFeatureGroup = L.featureGroup();
	
	// For each route
	for (var r=0; r<routeData.routes.length; ++r) {
		// Draw the paths for the route
		var route = routeData.routes[r];
		for (var i=0; i<route.shape.length; ++i) {
			var shape = route.shape[i];
			var latLngs = [];		
			for (var j=0; j<shape.loc.length; ++j) {
				var loc = shape.loc[j];			
				latLngs.push(L.latLng(loc.lat, loc.lon));
			}
			var polyline = L.polyline(latLngs, routeOptions);
			routeFeatureGroup.addLayer(polyline);
		}	
	}
	
	// Add all of the paths and stops to the map at once via the FeatureGroup
	routeFeatureGroup.addTo(map);

	// It can happen that vehicles get drawn before the route paths.
	// In this case need call bringToBack() on the paths so that
	// the vehicles will be drawn on top.
	// Note: bringToBack() must be called after map is first specified 
	// via fitBounds() or other such method.
	routeFeatureGroup.bringToBack();
}

/**
 * Create map and zoom to extent of agency
 */
function createMap(mapTileUrl, mapTileCopyright) {
	// Create map. 
	map = L.map('map');
	L.control.scale({metric: false}).addTo(map);
	
	L.tileLayer(mapTileUrl, {
		// Specifying a shorter version of attribution. Original really too long.
	    //attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery � <a href="http://mapbox.com">Mapbox</a>',
	    attribution: '&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> &amp; <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery �<%= WebConfigParams.getMapTileCopyright() %>',
	    maxZoom: 19
	}).addTo(map);

	// Set the CLIP_PADDING to a higher value so that when user pans on map
	// the route path doesn't need to be redrawn. Note: leaflet documentation
	// says that this could decrease drawing performance. But hey, it looks
	// better.
	L.Path.CLIP_PADDING = 0.8;
		
	// Set map bounds to the agency extent
	$.getJSON(apiUrlPrefix + "/command/agencyGroup", 
			function(agencies) {
		        // Fit the map initially to the agency
				var e = agencies.agency[0].extent;
				map.fitBounds([[e.minLat, e.minLon], [e.maxLat, e.maxLon]]);
			});	
	
	// Get route config data and draw all routes
	$.getJSON(apiUrlPrefix + "/command/routesDetails", routeConfigCallback);

	// Start showing schedule adherence data and update every 10 seconds.
	// Updating every is more than is truly useful since won't get significant
	// change every 10 seconds, but it shows that the map is live and is
	// really cool.
	getAndProcessSchAdhData();
	setInterval(getAndProcessSchAdhData, 10000);
}

/**
 * When page finishes loading then create map
 */
$( document ).ready(function() {
	createMap('<%= WebConfigParams.getMapTileUrl() %>', 
			'<%= WebConfigParams.getMapTileCopyright() %>');
});

</script>

</head>
<body>
<div id="map">
<div class="modal">
<label for="earlyTimeInput">Tolerancja wcześniej(w sekundach):</label>
<input name="earlyTimeInput" id="earlyTimeInput" value="60">
<label for="lateTimeInput">Tolerancja później(w sekundach):</label>
<input name="lateTimeInput" id="lateTimeInput" value="180">
<button onclick="setEarlyAndLateTime()" style="margin-top: 10px;">Odśwież</button>
<div style="margin-top: 10px;"></div>
LEGENDA:
<div style="display: flex; margin-top: 10px;"><div class="circle_early"></div>- wcześniej</div>
<div style="display: flex; margin-top: 10px;"><div class="circle_ontime"></div> - na czas</div>
<div style="display: flex; margin-top: 10px;"><div class="circle_late"></div> - później</div>
<div style="display: flex; margin-top: 10px;"><div class="bus"></div> - brak informacji</div>
<div style="margin-top: 10px;"></div>
<input type="checkbox" id="showOnlyPredictedVehicles" name="showOnlyPredictedVehicles" value="showOnlyPredictedVehicles" onclick="onClickShowOnlyPredictedVehicles()">
<label for="showOnlyPredictedVehicles"> Ukryj nieprzypisane</label>
</div>
</div>

</body>
</html>