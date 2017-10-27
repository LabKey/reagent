/*
 * Copyright (c) 2010-2017 LabKey Corporation
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
package org.labkey.test.tests;

import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.experimental.categories.Category;
import org.labkey.test.BaseWebDriverTest;
import org.labkey.test.Locator;
import org.labkey.test.categories.DailyA;
import org.labkey.test.pages.ImportDataPage;
import org.labkey.test.util.DataRegionTable;
import org.labkey.test.util.PortalHelper;
import org.openqa.selenium.Keys;
import org.openqa.selenium.interactions.Actions;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

import static org.junit.Assert.assertEquals;

@Category({DailyA.class})
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

        beginAt("reagent/" + PROJECT_NAME + "/" + FOLDER_NAME + "/initialize.view");
        clickButton("Initialize", 0);
        waitForElement(Locator.name("webpart").containing("Done."), 2 * WAIT_FOR_JAVASCRIPT);
    }

    @Test
    public void testInsert()
    {
        log("** Inserting new Reagent");
        beginAt("query/" + PROJECT_NAME + "/" + FOLDER_NAME + "/executeQuery.view?schemaName=reagent&query.queryName=Reagents");
        DataRegionTable table = new DataRegionTable("query", this);
        table.clickInsertNewRow();

        waitForElement(Locator.extButton("Cancel"), WAIT_FOR_JAVASCRIPT);

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
    }

    @Test
    public void testImportLookupByAlternateKey()
    {
        beginAt("query/" + PROJECT_NAME + "/" + FOLDER_NAME + "/executeQuery.view?schemaName=reagent&query.queryName=Reagents");

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
}
