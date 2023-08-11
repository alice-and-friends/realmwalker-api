function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Scrape
csv='';
while ($('.loclistitem-hold').size()) {
    console.log($('.loclistitem-hold').size())
    $('.loclistitem-hold').first().click();
    await timeout(500);
    name = $('#infoboxtitle').text()

    $('.fa-info-circle').first().click();
    await timeout(500);
    content =  $('.content').first().text() + ';';
    ext_id = content.match(/Location ID: [0-9]+/)[0].split(': ')[1];
    coords = content.match(/[0-9]{1,2}\.[0-9]{6}/g)
    lat = coords[0]
    lon = coords[1]
    if (content.match(/Raid/)) {
        type = 'special'
    } else if (content.match(/Gym/)) {
        type = 'dungeon'
    } else {
        type = 'npc'
    }
    if (ext_id && lat && lon && type && name) {
        csv += `${ext_id}, ${lat}, ${lon}, ${type}, ${name}` + "\n"
    } else {
        console.warn('Missing info', ext_id, lat, lon, type, name)
    }
    $('.closeIcon').first().click();
    await timeout(100);
    $('#infoboxclosebtn').click();
    await timeout(100);
    $('.loclistitem-hold').first().remove();
    await timeout(100);
}
console.log(csv)

// Save as file
var newDate = new Date();
filename = 'scrape-'+parseInt(newDate.getFullYear()+1)+'-'+newDate.getMonth()+'-'+newDate.getDate()+'-'+newDate.getHours()+newDate.getMinutes()+newDate.getSeconds()+'.csv'
var file = new Blob([csv], {type: type});
if (window.navigator.msSaveOrOpenBlob) // IE10+
    window.navigator.msSaveOrOpenBlob(file, filename);
else { // Others
    var a = document.createElement("a"),
        url = URL.createObjectURL(file);
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    setTimeout(function() {
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    }, 0);
}

// https://www.pogomap.info/location/59,909169/10,716476/12

// https://docs.google.com/spreadsheets/d/1KzzcMVQDlN-VLJyiarvP0vsP2e8p7pNMUFpqV8SluC8/edit#gid=2014040112
