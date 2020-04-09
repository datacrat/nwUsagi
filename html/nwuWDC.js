/*
 * nwuWDC.js
 *
 * (c) 2020 datacrat
 */

(function () {

    var urlParam = location.search.substring(1);
    var param, paramArray, device;
    var tableSchema;
    var dfrSchema = new $.Deferred;

    $(document).ready(function () {
	if (!urlParam) {
	    $('#_main').replaceWith('<p>ERROR: "device" parameter is not found.</p>');
	    return;
	}
	else {
	    param = urlParam.split('&');
	    paramArray = [];
	    for (i = 0; i < param.length; i++) {
                var paramItem = param[i].split('=');
		paramArray[paramItem[0]] = paramItem[1];
            }
	    if (!paramArray.device) {
                $('#_main').replaceWith('<p>ERROR: "device" parameter is not found.</p>');
                device = "_NONE_";
            } else {
                device = paramArray.device;
            }
	}
    });

    function getSchema() {
	$.ajax({
	    url: "/nwuapi/v1/wdc/schema",
	    data: JSON.stringify( {"device": device } ),
	    type: "POST",
	    dataType: "json"
	})
	    .done(function(resp) {
		tableSchema = resp;
		dfrSchema.resolve();
	    })
	    .fail(function() {
	    })
	    .always(function() {
	    })
    }

    function showSchema() {
	var table = '<table class="table table-xs">';
	table += '<tr><td>Device</td><td>' + tableSchema.alias + '</td></tr>';
	table += '<tr><td>Columns</td>';
	table += '<td>';
	table += '<table class="table table-striped table-xs">';
	tableSchema.columns.forEach(function(c) {
	    var typeStr;
	    switch (c.dataType) {
	    case 0: typeStr = "tableau.dataTypeEnum.bool";     break;
	    case 1: typeStr = "tableau.dataTypeEnum.date";     break;
	    case 2: typeStr = "tableau.dataTypeEnum.datetime"; break;
	    case 3: typeStr = "tableau.dataTypeEnum.float";    break;
	    case 4: typeStr = "tableau.dataTypeEnum.geometry"; break;
	    case 5: typeStr = "tableau.dataTypeEnum.int";      break;
	    case 6: typeStr = "tableau.dataTypeEnum.string";   break;
	    default: 
	    }
	    table += '<tr><td>' + c.id + '</td><td>' + c.alias + '</td><td>' + typeStr +'</td><tr>';
	});
	table += '</table>';
	$('#_main').append(table);
    }

    function showSubmitButton() {
	$('#_main').append('<button type=\"button\" id=\"submitButton\" class=\"btn btn-success\" style=\"margin: 10px;\">Pull Data</button>');
    }

    //------------- Tableau WDC code -------------//
    var myConnector = tableau.makeConnector();

    myConnector.init = function(initCallback) {
	if (tableau.phase == tableau.phaseEnum.interactivePhase) {
	    getSchema();
	    dfrSchema.promise().then(function() {
		showSchema();
		showSubmitButton();
		$("#submitButton").click(function () {
		    tableau.connectionName = 'nwUsagi WDC (' + tableSchema.alias + ')';
		    tableau.submit();
		});
	    });
	}
	else if (tableau.phase == tableau.phaseEnum.gatherDataPhase) {
	    getSchema();
	}
	initCallback();
    };

    myConnector.getSchema = function (schemaCallback) {
	dfrSchema.promise().then(function() {
            var cols = [];
            tableSchema.columns.forEach(function(c) {
		var _c = {};
		_c.id = c.id;
		_c.alias = c.alias;
		switch (c.dataType) {
		case 0: _c.dataType = tableau.dataTypeEnum.bool; break;
		case 1: _c.dataType = tableau.dataTypeEnum.date; break;
		case 2: _c.dataType = tableau.dataTypeEnum.datetime; break;
		case 3: _c.dataType = tableau.dataTypeEnum.float; break;
		case 4: _c.dataType = tableau.dataTypeEnum.geometry; break;
		case 5: _c.dataType = tableau.dataTypeEnum.int; break;
		case 6: _c.dataType = tableau.dataTypeEnum.string; break;
		default: 
		}
		cols.push(_c);
	    });
            var ts = {};
            ts.id = tableSchema.id;
            ts.alias = tableSchema.alias;
            ts.columns = cols;
            schemaCallback([ts]);
	});
    };

    myConnector.getData = function(table, doneCallback) {
	$.post(
	    "/nwuapi/v1/wdc/data",
	    JSON.stringify( {"device": device } ),
	    function(resp) {
		var r = resp.data, tableData = [];
		for (var i = 0, len = r.length; i < len; i++) {
		    tableData.push(r[i]);
		}
		table.appendRows(tableData);
		doneCallback();
	    },
	    "json"
	);
    };

    tableau.registerConnector(myConnector);

})();

/* bottom of file */
