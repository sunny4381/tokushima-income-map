$ ->
  loadCsv = (callback) ->
    $.ajax
      url: 'data.csv'
      async: false
      beforeSend: (xhr) =>
        xhr.overrideMimeType('text/plain; charset=UTF-8')
      success: (data) =>
        callback($.csv.toArrays(data))
      error: (xhr, status, error) =>
        alert("data loading error: #{status}")

  mergeCsv = (geojson, csv) ->
    data = {}
    for row, i in csv
      continue if !row[0] || row[0] == '市町村'
      data[row[0]] =
        '市町村': row[0]
        '総生産額': parseInt(row[1].replace(',', ''), 10)
        '経済成長率': row[2]
        '第１次産業': parseInt(row[3].replace(',', ''))
        '第２次産業': parseInt(row[4].replace(',', ''))
        '第３次産業': parseInt(row[5].replace(',', ''))
        '輸入品に課される税・関税': parseInt(row[6].replace(',', ''))
        '総資本形成に係る消費税': parseInt(row[7].replace(',', ''))
        '市町村民所得': parseInt(row[8].replace(',', ''))
        '面積': parseFloat(row[9].replace(',', ''))
        '人口': parseInt(row[10].replace(',', ''))
        '1人当たり市町村民所得_H23': parseInt(row[11].replace(',', ''))
        '1人当たり市町村民所得_H24': parseInt(row[12].replace(',', ''))
    geojson.features.forEach((feature) ->
      division = feature.properties.N03_004
      return unless data[division]
      feature.properties.data = data[division])

  style = (feature) ->
    data = feature.getProperty('data')
    income = data['1人当たり市町村民所得_H24']
    color = if income > 3000
      'darkred'
    else if income > 2500
      'orangered'
    else if income > 2000
      'orange'
    else if income > 1750
      'gold'
    else
      'black'
    ret =
      strokeWeight: 1
      strokeColor: '#555555'
      zIndex: 4
      fillColor: color
      fillOpacity: 0.5
      visible: true
    ret

  initializeMap = () ->
    mapOptions =
      center: new google.maps.LatLng(33.9, 134.2)
      zoom: 10
      mapTypeId: google.maps.MapTypeId.ROADMAP
    map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
    $.getJSON('tokushima.geojson', (geojson) ->
      loadCsv((csv) ->
        mergeCsv(geojson, csv)
        map.data.addGeoJson(geojson)
        map.data.setStyle(style)))
    map.data.addListener('mouseover', (event) ->
      data = event.feature.getProperty('data')
      html = $.tmpl($("#info-box-template").html(), { data: data })
      $('#info-box').html(html).show()
      map.data.revertStyle()
      map.data.overrideStyle(event.feature, {strokeWeight: 8}))
    map.data.addListener('mouseout', (event) ->
      $('#info-box').hide()
      map.data.revertStyle())

  initializeMap()

window.formatNumber = (value) ->
  value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
