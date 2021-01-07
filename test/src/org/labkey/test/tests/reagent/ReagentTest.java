/*
 * Copyright (c) 2010-2018 LabKey Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.labkey.test.tests.reagent;

import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.experimental.categories.Category;
import org.labkey.test.BaseWebDriverTest;
import org.labkey.test.Locator;
import org.labkey.test.Locators;
import org.labkey.test.categories.CustomModules;
import org.labkey.test.pages.ImportDataPage;
import org.labkey.test.util.DataRegionTable;
import org.labkey.test.util.ExtHelper;
import org.labkey.test.util.LogMethod;
import org.labkey.test.util.LoggedParam;
import org.labkey.test.util.PortalHelper;
import org.openqa.selenium.Keys;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Random;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.not;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThat;

@Category({CustomModules.class})
@BaseWebDriverTest.ClassTimeout(minutes = 4)
public class ReagentTest extends BaseWebDriverTest
{
    protected static final String PROJECT_NAME = "ReagentProject";
    protected static final String FOLDER_NAME = "ReagentFolder";

    @Override
    public List<String> getAssociatedModules()
    {
        return Arrays.asList("reagent");
    }

    @Override
    protected String getProjectName()
    {
        return PROJECT_NAME;
    }

    @BeforeClass
    public static void doSetup()
    {
        ReagentTest test = (ReagentTest)getCurrentTest();
        test.setup();
    }

    public void setup()
    {
        createProject();
    }

    public void createProject()
    {
        log("** Create Project");
        _containerHelper.createProject(PROJECT_NAME, null);
        _containerHelper.createSubfolder(PROJECT_NAME, FOLDER_NAME);
        _containerHelper.enableModule("reagent");

        PortalHelper portalHelper = new PortalHelper(this);
        portalHelper.addQueryWebPart("reagent");

        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/reagent-initialize.view");
        clickButton("Initialize", 0);
        waitForElement(Locator.tag("span").withText("Done."), 2 * WAIT_FOR_JAVASCRIPT);
        waitForText("Inserted Manufacturers:", "Inserted Labels:", "Inserted Species:", "Inserted Reagents:");
        assertElementNotPresent(Locators.labkeyError);
    }

    @Test
    public void testInsert()
    {
        log("** Inserting new Reagent");
        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/query-executeQuery.view?schemaName=reagent&query.queryName=Reagents");
        DataRegionTable table = new DataRegionTable("query", this);
        table.clickInsertNewRow();

        waitForElement(Locator.extButton("Cancel"), WAIT_FOR_JAVASCRIPT);

        WebElement el = Locator.tagWithClass("span", "labkey-wp-title-text").findElement(getDriver());
        assertEquals("Insert New Reagent", el.getText());

        log("** Selecting AntigenId from ComboBox list");
        // click on ComboBox trigger image
        _extHelper.selectComboBoxItem("Antigen:", "AVDLSHFLK");

        log("** Filtering LabelId ComboBox by 'Alexa'");

        click(Locator.xpath("//input[@name='LabelId']/../img"));
        setFormElement(Locator.xpath("//input[@name='LabelId']/../input[contains(@class, 'x-form-field')]"), "Alexa");
        int alexaLabels = getElementCount(Locator.tag("div").withClass("x-combo-list-item").notHidden().containing("Alexa"));
        assertEquals("Expected to find 5 Alexa labels", 5, alexaLabels);

        Actions builder = new Actions(getDriver());
        builder.sendKeys(Keys.ARROW_DOWN, Keys.ARROW_DOWN).build().perform();

        waitAndClick(Locator.tag("div").withClass("x-combo-selected").withText("Alexa 680").notHidden());
        assertFormElementEquals(Locator.xpath("//input[@name='LabelId']/../input[contains(@class, 'x-form-field')]"), "Alexa 680");

        String clone = "jimmy " + Math.random();
        setComboBoxInput("Clone:", clone);

        _extHelper.clickExtButton("Save");
        table = new DataRegionTable("query", this);
        table.setFilter("Clone", "Equals", clone);
        assertEquals(1, table.getDataRowCount());

        Map<String, String> rowMap = table.getRowDataAsMap(0);
        assertEquals(clone, rowMap.get("Clone"));
        assertEquals("AVDLSHFLK", rowMap.get("AntigenId"));
        assertEquals("Alexa 680", rowMap.get("LabelId"));
    }

    @Test
    public void testUpdate()
    {
        log("** Navigate to Reagents and filter to clone='8D4-8'");
        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/query-executeQuery.view?schemaName=reagent&query.queryName=Reagents&query.Clone~eq=8D4-8");

        log("** Update existing Reagent");
        DataRegionTable table = new DataRegionTable("query", this);
        table.clickEditRow(0);
        waitForElement(Locator.extButton("Cancel"), WAIT_FOR_JAVASCRIPT);

        WebElement el = Locator.tagWithClass("span", "labkey-wp-title-text").findElement(getDriver());
        assertEquals("Update Reagent", el.getText());

        String description = "update " + Math.random();
        _extHelper.setExtFormElementByLabel("Description:", description);

        _extHelper.clickExtButton("Save");
        table = new DataRegionTable("query", this);
        table.setFilter("Description", "Equals", description);
        assertEquals(1, table.getDataRowCount());
    }

    @Test
    public void testBulkUpdate()
    {
        log("** Navigate to Reagents and filter to Label='Alexa 405'");
        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/query-executeQuery.view?schemaName=reagent&query.queryName=Reagents&query.LabelId%2FName~eq=Alexa%20405");

        DataRegionTable table = new DataRegionTable("query", this);
        assertEquals(4, table.getDataRowCount());

        WebElement bulkEditEl = table.getHeaderButton("Bulk Edit");
        assertThat(bulkEditEl.getAttribute("class"), containsString("labkey-disabled-button"));

        table.checkAllOnPage();
        assertThat(bulkEditEl.getAttribute("class"), not(containsString("labkey-disabled-button")));
        bulkEditEl.click();
        waitForElement(Locator.extButton("Cancel"), WAIT_FOR_JAVASCRIPT);

        WebElement el = Locator.tagWithClass("span", "labkey-wp-title-text").findElement(getDriver());
        assertEquals("Bulk Update Selected Reagents", el.getText());

        assertEquals("Selected rows have different values for this field.", getComboBoxInput("Antigen:"));

        assertEquals("Alexa 405", getComboBoxInput("Label:"));

        assertEquals("Selected rows have different values for this field.", getComboBoxInput("Clone:"));

        _extHelper.selectComboBoxItem("Antigen:", "Via-Probe");

        _extHelper.clickExtButton("Save");

        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/query-executeQuery.view?schemaName=reagent&query.queryName=Reagents&query.LabelId%2FName~eq=Alexa%20405");

        table = new DataRegionTable("query", this);
        assertEquals(4, table.getDataRowCount());
        for (int i = 0; i < table.getDataRowCount(); i++)
        {
            var row = table.getRowDataAsMap(i);
            assertEquals("Via-Probe", row.get("AntigenId"));
            assertEquals("Alexa 405", row.get("LabelId"));
        }
    }

    @Test
    public void testInsertLotAndTiter()
    {
        String antigenName = "CCR7";
        String labelName = "PE-Cy7";
        String clone = "3D12";
        String reagentName = antigenName + ", " + labelName + " (" + clone + ")";

        log("** Navigate to Reagents and filter to Clone='" + clone + "'");
        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/query-executeQuery.view?schemaName=reagent&query.queryName=Reagents&query.Clone~eq=" + clone);

        DataRegionTable table = new DataRegionTable("query", this);
        assertEquals(1, table.getDataRowCount());

        assertEquals(antigenName, table.getDataAsText(0, "AntigenId"));
        assertEquals(labelName, table.getDataAsText(0, "LabelId"));
        assertEquals(clone, table.getDataAsText(0, "Clone"));

        log("** Navigate to Reagent details");
        table.clickRowDetails(0);

        // wait for nested Lots grid
        waitForElement(Locator.id("reagentLots").descendant(Locator.tagWithAttribute("h3", "title", "Lots")), WAIT_FOR_JAVASCRIPT);

        DataRegionTable lotsTable = new DataRegionTable("aqwp101", getDriver());
        assertEquals(0, lotsTable.getDataRowCount());

        log("** Insert new Lot");
        lotsTable.clickInsertNewRow();
        waitForElement(Locator.extButton("Cancel"), WAIT_FOR_JAVASCRIPT);

        WebElement el = Locator.tagWithClass("span", "labkey-wp-title-text").findElement(getDriver());
        assertEquals("Insert New Lot", el.getText());

        String lotNumber = "lot-" + Math.random();

        // reagent combo should pre-select the reagent we started with
        assertEquals(reagentName, getComboBoxInput("Reagent:"));
        _extHelper.selectComboBoxItem("Manufacturer:", "Immunotech");
        _extHelper.setExtFormElementByLabel("Lot Number:", lotNumber);
        setComboBoxInput("CatalogNumber:", "IM2712X");
        //_extHelper.setExtFormElementByLabel("Expiration:", "2050-12-07");

        _extHelper.clickExtButton("Save");

        // wait for nested Lots grid
        waitForElement(Locator.id("reagentLots").descendant(Locator.tagWithAttribute("h3", "title", "Lots")), WAIT_FOR_JAVASCRIPT);

        lotsTable = new DataRegionTable("aqwp101", getDriver());
        assertEquals(1, lotsTable.getDataRowCount());

        log("** Navigate to Lot details");
        lotsTable.clickRowDetails(0);

        // wait for nested Vials grid
        waitForElement(Locator.id("lotVials").descendant(Locator.tagWithAttribute("h3", "title", "Vials")), WAIT_FOR_JAVASCRIPT);

        // wait for nested Titrations grid
        waitForElement(Locator.id("lotTitrations").descendant(Locator.tagWithAttribute("h3", "title", "Titrations")), WAIT_FOR_JAVASCRIPT);

        log("** Navigate to Lots grid");
        clickButton("View Grid");

        table = new DataRegionTable("query", this);
        table.setFilter("LotNumber", "Equals", lotNumber);
        assertEquals(1, table.getDataRowCount());

    }

    @Test
    public void testImportLookupByAlternateKey()
    {
        beginAt(PROJECT_NAME + "/" + FOLDER_NAME + "/query-executeQuery.view?schemaName=reagent&query.queryName=Reagents");

        DataRegionTable table = new DataRegionTable("query", this);
        table.clickImportBulkData();

        String antigen = "CD28/CD49d";
        String label = "PE-Texas Red";
        String clone = "clone" + new Random().nextInt(10000);
        String description = "covfefe";
        String tsv =
                "antigenId\tlabelId\tclone\tdescription\tspecies\n" +
                antigen + "\t" + label + "\t" + clone + "\t" + description + "\t";

        ImportDataPage page = new ImportDataPage(this.getDriver());
        page.setText(tsv);
        page.setImportLookupByAlternateKey(true);
        page.submit();

        // We should be back on grid
        assertTitleContains("Reagents: /" + getProjectName());

        table.setFilter("Clone", "Equals", clone);
        assertEquals("Expected to find a single row for clone '" + clone + "'", 1, table.getDataRowCount());
        assertEquals(antigen, table.getDataAsText(0, "Antigen"));
        assertEquals(label, table.getDataAsText(0, "Label"));
        assertEquals(clone, table.getDataAsText(0, "Clone"));
        assertEquals(description, table.getDataAsText(0, "Description"));
    }


    @LogMethod(quiet = true)
    public void setComboBoxInput(@LoggedParam String label, @LoggedParam String text)
    {
        Locator comboLoc = ExtHelper.Locators.formItemWithLabel(label).notHidden();
        WebElement comboEl = comboLoc.findElement(getDriver());

        Locator inputLoc = Locator.xpath("//input[contains(@class, 'x-form-field')]");
        WebElement inputEl = inputLoc.findElement(comboEl);
        setFormElement(inputEl, text);
    }

    @LogMethod(quiet = true)
    public String getComboBoxInput(@LoggedParam String label)
    {
        Locator comboLoc = ExtHelper.Locators.formItemWithLabel(label).notHidden();
        WebElement comboEl = comboLoc.findElement(getDriver());

        Locator inputLoc = Locator.xpath("//input[contains(@class, 'x-form-field')]");
        WebElement inputEl = inputLoc.findElement(comboEl);
        return getFormElement(inputEl);
    }

}
