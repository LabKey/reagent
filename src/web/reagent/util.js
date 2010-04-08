var ColumnSets = {
    Antigens: [ 'Name', 'Aliases', 'Description' ],
    Labels: [ 'Name', 'Aliases', 'Description' ],
    Manufacturers: [ 'Name' ],
    Reagents: [ 'AntigenId', 'LabelId', 'Clone', 'Description' ],
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

function save(updateRowId, schemaName, queryName, values)
{
    Ext.MessageBox.wait("Saving...", "Saving...");

    for (var key in values) {
        if (typeof values[key] == "string")
            values[key] = values[key].trim();
    }

    var fn = LABKEY.Query.insertRows;
    if (updateRowId) {
        values["RowId"] = +updateRowId;
        fn = LABKEY.Query.updateRows;
    }

    fn({
        schemaName: schemaName,
        queryName: queryName,
        rowDataArray: [ values ],
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

// updateRowId is 0 when inserting a new item
function initForm(updateRowId, schemaName, queryName)
{
    initSrcURL(schemaName, queryName);

    columns = ColumnSets[queryName] || [];

    function createForm(data)
    {
        // clear out any selected values if we're creating an empty insert form.
        if (!updateRowId && data.rows && data.rows.length > 0)
            data.rows = [];

        // create column->metadata map
        var metaData = { };
        for (var i = 0; i < data.metaData.fields.length; i++)
        {
            var field = data.metaData.fields[i];
            var cm = data.columnModel[i];

            var meta = {};
            Ext.applyIf(meta, field);
            Ext.applyIf(meta, cm);

            metaData[field.name] = meta;
        }

        var items = [ { name: 'RowId', xtype: 'hidden' } ];
        for (var i = 0; i < columns.length; i++)
        {
            var column = columns[i];
            var meta = metaData[column];
            var value = updateRowId ? data.rows[0][column] : undefined;
            var item = null;

            switch (column) {
                case 'ReagentId':
                    item = createReagentCombo(meta, value);
                    break;

                case 'LotId':
                    item = createLotCombo(meta, value);
                    break;

                case 'AntigenId':
                case 'LabelId':
                case 'ManufacturerId':
                    item = createCombo(meta, value);
                    break;

                case 'OwnedBy':
                case 'PerformedBy':
                    // XXX: on update, the userid combo shows the userid value rather than the displayName
                    item = createUserCombo(meta, queryName, value || LABKEY.user.displayName);
                    break;

                case 'Clone':
                case 'CatalogNumber':
                case 'Location':
                case 'Box':
                case 'Row':
                case 'Col':
                case 'Type':
                    item = createTextCombo(meta, queryName, value);
                    break;
            }

            if (item)
            {
                items.push(item);
            }
        }

        var recordCtor = Ext.data.Record.create(data.metaData.fields);

        var f = new LABKEY.ext.FormPanel({
            border: false,
            bodyStyle:'padding:5px 5px',
            selectRowsResults: data,
            defaults: { width: 350 },
            items: items,
            addAllFields: true,
            buttonAlign: 'left',
            buttons: [{
                text: 'Save',
                handler: function () {
                    var form = f.getForm();
                    if (form.isValid()) {
                        var record = new recordCtor({});
                        form.updateRecord(record);
                        save(updateRowId, schemaName, queryName, record.data);
                    }
                    else {
                        Ext.MessageBox.alert('Error saving', 'There are errors on the form.');
                    }
                }
            },{
                text: 'Cancel',
                handler: navSrcURL
            }]
        });

        f.render('formDiv');
    }

    // get the update row or no rows
    var filterRowId = updateRowId || 0;
    var filters = [ LABKEY.Filter.create('RowId', filterRowId) ];

    LABKEY.Query.selectRows({
        schemaName: schemaName,
        queryName: queryName,
        columns: columns.join(','),
        filterArray: filters,
        maxRows: 1,
        successCallback: createForm,
        errorCallback: function (errorInfo) {
            alert(errorInfo);
        }
    });
}

var tm = null;
function measureList(records)
{
    if (!tm)
    {
        var span = Ext.DomHelper.append(document.body,{tag:'span', id:'_hiddenSpan', style:{display:'none'}});
        tm = Ext.util.TextMetrics.createInstance(span);
    }

    var maxWidth = 350;
    for (var i = 0; i < records.length; i++)
    {
        var record = records[i];
        var row = record.data;
        var w = Math.max(tm.getWidth(row["Name"] + " " + row["Aliases"]),
                         tm.getWidth(row["Description"]));
        maxWidth = Math.max(maxWidth, Math.ceil(w));
    }

    return maxWidth;
}

function createReagentCombo(meta, value)
{
    var field = LABKEY.ext.FormHelper.getFieldEditorConfig(meta);
    field.store.baseParams['query.columns'] = ['RowId', 'AntigenId/Name', 'LabelId/Name', 'Clone'].join(',');
    field.store.baseParams['query.sort'] = 'AntigenId/Name,LabelId/Name,Clone';
    field.store.on('load', function (store, records, options) {
        var len = records.length;
        for (var i = 0; i < len; i++) {
            var r = records[i];
            var display = r.data['AntigenId/Name'] + ', ' + r.data['LabelId/Name'] + ' (' + r.data['Clone'] + ')';
            r.data['ReagentDisplay'] = display;
        }
    });

    field.value = value;
    field.initialValue = value;
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.displayField = 'ReagentDisplay';
    field.tpl = '<tpl for="."><div class="x-combo-list-item"><b>{[values["AntigenId/Name"]]}</b> {[values["LabelId/Name"]]} <i>({[values["Clone"]]})</i></div></tpl>';

    // set 'name' property so LABKEY.ext.FormPanel.initComponents will filter out the existing items
    field.name = field.name || field.hiddenName;

    var combo = Ext.ComponentMgr.create(field);
    combo.store.on('load', combo.initialLoad, combo);
    combo.store.load();
    return combo;
}

function createLotCombo(meta, value)
{
    var field = LABKEY.ext.FormHelper.getFieldEditorConfig(meta);
    field.store.baseParams['query.columns'] = ['RowId', 'LotNumber', 'CatalogNumber', 'ManufacturerId/Name', 'ReagentId/AntigenId/Name', 'ReagentId/LabelId/Name', 'ReagentId/Clone'].join(',');
    field.store.baseParams['query.sort'] = 'ReagentId/AntigenId/Name,ReagentId/LabelId/Name,ReagentId/Clone,ManufacturerId';
    field.store.on('load', function (store, records, options) {
        var len = records.length;
        for (var i = 0; i < len; i++) {
            var r = records[i];
            var display = 'Lot ' + r.data['LotNumber'] + ': ' + r.data['ReagentId/AntigenId/Name'] + ', ' + r.data['ReagentId/LabelId/Name'] + ' (' + r.data['ReagentId/Clone'] + ') ' + r.data['ManufacturerId/Name'];
            r.data['LotDisplay'] = display;
        }
    });

    field.value = value;
    field.initialValue = value;
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    field.displayField = 'LotDisplay';
    field.tpl = '<tpl for="."><div class="x-combo-list-item">Lot {[values["LotNumber"]]}: <b>{[values["ReagentId/AntigenId/Name"]]}</b>, {[values["ReagentId/LabelId/Name"]]} <i>({[values["ReagentId/Clone"]]})</i> &nbsp;{[values["ManufacturerId/Name"]]}</div></tpl>',

    // set 'name' property so LABKEY.ext.FormPanel.initComponents will filter out the existing items
    field.name = field.name || field.hiddenName;

    var combo = Ext.ComponentMgr.create(field);
    combo.store.on('load', combo.initialLoad, combo);
    combo.store.load();
    return combo;
}

function createCombo(meta, value)
{
    var field = LABKEY.ext.FormHelper.getFieldEditorConfig(meta);
    field.store.baseParams['query.columns'] = ['RowId', 'Name', 'Aliases', 'Description'].join(',');
    field.store.baseParams['query.sort'] = 'Name';
    field.value = value;
    field.initialValue = value;
    field.typeAhead = true;
    field.minChars = 0;
    field.mode = 'local';
    if (meta.name == 'ManufacturerId')
        field.tpl = '<tpl for="."><div class="x-combo-list-item">{[values["Name"]]}</div></tpl>';
    else
        field.tpl = '<tpl for="."><div class="x-combo-list-item" style="color:#555"><div style="color:#222"><i style="font-size:0.9em;display:block;float:right;clear:none;">{[values["Aliases"]]}</i><b>{[values["Name"]]}</b></div>{[values["Description"]]}</div></tpl>';

    // set 'name' property so LABKEY.ext.FormPanel.initComponents will filter out the existing items
    field.name = field.name || field.hiddenName;

    var combo = Ext.ComponentMgr.create(field);
    combo.store.on('load', combo.initialLoad, combo);
    combo.store.on('load', function (s, records) {
        var w = measureList(records);
        combo.listWidth = w;
    });
    combo.store.load();
    return combo;
}

function createTextCombo(meta, queryName, value)
{
    var h = Ext.util.Format.htmlEncode;

    var table_column = h(queryName + "." + meta.name);
    var store = new LABKEY.ext.Store({
        schemaName: 'reagent',
        containerPath: LABKEY.container.path,
        sql: 'SELECT DISTINCT ' + table_column + ' FROM ' + h(queryName) + ' WHERE ' + table_column + ' IS NOT NULL ORDER BY ' + table_column,
        updateable: false
    });

    var combo = new LABKEY.ext.ComboBox({
        name: meta.name,
        fieldLabel: h(meta.label) || meta.header || h(meta.name),
        helpPopup: { html: meta.tooltip },
        store: store,
        value: value,
        initialValue: value,
        allowBlank: !meta.required,
        forceSelection: false, /* don't restrict to just values previously entered. */
        typeAhead: true,
        minChars: 0,
        mode: 'local',
        hiddenName: meta.name,
        hiddenId: (new Ext.Component()).getId(),
        triggerAction: 'all',
        //valueField: meta.name, // valueField isn't necessary since we're not mapping to row ids.
        displayField: meta.name,
        tpl: '<tpl for="."><div class="x-combo-list-item">{[values["' + meta.name + '"]]}</div></tpl>',
        listClass: 'labkey-grid-editor'
    });

    if (meta.tooltip)
        combo.helpPopup = { html: meta.tooltip };

    combo.store.load();
    return combo;
}

function createUserCombo(meta, queryName, value)
{
    var h = Ext.util.Format.htmlEncode;

    var table_column = h(queryName + "." + meta.name);
    /*
    var sql = 'SELECT DISTINCT X.' + h(meta.name) + ', U.DisplayName ' +
              'FROM reagent.' + h(queryName) + ' X ' +
              'INNER JOIN core.Users U ON U.UserId = CONVERT(X.' + h(meta.name) + ' AS integer) ' +
              'WHERE X.' + h(meta.name) + ' IS NOT NULL';
    */

    var sql =
'SELECT DISTINCT X.' + h(meta.name) + ', X.DisplayName FROM (' +
'SELECT' +
'   T.' + h(meta.name) + ',' +
'   (CASE WHEN U.DisplayName IS NULL THEN T.' + h(meta.name) + ' ELSE U.DisplayName END) AS DisplayName' +
' FROM ' + h(queryName) + ' T' +
' LEFT OUTER JOIN core.Users U ON CONVERT(U.UserId AS varchar) = T.' + h(meta.name) +
' WHERE T.' + h(meta.name) + ' IS NOT NULL' +
' UNION' +
' SELECT CONVERT(U.UserId AS varchar) AS ' + h(meta.name) + ', U.DisplayName' +
' FROM core.Users U' +
') X';


    var store = new LABKEY.ext.Store({
        schemaName: 'reagent',
        containerPath: LABKEY.container.path,
        sql: sql,
        updateable: false
    });

    var combo = new LABKEY.ext.ComboBox({
        name: meta.name,
        fieldLabel: h(meta.label) || meta.header || h(meta.name),
        store: store,
        value: value,
        initialValue: value,
        allowBlank: !meta.required,
        forceSelection: false, /* don't restrict to just values previously entered. */
        typeAhead: true,
        minChars: 0,
        mode: 'local',
        hiddenName: meta.name,
        hiddenId: (new Ext.Component()).getId(),
        triggerAction: 'all',
        valueField: meta.name,
        displayField: "DisplayName",
        tpl: '<tpl for="."><div class="x-combo-list-item">{[values["DisplayName"]]}</div></tpl>',
        listClass: 'labkey-grid-editor'
    });

    if (meta.tooltip)
        combo.helpPopup = { html: meta.tooltip };

    combo.store.load();
    return combo;
}
