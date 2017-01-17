/*
 * Copyright (c) 2010-2016 LabKey Corporation
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

import org.junit.Test;
import org.junit.experimental.categories.Category;
import org.labkey.test.BaseWebDriverTest;
import org.labkey.test.Locator;
import org.labkey.test.TestTimeoutException;
import org.labkey.test.categories.DailyA;
import org.labkey.test.util.PortalHelper;
import org.openqa.selenium.Keys;
import org.openqa.selenium.interactions.Actions;

import java.util.Arrays;
import java.util.List;

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

    @Override
    protected void doCleanup(boolean afterTest) throws TestTimeoutException
    {
        _containerHelper.deleteProject(getProjectName(), afterTest);
    }

    @Test
    public void testSteps()
    {
        createProject();
        _testInsert();
        _testUpdate();
        _testBulkUpdate();
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

    public void _testInsert()
    {
        log("** Inserting new Reagent");
        beginAt("query/" + PROJECT_NAME + "/" + FOLDER_NAME + "/executeQuery.view?schemaName=reagent&query.queryName=Reagents");
        _extHelper.clickInsertNewRow();

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

    public void _testUpdate()
    {

    }

    public void _testBulkUpdate()
    {
        
    }
}
