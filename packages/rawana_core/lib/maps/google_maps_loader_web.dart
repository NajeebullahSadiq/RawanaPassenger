import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Injects the Maps JavaScript API using a browser-restricted API key from `.env`.
Future<void> ensureGoogleMapsScriptLoaded(String apiKey) async {
  if (apiKey.isEmpty) return;

  _installRouteMapHelpers();

  final existing =
      html.document.querySelector('script[src*="maps.googleapis.com/maps/api/js"]');
  if (existing != null) return;

  final completer = Completer<void>();
  final callbackName = 'rawanaMapsInit_${DateTime.now().millisecondsSinceEpoch}';

  js.context[callbackName] = () {
    if (!completer.isCompleted) completer.complete();
    js.context[callbackName] = null;
  };

  final script = html.ScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=$apiKey&language=en&region=AF&loading=async&libraries=geometry&callback=$callbackName'
    ..async = true;
  script.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        'Failed to load Google Maps JavaScript API. '
        'Enable the Maps JavaScript API on GOOGLE_MAPS_WEB_API_KEY and allow '
        'http://localhost:* referrers.',
      );
    }
  });
  html.document.head!.append(script);
  await completer.future;
}

void _installRouteMapHelpers() {
  js.context.callMethod('eval', [
    '''
(function() {
  window.__rawanaRouteMaps = window.__rawanaRouteMaps || {};

  function waitForMaps(cb) {
    if (window.google && window.google.maps) {
      cb();
      return;
    }
    var tries = 0;
    var timer = setInterval(function() {
      tries++;
      if (window.google && window.google.maps) {
        clearInterval(timer);
        cb();
      } else if (tries > 100) {
        clearInterval(timer);
      }
    }, 80);
  }

  function isValid(lat, lng) {
    return typeof lat === 'number' && typeof lng === 'number' &&
      isFinite(lat) && isFinite(lng) &&
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 &&
      !(Math.abs(lat) < 0.01 && Math.abs(lng) < 0.01);
  }

  function toLatLng(p) {
    if (!p) return null;
    var lat = Number(Array.isArray(p) ? p[0] : p.lat);
    var lng = Number(Array.isArray(p) ? p[1] : p.lng);
    if (!isValid(lat, lng)) return null;
    return { lat: lat, lng: lng };
  }

  function decodePolyline(encoded) {
    if (!encoded || typeof encoded !== 'string') return [];
    if (window.google && google.maps && google.maps.geometry && google.maps.geometry.encoding) {
      try {
        return google.maps.geometry.encoding.decodePath(encoded);
      } catch (e) { /* fall through */ }
    }
    var points = [];
    var index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      var shift = 0, result = 0, b;
      do {
        b = encoded.charCodeAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      var dlat = (result & 1) ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0; result = 0;
      do {
        b = encoded.charCodeAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      var dlng = (result & 1) ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      points.push({ lat: lat / 1e5, lng: lng / 1e5 });
    }
    return points;
  }

  function resolvePath(config, encoded, fallbackPath) {
    var fromPath = (fallbackPath || []).map(toLatLng).filter(Boolean);
    if (fromPath.length >= 2) return fromPath;
    var decoded = decodePolyline(encoded);
    return decoded.length >= 2 ? decoded : [];
  }

  function clearPolylines(entry) {
    (entry.polylines || []).forEach(function(line) { line.setMap(null); });
    entry.polylines = [];
  }

  function clearMarkers(entry) {
    (entry.markers || []).forEach(function(m) { m.setMap(null); });
    entry.markers = [];
  }

  function drawPolylines(map, entry, config) {
    clearPolylines(entry);
    var primary = resolvePath(config, config.encodedPolyline, config.path);
    var paths = [primary];
    var secondaryEncoded = config.encodedSecondaryPolylines || [];
    var secondaryPaths = config.secondaryPaths || [];
    for (var i = 0; i < secondaryEncoded.length; i++) {
      paths.push(resolvePath(config, secondaryEncoded[i], secondaryPaths[i] || []));
    }
    for (var j = secondaryEncoded.length; j < secondaryPaths.length; j++) {
      paths.push(resolvePath(config, '', secondaryPaths[j] || []));
    }
    paths = paths.filter(function(p) { return p && p.length >= 2; });

    var colors = [config.lineColor || '#0B5FFF'];
    var widths = [config.lineWidth || 8];
    for (var k = 1; k < paths.length; k++) {
      colors.push('#94A3B8');
      widths.push(Math.max(4, (config.lineWidth || 8) - 2));
    }

    paths.forEach(function(path, idx) {
      var line = new google.maps.Polyline({
        path: path,
        strokeColor: colors[idx] || colors[0],
        strokeWeight: widths[idx] || widths[0],
        strokeOpacity: idx === 0 ? 1 : 0.55,
        geodesic: false,
        map: map,
        zIndex: idx === 0 ? 999 : 500
      });
      entry.polylines.push(line);
    });
    var traveled = (config.traveledPath || []).map(toLatLng).filter(Boolean);
    if (traveled.length >= 2) {
      entry.polylines.push(new google.maps.Polyline({
        path: traveled,
        strokeColor: '#94A3B8',
        strokeWeight: Math.max(4, (config.lineWidth || 8) - 3),
        strokeOpacity: 0.35,
        geodesic: false,
        map: map,
        zIndex: 400
      }));
    }
    entry.primaryPath = paths[0] || [];
  }

  function vehicleSvg(kind, heading) {
    var rot = Number(heading || 0);
    var teal = kind === 'premium' ? '#1F6F6A' : '#2A9B94';
    var dark = kind === 'premium' ? '#134844' : '#1A6F6A';
    var light = kind === 'premium' ? '#3D8F89' : '#4EC4BB';
    if (kind === 'bike') {
      return '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56">' +
        '<g transform="rotate(' + rot + ' 28 28)">' +
        '<ellipse cx="28" cy="38" rx="10" ry="5" fill="rgba(0,0,0,0.18)"/>' +
        '<circle cx="28" cy="16" r="7" fill="none" stroke="#1A1F24" stroke-width="3"/>' +
        '<circle cx="28" cy="40" r="8" fill="none" stroke="#1A1F24" stroke-width="3"/>' +
        '<circle cx="28" cy="16" r="2.4" fill="' + teal + '"/>' +
        '<circle cx="28" cy="40" r="2.6" fill="' + teal + '"/>' +
        '<path d="M25 18 Q36 24 32 36 Q26 40 23 32 Q20 24 25 18 Z" fill="' + teal + '"/>' +
        '<rect x="22" y="15" width="12" height="3" rx="1.5" fill="#1A1F24"/>' +
        '</g></svg>';
    }
    var w = kind === 'xl' ? 22 : 18;
    var h = kind === 'xl' ? 34 : 30;
    return '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56">' +
      '<g transform="rotate(' + rot + ' 28 28)">' +
      '<ellipse cx="28" cy="36" rx="' + (w * 0.7) + '" ry="8" fill="rgba(0,0,0,0.18)"/>' +
      '<rect x="' + (28 - w / 2) + '" y="' + (28 - h / 2) + '" width="' + w + '" height="' + h + '" rx="' + (w * 0.34) + '" fill="' + teal + '"/>' +
      '<rect x="' + (28 - w * 0.36) + '" y="' + (28 - h * 0.16) + '" width="' + (w * 0.72) + '" height="' + (h * 0.42) + '" rx="4" fill="' + dark + '" opacity="0.55"/>' +
      '<rect x="' + (28 - w * 0.31) + '" y="' + (28 - h * 0.38) + '" width="' + (w * 0.62) + '" height="' + (h * 0.18) + '" rx="3" fill="#1B2833"/>' +
      '<rect x="' + (28 - w * 0.28) + '" y="' + (28 + h * 0.12) + '" width="' + (w * 0.56) + '" height="' + (h * 0.14) + '" rx="3" fill="#1B2833"/>' +
      '<rect x="' + (28 - w * 0.52) + '" y="' + (28 - h * 0.28) + '" width="' + (w * 0.12) + '" height="' + (h * 0.18) + '" rx="1.5" fill="#1A1F24"/>' +
      '<rect x="' + (28 + w * 0.40) + '" y="' + (28 - h * 0.28) + '" width="' + (w * 0.12) + '" height="' + (h * 0.18) + '" rx="1.5" fill="#1A1F24"/>' +
      '<circle cx="' + (28 - w * 0.22) + '" cy="' + (28 - h * 0.44) + '" r="1.6" fill="#FFF3C4"/>' +
      '<circle cx="' + (28 + w * 0.22) + '" cy="' + (28 - h * 0.44) + '" r="1.6" fill="#FFF3C4"/>' +
      '<rect x="' + (28 - w * 0.48) + '" y="' + (28 - h * 0.32) + '" width="' + (w * 0.12) + '" height="' + (h * 0.58) + '" rx="3" fill="' + light + '" opacity="0.35"/>' +
      '</g></svg>';
  }

  function vehicleIcon(kind, color, heading) {
    if (kind === 'bike' || kind === 'car' || kind === 'premium' || kind === 'xl') {
      return {
        url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(vehicleSvg(kind, heading)),
        scaledSize: new google.maps.Size(48, 48),
        anchor: new google.maps.Point(24, 24)
      };
    }
    if (kind === 'you' || kind === 'current') {
      return {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 10,
        fillColor: '#1A73E8',
        fillOpacity: 1,
        strokeColor: '#FFFFFF',
        strokeWeight: 3
      };
    }
    if (kind === 'passenger') {
      return {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 10,
        fillColor: color || '#0B5FFF',
        fillOpacity: 1,
        strokeColor: '#FFFFFF',
        strokeWeight: 2
      };
    }
    if (kind === 'pickup' || kind === 'dropoff') {
      return {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 8,
        fillColor: color || '#22C55E',
        fillOpacity: 1,
        strokeColor: '#FFFFFF',
        strokeWeight: 2
      };
    }
    return {
      path: 'M -7,-14 L 7,-14 L 9,-4 L 9,12 L 6,14 L -6,14 L -9,12 L -9,-4 Z',
      fillColor: kind === 'premium' ? '#111827' : '#FFFFFF',
      fillOpacity: 1,
      strokeColor: '#111827',
      strokeWeight: 1.2,
      scale: 1.15,
      rotation: heading || 0,
      anchor: new google.maps.Point(0, 0)
    };
  }

  function drawMarkers(map, entry, markers) {
    clearMarkers(entry);
    (markers || []).forEach(function(m) {
      var pos = toLatLng(m);
      if (!pos) return;
      if (m.kind === 'you' || m.kind === 'current') {
        entry.markers.push(new google.maps.Circle({
          center: pos,
          radius: 42,
          fillColor: '#1A73E8',
          fillOpacity: 0.18,
          strokeColor: '#1A73E8',
          strokeOpacity: 0.35,
          strokeWeight: 1,
          map: map,
          zIndex: 150
        }));
      }
      var marker = new google.maps.Marker({
        position: pos,
        map: map,
        title: m.label || '',
        icon: vehicleIcon(m.kind, m.color, m.heading),
        zIndex: m.kind === 'you' ? 1100 : (m.follow ? 1000 : 200)
      });
      entry.markers.push(marker);
    });
  }

  function followDriver(map, entry, config) {
    if (!config.navigationMode) return;
    var pos = toLatLng({ lat: config.followLat, lng: config.followLng });
    if (!pos) pos = toLatLng({ lat: config.originLat, lng: config.originLng });
    if (!pos && entry.primaryPath && entry.primaryPath.length) {
      pos = entry.primaryPath[0];
    }
    if (!pos) pos = toLatLng({ lat: config.centerLat, lng: config.centerLng });
    if (!pos) return;
    map.panTo(pos);
    var zoom = config.zoom || 17;
    if (zoom < 16) zoom = 16;
    if (zoom > 18) zoom = 18;
    map.setZoom(zoom);
    // Keep north-up. Rotating the whole map from GPS heading (or RTL
    // platform-view mirroring) made the map look inverted.
    if (typeof map.setTilt === 'function') map.setTilt(0);
    if (typeof map.setHeading === 'function') map.setHeading(0);
  }

  function recenterOnUser(map, entry, config) {
    var pos = null;
    (config.markers || []).forEach(function(m) {
      if (!pos && m.kind === 'you') pos = toLatLng(m);
    });
    if (!pos) {
      (config.markers || []).forEach(function(m) {
        if (!pos && (m.follow || m.kind === 'driver')) pos = toLatLng(m);
      });
    }
    if (!pos) {
      (config.markers || []).forEach(function(m) {
        if (!pos && m.kind === 'passenger') pos = toLatLng(m);
      });
    }
    if (!pos) pos = toLatLng({ lat: config.followLat, lng: config.followLng });
    if (!pos) pos = toLatLng({ lat: config.centerLat, lng: config.centerLng });
    if (!pos) pos = toLatLng({ lat: config.originLat, lng: config.originLng });
    if (!pos) return;
    var zoom = config.zoom || 16;
    if (zoom < 16) zoom = 16;
    if (zoom > 18) zoom = 18;
    map.panTo(pos);
    map.setZoom(zoom);
    if (typeof map.setTilt === 'function') map.setTilt(0);
    if (typeof map.setHeading === 'function') map.setHeading(0);
  }

  function fitToRoute(map, entry, config) {
    if (config.navigationMode) {
      followDriver(map, entry, config);
      return;
    }
    if (!config.fitBounds) return;
    var bounds = new google.maps.LatLngBounds();
    var hasPoint = false;
    (entry.primaryPath || []).forEach(function(p) {
      bounds.extend(p);
      hasPoint = true;
    });
    (config.markers || []).forEach(function(m) {
      var pos = toLatLng(m);
      if (pos) { bounds.extend(pos); hasPoint = true; }
    });
    if (!hasPoint) {
      var o = toLatLng({ lat: config.originLat, lng: config.originLng });
      var d = toLatLng({ lat: config.destLat, lng: config.destLng });
      if (o) { bounds.extend(o); hasPoint = true; }
      if (d) { bounds.extend(d); hasPoint = true; }
    }
    if (!hasPoint) return;

    var ne = bounds.getNorthEast();
    var sw = bounds.getSouthWest();
    var latSpan = Math.abs(ne.lat() - sw.lat());
    var lngSpan = Math.abs(ne.lng() - sw.lng());
    if (latSpan > 4 || lngSpan > 4) {
      var center = toLatLng({ lat: config.centerLat, lng: config.centerLng });
      if (center) {
        map.setCenter(center);
        map.setZoom(config.zoom || 14);
      }
      return;
    }

    map.fitBounds(bounds, 72);
    google.maps.event.addListenerOnce(map, 'idle', function() {
      if (map.getZoom() > 17) map.setZoom(17);
      if (map.getZoom() < 11) map.setZoom(11);
    });
  }

  function triggerResize(map) {
    google.maps.event.trigger(map, 'resize');
  }

  function bootMap(div, config) {
    waitForMaps(function() {
      function start() {
        if (div) {
          div.setAttribute('dir', 'ltr');
          div.style.direction = 'ltr';
          div.style.unicodeBidi = 'isolate';
        }
        if (div.offsetWidth < 4 || div.offsetHeight < 4) {
          requestAnimationFrame(start);
          return;
        }
        var center = toLatLng({ lat: config.centerLat, lng: config.centerLng }) ||
          { lat: 34.5553, lng: 69.2075 };
        var map = new google.maps.Map(div, {
          center: center,
          zoom: config.zoom || 14,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
          zoomControl: true,
          gestureHandling: 'greedy'
        });
        var entry = { map: map, polylines: [], markers: [], primaryPath: [] };
        window.__rawanaRouteMaps[config.id] = entry;
        drawPolylines(map, entry, config);
        drawMarkers(map, entry, config.markers);
        fitToRoute(map, entry, config);

        triggerResize(map);
        google.maps.event.addListenerOnce(map, 'idle', function() {
          triggerResize(map);
          fitToRoute(map, entry, config);
        });
        google.maps.event.addListenerOnce(map, 'tilesloaded', function() {
          triggerResize(map);
        });

        if (window.ResizeObserver) {
          var ro = new ResizeObserver(function() {
            triggerResize(map);
          });
          ro.observe(div);
          entry.resizeObserver = ro;
        }
      }
      start();
    });
  }

  function scheduleMapRefresh(map, entry, config) {
    triggerResize(map);
    fitToRoute(map, entry, config);
    requestAnimationFrame(function() {
      triggerResize(map);
      fitToRoute(map, entry, config);
    });
    setTimeout(function() {
      triggerResize(map);
      fitToRoute(map, entry, config);
    }, 120);
    setTimeout(function() {
      triggerResize(map);
      fitToRoute(map, entry, config);
    }, 400);
  }

  window.__rawanaRouteMapInit = function(div, config) {
    bootMap(div, config);
  };

  window.__rawanaRouteMapUpdate = function(id, config) {
    waitForMaps(function() {
      var entry = window.__rawanaRouteMaps[id];
      if (!entry) return;
      drawPolylines(entry.map, entry, config);
      drawMarkers(entry.map, entry, config.markers || []);
      scheduleMapRefresh(entry.map, entry, config);
    });
  };

  window.__rawanaRouteMapUpdateMarkers = function(id, markers, config) {
    waitForMaps(function() {
      var entry = window.__rawanaRouteMaps[id];
      if (!entry) return;
      drawMarkers(entry.map, entry, markers);
      if (config) scheduleMapRefresh(entry.map, entry, config);
    });
  };

  window.__rawanaRouteMapResize = function(id, config) {
    waitForMaps(function() {
      var entry = window.__rawanaRouteMaps[id];
      if (!entry) return;
      if (config) scheduleMapRefresh(entry.map, entry, config);
      else triggerResize(entry.map);
    });
  };

  window.__rawanaRouteMapFollow = function(id, config) {
    waitForMaps(function() {
      var entry = window.__rawanaRouteMaps[id];
      if (!entry) return;
      drawMarkers(entry.map, entry, config.markers || []);
      followDriver(entry.map, entry, config);
    });
  };

  window.__rawanaRouteMapRecenter = function(id, config) {
    waitForMaps(function() {
      var entry = window.__rawanaRouteMaps[id];
      if (!entry) return;
      drawMarkers(entry.map, entry, config.markers || []);
      recenterOnUser(entry.map, entry, config);
    });
  };

  window.__rawanaRouteMapDestroy = function(id) {
    var entry = window.__rawanaRouteMaps[id];
    if (!entry) return;
    clearPolylines(entry);
    clearMarkers(entry);
    if (entry.resizeObserver) entry.resizeObserver.disconnect();
    delete window.__rawanaRouteMaps[id];
  };
})();
''',
  ]);
}
