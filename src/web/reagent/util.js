/*
 * Copyright (c) 2009-2010 LabKey Corporation
 *
 * Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
 */
var ColumnSets = {
    Antigens: [ 'Name', 'Aliases', 'Description' ],
    Labels: [ 'Name', 'Aliases', 'Description' ],
    Manufacturers: [ 'Name' ],
    Reagents: [ 'AntigenId', 'LabelId', 'Clone', 'Description'/*, 'Species'*/ ],
    Lots: [ 'ReagentId', 'ManufacturerId', 'CatalogNumber', 'LotNumber', 'Description' ],
    Vials: [ 'LotId', 'OwnedBy', 'Location', 'Box', 'Row', 'Col', 'Used' ],
    Titrations: [ 'LotId', 'PerformedBy', 'ExperimentId', 'Type', 'Result', 'Description' ],
};

var srcURL = null;

function initSrcURL(schemaName, queryName)
{
    srcURL = LABKEY.ActionURL.getParameter('srcURL');
    if (!srcURL) {
        srcURL = LABKEY.ActionURL.buildURL('query', 'executeQuery.view', null, {
            schemaName: schemaName,
            'query.queryName': queryName
        });
    }
}

function navSrcURL()
{
    window.location = srcURL;
}

function save(selected, updateRowId, schemaName, queryName, values)
{
    Ext.MessageBox.wait("Saving...", "Saving...");

    var fn = LABKEY.Query.insertRows;
    if (selected || updateRowId) {
        fn = LABKEY.Query.updateRows;
    }

    fn({
        schemaName: schemaName,
        queryName: queryName,
        rowDataArray: values,
        successCallback: function (data) {
            Ext.MessageBox.updateProgress(1, "Saved.");
            Ext.MessageBox.hide();
            navSrcURL();
        },
        errorCallback: function (errorInfo) {
            Ext.MessageBox.updateProgress(1);
            Ext.MessageBox.hide();
            Ext.MessageBox.alert("Error Saving", errorInfo.exception || errorInfo.statusText);
        }
    });
}

/**
 * Initializes the FormPanel.
 * @param selected {Boolean} true when updating multiple records that have been checked on the grid.
 * @param updateRowId {Integer} The row id of the record to update.
 * @param schemaName
 * @param queryName
 */
function initForm(selected, updateRowId, schemaName, queryName)
{
    initSrcURL(schemaName, queryName);

    var columns = ColumnSets[queryName] || [];

    function createForm(data)
    {
        if (selected || updateRowId)
        {
            if (data.rows.length == 0)
            {
                Ext.fly("msgDiv").update("<span class='labkey-error'>No rows were selected to update!</span>");
                return;
            }
        }
        else
        {
            // clear out any values if we're creating an empty insert form.
            data.rows = [];
        }

        var items = [];
        for (var i = 0; i < columns.length; i++)
        {
            var column = columns[i];
            switch (column) {
                case 'Species':
                    //createSpeciesField();
                    break;
            }
        }

        function augmentItem(c)
        {
            var name = c.name;
            switch (name) {
                case 'ReagentId':
                    augmentReagentCombo(c);
                    break;

                case 'LotId':
                    augmentLotCombo(c);
                    break;

                case 'AntigenId':
                case 'LabelId':
                case 'ManufacturerId':
                    augmentCombo(c);
                    break;

                case 'OwnedBy':
                    // XXX: on update, the userid combo shows the userid value rather than the displayName
                    augmentUserCombo(c, queryName);
                    c.value = c.value || LABKEY.user.displayName;
                    break;

                case 'PerformedBy':
                    // XXX: on update, the userid combo shows the userid value rather than the displayName
                    augmentUserCombo(c, queryName);
                    break;

                case 'Clone':
                case 'CatalogNumber':
                case 'Location':
                case 'Box':
                case 'Row':
                case 'Col':
                case 'Type':
                    augmentTextCombo(c, queryName);
                    break;
            }

            return c;
        }

        var f = new LABKEY.ext.FormPanel({
            id: 'reagentForm',
            border: false,
            bodyStyle:'padding:5px 5px',
            selectRowsResults: data,
            defaults: { width: 350 },
            //items: items,
            addAllFields: true,
            lazyCreateStore: true,
            buttonAlign: 'left',
            buttons: [{
                text: 'Save',
                handler: function () {
                    var form = f.getForm();
                    if (form.isValid()) {
                        var values = f.getFormValues();
                        save(selected, updateRowId, schemaName, queryName, values);
                    }
                    else {
                        Ext.MessageBox.alert('Error saving', 'There are errors on the form.');
                    }
                }
            },{
                text: 'Cancel',
                handler: navSrcURL
            }],
            listeners : {
                applydefaults: function (fp, c) {
                    augmentItem(c);
                }
            }
        });

        f.render('formDiv');
    }

    // If not getting the selected rows, either get the update row by id or no row (id=0)
    var filters = [ ];
    if (!selected)
    {
        var filterRowId = updateRowId || 0;
        filters.push(LABKEY.Filter.create('RowId', filterRowId));
    }

    LABKEY.Query.selectRows({
        requiredVersion: 9.1,
        schemaName: schemaName,
        queryName: queryName,
        columns: columns.join(','),
        filterArray: filters,
        showRows: selected ? "selected" : "all",
        successCallback: createForm,
        errorCallback: function (errorInfo) {
            alert(errorInfo);
        }
    });
}


function augmentReagentCombo(field)
{
    field.store.columns = ['RowId', 'AntigenId/Name', 'LabelId/Name', 'Clone'].join(',');
    field.store.sort = 'AntigenId/Name,LabelId/Name,Clone';
    field.store.listeners = {
        load: function (store, records, options) {
            var len = records.length;
            for (var i = 0; i < len; i++) {
                var r = records[i];
                var display = r.data['AntigenId/Name'] + ', ' + r.data['LabelId/Name'] + ' (' + r.data['Clone'] + ')';
                r.data['ReagentDisplay'] = display;
            }
        }
    };

    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.displayField = 'ReagentDisplay';
    field.tpl = '<tpl for="."><div class="x-combo-list-item"><b>{[values["AntigenId/Name"]]}</b> {[values["LabelId/Name"]]} <i>({[values["Clone"]]})</i></div></tpl>';
}

function augmentLotCombo(field)
{
    field.store.columns = ['RowId', 'LotNumber', 'CatalogNumber', 'ManufacturerId/Name', 'ReagentId/AntigenId/Name', 'ReagentId/LabelId/Name', 'ReagentId/Clone'].join(',');
    field.store.sort = 'ReagentId/AntigenId/Name,ReagentId/LabelId/Name,ReagentId/Clone,ManufacturerId';
    field.store.listeners = {
        load: function (store, records, options) {
            var len = records.length;
            for (var i = 0; i < len; i++) {
                var r = records[i];
                var display = r.data['LotNumber'] + ': ' + r.data['ReagentId/AntigenId/Name'] + ', ' + r.data['ReagentId/LabelId/Name'] + ' (' + r.data['ReagentId/Clone'] + ') ' + r.data['ManufacturerId/Name'];
                r.data['LotDisplay'] = display;
            }
        }
    };

    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.displayField = 'LotDisplay';
    field.tpl = '<tpl for="."><div class="x-combo-list-item">{[values["LotNumber"]]}: <b>{[values["ReagentId/AntigenId/Name"]]}</b>, {[values["ReagentId/LabelId/Name"]]} <i>({[values["ReagentId/Clone"]]})</i> &nbsp;{[values["ManufacturerId/Name"]]}</div></tpl>';
}

function augmentCombo(field)
{
    field.store.columns = ['RowId', 'Name', 'Aliases', 'Description'].join(',');
    field.store.sort = 'Name';
    if (field.allowBlank && field.store.nullRecord)
        field.store.nullRecord.nullCaption = "[Keep original values]";
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    if (field.name == 'ManufacturerId')
        field.tpl = '<tpl for="."><div class="x-combo-list-item">{Name}</div></tpl>';
    else
        field.tpl = '<tpl for=".">' +
                    '<div class="x-combo-list-item" style="color:#555">' +
                    '<div style="color:#222">' +
                    '<i style="font-size:0.9em;display:block;float:right;clear:both;">{[values["Aliases"] ? values["Aliases"] : ""]}</i>' +
                    '<b>{[values["Name"] ? values["Name"] : ""]}</b>' +
                    '</div>' +
                    '{[values["Description"] ? values["Description"] : ""]}' +
                    '</div>' +
                    '</tpl>';
}

function augmentTextCombo(field, queryName)
{
    var h = Ext.util.Format.htmlEncode;
    var table_column = h(queryName + "." + field.name);

    field.xtype = 'combo';
    field.fieldLabel = field.name;
    field.forceSelection = true;
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.hiddenName = field.name;
    field.hiddenId = (new Ext.Component()).getId();
    field.triggerAction ='all';
    //field.valueField = field.name; // valueField shouldn't be set since we're not mapping to row ids.
    field.displayField = field.name;
    field.tpl = '<tpl for="."><div class="x-combo-list-item">{[values["' + field.name + '"]]}</div></tpl>';
    field.listClass = 'labkey-grid-editor';
    field.store = {
        xtype: 'labkey-store',
        schemaName: 'reagent',
        containerPath: LABKEY.container.path,
        sql: 'SELECT DISTINCT ' + table_column + ' FROM ' + h(queryName) + ' WHERE ' + table_column + ' IS NOT NULL ORDER BY ' + table_column + ' LIMIT 1000',
        updateable: false,
        autoLoad: true
    };
//    if (field.allowBlank)
//        field.store.nullRecord = {
//            displayColumn: field.displayField,
//            nullCaption: "[Keep original values]"
//        };
}

function augmentUserCombo(field, queryName)
{
    var h = Ext.util.Format.htmlEncode;

    var table_column = h(queryName + "." + field.name);
    /*
    var sql = 'SELECT DISTINCT X.' + h(meta.name) + ', U.DisplayName ' +
              'FROM reagent.' + h(queryName) + ' X ' +
              'INNER JOIN core.Users U ON U.UserId = CONVERT(X.' + h(meta.name) + ' AS integer) ' +
              'WHERE X.' + h(meta.name) + ' IS NOT NULL';
    */

    var sql =
'SELECT DISTINCT X.' + h(field.name) + ', X.DisplayName FROM (' +
'SELECT' +
'   T.' + h(field.name) + ',' +
'   (CASE WHEN U.DisplayName IS NULL THEN T.' + h(field.name) + ' ELSE U.DisplayName END) AS DisplayName' +
' FROM ' + h(queryName) + ' T' +
' LEFT OUTER JOIN core.Users U ON CONVERT(U.UserId, varchar) = T.' + h(field.name) +
' WHERE T.' + h(field.name) + ' IS NOT NULL' +
' UNION' +
' SELECT CONVERT(U.UserId, varchar) AS ' + h(field.name) + ', U.DisplayName' +
' FROM core.Users U' +
') X';

    
    field.xtype = 'combo';
    field.fieldLabel = field.name;
    field.forceSelection = true;
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.hiddenName = field.name;
    field.hiddenId = (new Ext.Component()).getId();
    field.triggerAction ='all';
    field.valueField = field.name; // valueField shouldn't be set since we're not mapping to row ids.
    field.displayField = "DisplayName";
    field.tpl = '<tpl for="."><div class="x-combo-list-item">{[values["DisplayName"]]}</div></tpl>';
    field.listClass = 'labkey-grid-editor';
    field.store = {
        xtype: 'labkey-store',
        schemaName: 'reagent',
        containerPath: LABKEY.container.path,
        sql: sql,
        updateable: false,
        autoLoad: true
    };
}
