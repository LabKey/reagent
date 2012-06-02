/*
 * Copyright (c) 2010-2011 LabKey Corporation
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

CREATE TABLE reagent.Species
(
  RowId SERIAL NOT NULL,
  Container ENTITYID NOT NULL,
  Name VARCHAR(255) NOT NULL,

  CONSTRAINT PK_Species PRIMARY KEY (RowId),
  CONSTRAINT UQ_Species UNIQUE (Container, Name)
);


CREATE TABLE reagent.ReagentSpecies
(
  ReagentId INT4 NOT NULL,
  SpeciesId INT4 NOT NULL,

  CONSTRAINT PK_ReagentSpecies PRIMARY KEY (ReagentId, SpeciesId),
  CONSTRAINT FK_ReagentSpecies_Reagent FOREIGN KEY (ReagentId)
      REFERENCES reagent.reagents (rowid),
  CONSTRAINT FK_ReagentSpecies_Species FOREIGN KEY (SpeciesId)
      REFERENCES reagent.Species (RowId)
);

CREATE INDEX IX_ReagentSpecies ON reagent.ReagentSpecies USING btree (ReagentId);

