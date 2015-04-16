/*
 * Copyright (c) 2010-2015 LabKey Corporation
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

/* reagent-0.00-10.10.sql */

CREATE SCHEMA reagent;

CREATE TABLE reagent.Antigens
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Aliases VARCHAR(255),

    CONSTRAINT PK_Antigens PRIMARY KEY (RowId),
    CONSTRAINT UQ_Antigens UNIQUE (Container, Name)
);

CREATE TABLE reagent.Labels
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Aliases VARCHAR(255),

    CONSTRAINT PK_Labels PRIMARY KEY (RowId),
    CONSTRAINT UQ_Labels UNIQUE (Container, Name)
);

CREATE TABLE reagent.Manufacturers
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    Name VARCHAR(255) NOT NULL,

    CONSTRAINT PK_Manufacturers PRIMARY KEY (RowId),
    CONSTRAINT UQ_Manufacturers UNIQUE (Container, Name)
);

CREATE TABLE reagent.Reagents
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    AntigenId INT4 NOT NULL,
    LabelId INT4 NOT NULL,
    Clone VARCHAR(255),
    Description TEXT NULL,

    CONSTRAINT PK_Reagents PRIMARY KEY (RowId),
    CONSTRAINT FK_Reagents_Antigens FOREIGN KEY (AntigenId) REFERENCES reagent.Antigens(RowId),
    CONSTRAINT FK_Reagents_Labels FOREIGN KEY (LabelId) REFERENCES reagent.Labels(RowId),
    CONSTRAINT UQ_Reagents UNIQUE (Container, AntigenId, LabelId, Clone)
);

CREATE TABLE reagent.Lots
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    ReagentId INT4 NOT NULL,
    ManufacturerId INT4 NOT NULL,
    LotNumber VARCHAR(255) NOT NULL,
    CatalogNumber VARCHAR(255),
    Expiration TIMESTAMP NULL,
    Description TEXT NULL,

    CONSTRAINT PK_Lots PRIMARY KEY (RowId),
    CONSTRAINT FK_Lots_Reagents FOREIGN KEY (ReagentId) REFERENCES reagent.Reagents(RowId),
    CONSTRAINT FK_Lots_Manufacturers FOREIGN KEY (ManufacturerId) REFERENCES reagent.Manufacturers(RowId),
    CONSTRAINT UQ_Lots UNIQUE (Container, ManufacturerId, LotNumber, CatalogNumber, ReagentId)
);

CREATE TABLE reagent.Vials
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    LotId INT4 NOT NULL,
    Location VARCHAR(255),
    Box VARCHAR(30),
    Row VARCHAR(30),
    Col VARCHAR(30),
    Used BOOLEAN NOT NULL,
    OwnedBy VARCHAR(30),

    CONSTRAINT PK_Vials PRIMARY KEY (RowId),
    CONSTRAINT FK_Vials_Lots FOREIGN KEY (LotId) REFERENCES reagent.Lots(RowId)
);

CREATE TABLE reagent.Titrations
(
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    LotId INT4 NOT NULL,
    ExperimentId VARCHAR(255),
    PerformedBy VARCHAR(30),
    Type VARCHAR(30) NOT NULL, -- 'Surface', 'Intercellular', '0 Degree'
    Result VARCHAR(30) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Titrations PRIMARY KEY (RowId),
    CONSTRAINT FK_Titrations_Lots FOREIGN KEY (LotId) REFERENCES reagent.Lots(RowId)
);

/* reagent-10.20-10.30.sql */

/* reagent-10.20-10.21.sql */

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

/* reagent-10.22-10.23.sql */

ALTER TABLE reagent.Reagents ADD COLUMN Lsid LsidType null;
ALTER TABLE reagent.Lots ADD COLUMN Lsid LsidType null;
ALTER TABLE reagent.Vials ADD COLUMN Lsid LsidType null;
ALTER TABLE reagent.Titrations ADD COLUMN Lsid LsidType null;

/* reagent-10.23-10.24.sql */

-- Add a Container column to ReagentSpecies to ease Container delete
ALTER TABLE reagent.ReagentSpecies ADD COLUMN Container ENTITYID null;
UPDATE reagent.ReagentSpecies SET Container = (SELECT Container FROM reagent.Reagents r WHERE r.RowId = ReagentId);
ALTER TABLE reagent.ReagentSpecies ALTER COLUMN Container SET NOT NULL;

-- Deleting Reagent will delete associated ReagentSpecies
ALTER TABLE reagent.ReagentSpecies DROP CONSTRAINT FK_ReagentSpecies_Reagent;
ALTER TABLE reagent.ReagentSpecies ADD CONSTRAINT
	FK_ReagentSpecies_Reagent FOREIGN KEY (ReagentId) REFERENCES reagent.Reagents (RowId)
	ON DELETE CASCADE;

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