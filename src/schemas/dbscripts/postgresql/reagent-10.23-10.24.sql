/*
 * Copyright (c) 2010 LabKey Corporation
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

-- Add a Container column to ReagentSpecies to ease Container delete
ALTER TABLE reagent.ReagentSpecies ADD COLUMN Container ENTITYID null;
UPDATE reagent.ReagentSpecies SET Container = (SELECT Container FROM reagent.Reagents r WHERE r.RowId = ReagentId);
ALTER TABLE reagent.ReagentSpecies ALTER COLUMN Container SET NOT NULL;

-- Deleting Reagent will delete associated ReagentSpecies
ALTER TABLE reagent.ReagentSpecies DROP CONSTRAINT FK_ReagentSpecies_Reagent;
ALTER TABLE reagent.ReagentSpecies ADD CONSTRAINT
	FK_ReagentSpecies_Reagent FOREIGN KEY (ReagentId) REFERENCES reagent.Reagents (RowId)
	ON DELETE CASCADE;

-- Clean up any data in a deleted Containers
DELETE FROM reagent.Titrations WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Vials WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Lots WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Manufacturers WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.ReagentSpecies WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Species WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Reagents WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Labels WHERE Container NOT IN (select entityid from core.Containers);
DELETE FROM reagent.Antigens WHERE Container NOT IN (select entityid from core.Containers);

-- Add Container FKs
ALTER TABLE reagent.Titrations ADD CONSTRAINT FK_Titrations_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Vials ADD CONSTRAINT FK_Vials_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Lots ADD CONSTRAINT FK_Lots_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Manufacturers ADD CONSTRAINT FK_Manufacturers_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.ReagentSpecies ADD CONSTRAINT FK_ReagentSpecies_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Species ADD CONSTRAINT FK_Species_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Reagents ADD CONSTRAINT FK_Reagents_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Labels ADD CONSTRAINT FK_Labels_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);
ALTER TABLE reagent.Antigens ADD CONSTRAINT FK_Antigens_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID);

-- Add LSID FKs
ALTER TABLE reagent.Titrations ADD CONSTRAINT FK_Titrations_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Vials ADD CONSTRAINT FK_Vials_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Lots ADD CONSTRAINT FK_Lots_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Reagents ADD CONSTRAINT FK_Reagents_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);

