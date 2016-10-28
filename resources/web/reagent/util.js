/*
 * Copyright (c) 2009-2016 LabKey Corporation
 *
 * Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
 */
var ColumnSets = {
    Antigens: [ 'Name', 'Aliases', 'Description' ],
    Labels: [ 'Name', 'Aliases', 'Description' ],
    Manufacturers: [ 'Name' ],
    Species: [ 'Name' ],
    Reagents: [ 'Antigen', 'Label', 'Clone', 'Species/RowId', 'Description' ],
    Lots: [ 'Reagent', 'Manufacturer', 'CatalogNumber', 'LotNumber', 'Description' ],
    Vials: [ 'Lot', 'OwnedBy', 'Location', 'Box', 'Row', 'Col', 'Used' ],
    Titrations: [ 'Lot', 'PerformedBy', 'ExperimentId', 'Type', 'Result', 'Description' ]
};

var ExcludeColumnSets = {
    Antigens: [ 'Container' ],
    Labels: [ 'Container' ],
    Manufacturers: [ 'Container' ],
    Species: [ 'Container' ],
    Reagents: [ 'Species', 'Container', 'CreatedBy', 'Created', 'ModifiedBy', 'Modified', 'Lsid' ],
    Lots: [ 'Container', 'CreatedBy', 'Created', 'ModifiedBy', 'Modified', 'Lsid' ],
    Vials: [ 'Container', 'CreatedBy', 'Created', 'ModifiedBy', 'Modified', 'Lsid' ],
    Titrations: [ 'Container', 'CreatedBy', 'Created', 'ModifiedBy', 'Modified', 'Lsid' ]
};

Ext.QuickTips.init();

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

function editDomain(queryName)
{
    var url = LABKEY.ActionURL.buildURL("property", "editDomain", null, {
        domainKind: "ExtensibleTable",
        createOrEdit: true,
        schemaName: "reagent",
        queryName: queryName
    });
    window.location = url;
}

// UNDONE: insert/update of Reagent and ReagentSpecies should be part of the same transaction
function saveReagentSpecies(schemaName, queryName, initialValues, updatedRows, modifiedSpecies, successCb, errorCb)
{
    var deleteCommand = {
        schemaName: schemaName,
        queryName: "ReagentSpecies",
        command: "delete",
        rows: []
    };
    var insertCommand = {
        schemaName: schemaName,
        queryName: "ReagentSpecies",
        command: "insert",
        rows: []
    };

    for (var i = 0; i < updatedRows.length; i++)
    {
        var updatedRow = updatedRows[i];
        var rowid = updatedRow.rowid || updatedRow.RowId || updatedRow.rowId;

        // delete the original values in the ReagentSpecies table if found
        for (var j = 0; j < initialValues.length; j++)
        {
            var initialValue = initialValues[j];
            var initialValueRowId = initialValue.rowid ? initialValue.rowid.value :
                                    initialValue.RowId ? initialValue.RowId.value :
                                    initialValue.rowId ? initialValue.rowId.value : -1;
            if (initialValueRowId == rowid)
            {
                var initialSpecies = initialValue["Species/RowId"].value;
                for (var k = 0; k < initialSpecies.length; k++)
                {
                    var speciesId = +initialSpecies[k];
                    deleteCommand.rows.push({ReagentId: rowid, SpeciesId: speciesId});
                }
                break;
            }
        }

        // insert new values into the ReagentSpecies table
        var species = modifiedSpecies[i];
        if (species)
        {
            if (Ext.isString(species))
                species = species.split(","); // ugh
            for (var m = 0; m < species.length; m++)
            {
                var speciesId = +species[m];
                insertCommand.rows.push({ReagentId: rowid, SpeciesId: speciesId});
            }
        }
    }

    var commands = [];
    if (deleteCommand.rows.length > 0)
        commands.push(deleteCommand);
    if (insertCommand.rows.length > 0)
        commands.push(insertCommand);

    // nothing to delete or insert
    if (commands.length == 0)
        successCb();

    LABKEY.Query.saveRows({
        commands: commands,
        successCallback: successCb,
        errorCallback: errorCb,
        transacted: true
    })
}

function save(selected, updateRowId, schemaName, queryName, initialValues, values)
{
    Ext.MessageBox.wait("Saving...", "Saving...");

    // stash away the species for insertion later
    var species = null;
    if (queryName == "Reagents")
    {
        species = [];
        for (var i = 0; i < values.length; i++)
        {
            species.push(values[i]["Species/RowId"]);
            delete values[i]["Species/RowId"];
        }
    }

    var fn = LABKEY.Query.insertRows;
    if (selected || updateRowId) {
        fn = LABKEY.Query.updateRows;
    }

    function successCallback() {
        Ext.MessageBox.updateProgress(1, "Saved.");
        Ext.MessageBox.hide();
        navSrcURL();
    }
    
    function errorCallback(errorInfo) {
        Ext.MessageBox.updateProgress(1);
        Ext.MessageBox.hide();
        Ext.MessageBox.alert("Error Saving", errorInfo.exception || errorInfo.statusText);
    }

    // insert or update the row, possibly updating the ReagentSpecies junction table.
    fn({
        schemaName: schemaName,
        queryName: queryName,
        rows: values,
        successCallback: function (data) {
            if (data.rows.length != values.length)
            {
                errorCallback({statusText: "Expected to save " + values.length + " rows, but received only " + data.rows.length + " rows."});
            }
            else
            {
                if (species)
                    saveReagentSpecies(schemaName, queryName, initialValues, data.rows, species, successCallback, errorCallback);
                else
                    successCallback();
            }
        },
        errorCallback: errorCallback
    });
}

var ReagentFormPanel = Ext.extend(LABKEY.ext.FormPanel, {

    // excludes some fields and any duplicates caused by adding '*' to the selected columns
    initFieldDefaults : function (config) {
        var allFields = ReagentFormPanel.superclass.initFieldDefaults.call(this, config);
        var seen = {};
        if (config.excludeItems)
        {
            var fields = [];
            for (var i = 0; i < allFields.length; i++)
            {
                if (!(allFields[i].name in seen) && config.excludeItems.indexOf(allFields[i].name) == -1)
                {
                    seen[allFields[i].name] = true;
                    fields.push(allFields[i]);
                }
            }
            allFields = fields;
        }
        return allFields;
    }
});

/**
 * Initializes the FormPanel.
 * @param selected {Boolean} true when updating multiple records that have been checked on the grid.
 * @param updateRowId {Integer} The row id of the record to update.
 * @param schemaName
 * @param queryName
 */
function initForm(selected, updateRowId, schemaName, queryName, selectionKey)
{
    initSrcURL(schemaName, queryName);

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

            // If there are any equals query filters on the URL, use them as initial values.
            // When looking at the Lot details page and the user clicks "Insert New" to add Titration
            // the parameter "query.LotId~eq=2" should be on the URL and can be used as a default value.
            var params = LABKEY.ActionURL.getParameters();
            for (var key in params)
            {
                // starts with "query." ends with "~eq"
                if (key.indexOf("query.") == 0 && key.indexOf("~eq") == key.length - "~eq".length)
                {
                    var col = key.substring("query.".length, key.length - "~eq".length);
                    var val = params[key];

                    if (data.rows.length == 0)
                    {
                        // Add the dummy row
                        data.rows[0] = {};
                        data.rowCount = 1;
                    }

                    data.rows[0][col] = { value: val };
                }
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

                case 'Species/RowId':
                    augmentSpeciesCombo(c);
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

        var f = new ReagentFormPanel({
            id: 'reagentForm',
            border: false,
            bodyStyle:'padding:5px 5px',
            selectRowsResults: data,
            defaults: { width: 350, msgTarget: "qtip" },
            //items: items,
            excludeItems: ExcludeColumnSets[queryName] || [],
            addAllFields: true,
            lazyCreateStore: true,
            buttonAlign: 'left',
            buttons: [{
                text: 'Save',
                handler: function () {
                    var form = f.getForm();
                    if (form.isValid()) {
                        var values = f.getFormValues();
                        save(selected, updateRowId, schemaName, queryName, f.initialConfig.values || [], values);
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

    var columns = ColumnSets[queryName] || [];
    columns.push("*");
    
    LABKEY.Query.selectRows({
        requiredVersion: 9.1,
        schemaName: schemaName,
        queryName: queryName,
        selectionKey: selectionKey,
        columns: columns,
        filterArray: filters,
        showRows: selected ? "selected" : "all",
        successCallback: createForm,
        errorCallback: function (errorInfo) {
            var error = (errorInfo && errorInfo.exception) ? errorInfo.exception : "An error occurred";
            Ext.fly("msgDiv").update("<span class='labkey-error'>" + Ext.util.Format.htmlEncode(error) + "</span>");
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
    field.store.sort = 'LotNumber,ReagentId/AntigenId/Name,ReagentId/LabelId/Name,ReagentId/Clone,ManufacturerId';
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

function augmentSpeciesCombo(field)
{
    field.fieldLabel = 'Species';
    field.xtype = 'lovcombo';
    field.forceSelection = true;
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.hiddenId = (new Ext.Component()).getId();
    field.triggerAction ='all';
    field.disabled = false;
    field.displayField = "Name";
    field.valueField = "RowId";
    field.allowBlank = true;
    field.store = {
        xtype: 'labkey-store',
        schemaName: 'reagent',
        queryName: 'Species',
        columns: ['RowId', 'Name'],
        containerPath: LABKEY.container.path,
        updatable: false,
        autoLoad: true,
        listeners: {
            metachange: function (store, meta) {
                // Add a 'checked' field for the LovCombo to store its state.
                meta.fields.push({name: "checked", type: "boolean", mvEnabled: false});
                var rtype = Ext.data.Record.create(meta.fields);
                store.fields = rtype.prototype.fields;
                store.columns = store.fields.keys;
                store.recordType = store.reader.recordType = rtype;
            }
        }
    };
}

function augmentTextCombo(field, queryName)
{
    var h = Ext.util.Format.htmlEncode;
    var table_column = h(queryName + "." + field.name);

    field.xtype = 'combo';
    field.fieldLabel = field.name;
    // Don't restrict to values previously entered.
    field.forceSelection = false;
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
    // Don't restrict to values previously entered.
    field.forceSelection = false;
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
