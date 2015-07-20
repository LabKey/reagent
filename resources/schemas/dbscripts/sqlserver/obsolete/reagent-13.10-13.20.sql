/*
 * Copyright (c) 2013-2015 LabKey Corporation
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
-- Null out any LSIDs that were created that don't have an associated exp.Object
UPDATE reagent.titrations SET lsid = NULL WHERE lsid IS NOT NULL AND lsid NOT IN (SELECT objecturi FROM exp.object);
UPDATE reagent.vials      SET lsid = NULL WHERE lsid IS NOT NULL AND lsid NOT IN (SELECT objecturi FROM exp.object);
UPDATE reagent.lots       SET lsid = NULL WHERE lsid IS NOT NULL AND lsid NOT IN (SELECT objecturi FROM exp.object);
UPDATE reagent.reagents   SET lsid = NULL WHERE lsid IS NOT NULL AND lsid NOT IN (SELECT objecturi FROM exp.object);
GO

-- Restore LSID FKs
ALTER TABLE reagent.Vials ADD CONSTRAINT FK_Vials_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Titrations ADD CONSTRAINT FK_Titrations_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Lots ADD CONSTRAINT FK_Lots_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Reagents ADD CONSTRAINT FK_Reagents_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
GO

