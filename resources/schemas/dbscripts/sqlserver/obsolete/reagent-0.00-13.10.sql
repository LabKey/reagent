/*
 * Copyright (c) 2015 LabKey Corporation
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

/* reagent-10.20-10.30.sql */

CREATE SCHEMA reagent;
GO

CREATE TABLE reagent.Antigens
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Antigens PRIMARY KEY (RowId),
    CONSTRAINT UQ_Antigens UNIQUE (Container, Name)
)

CREATE TABLE reagent.Labels
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Labels PRIMARY KEY (RowId),
    CONSTRAINT UQ_Labels UNIQUE (Container, Name)
)

CREATE TABLE reagent.Manufacturers
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    Name VARCHAR(255) NOT NULL,

    CONSTRAINT PK_Manufacturers PRIMARY KEY (RowId),
    CONSTRAINT UQ_Manufacturers UNIQUE (Container, Name)
)

CREATE TABLE reagent.Reagents
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created DATETIME NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified DATETIME NOT NULL,

    AntigenId INT NOT NULL,
    LabelId INT NOT NULL,
    Clone VARCHAR(255),

    CONSTRAINT PK_Reagents PRIMARY KEY (RowId),
    CONSTRAINT FK_Reagents_Antigens FOREIGN KEY (AntigenId) REFERENCES reagent.Antigens(RowId),
    CONSTRAINT FK_Reagents_Labels FOREIGN KEY (LabelId) REFERENCES reagent.Labels(RowId),
    CONSTRAINT UQ_Reagents UNIQUE (Container, AntigenId, LabelId, Clone)
)

CREATE TABLE reagent.Lots
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created DATETIME NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified DATETIME NOT NULL,

    ReagentId INT NOT NULL,
    ManufacturerId INT NOT NULL,
    LotNumber VARCHAR(255) NOT NULL,
    CatalogNumber VARCHAR(255),

    CONSTRAINT PK_Lots PRIMARY KEY (RowId),
    CONSTRAINT FK_Lots_Reagents FOREIGN KEY (ReagentId) REFERENCES reagent.Reagents(RowId),
    CONSTRAINT FK_Lots_Manufacturers FOREIGN KEY (ManufacturerId) REFERENCES reagent.Manufacturers(RowId),
    CONSTRAINT UQ_Lots UNIQUE (Container, ManufacturerId, LotNumber, CatalogNumber, ReagentId)
)

CREATE TABLE reagent.Vials
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created DATETIME NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified DATETIME NOT NULL,

    LotId INT NOT NULL,
    Freezer VARCHAR(255),
    Box VARCHAR(30),
    Row INT,
    Col INT,
    Used BIT NOT NULL,

    CONSTRAINT PK_Vials PRIMARY KEY (RowId),
    CONSTRAINT FK_Vials_Lots FOREIGN KEY (LotId) REFERENCES reagent.Lots(RowId)
)

EXEC sp_rename 'reagent.Vials.Freezer', 'Location', 'COLUMN'
ALTER TABLE reagent.Vials ALTER COLUMN [Row] VARCHAR(30)
ALTER TABLE reagent.Vials ALTER COLUMN Col VARCHAR(30)
ALTER TABLE reagent.Vials ADD Owner VARCHAR(30) NULL

ALTER TABLE reagent.Antigens ADD Aliases VARCHAR(255) NULL
ALTER TABLE reagent.Labels ADD Aliases VARCHAR(255) NULL

ALTER TABLE Reagent.Reagents ADD Description TEXT NULL

ALTER TABLE Reagent.Lots ADD Expiration DATETIME NULL
ALTER TABLE Reagent.Lots ADD Description TEXT NULL

CREATE TABLE reagent.Titrations
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created DATETIME NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified DATETIME NOT NULL,

    LotId INT NOT NULL,
    ExperimentId VARCHAR(255),
    Owner VARCHAR(30),
    Type VARCHAR(30) NOT NULL, -- 'Surface', 'Intercellular', '0 Degree'
    Result VARCHAR(30) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Titrations PRIMARY KEY (RowId),
    CONSTRAINT FK_Titrations_Lots FOREIGN KEY (LotId) REFERENCES reagent.Lots(RowId)
)

EXEC sp_rename 'reagent.Vials.Owner', 'OwnedBy', 'COLUMN'
EXEC sp_rename 'reagent.Titrations.Owner', 'PerformedBy', 'COLUMN'

CREATE TABLE reagent.Species
(
    RowId INT IDENTITY(1,1) NOT NULL,
    Container EntityID NOT NULL,
    Name VARCHAR(255) NOT NULL,

    CONSTRAINT PK_Species PRIMARY KEY (RowId),
    CONSTRAINT UQ_Species UNIQUE (Container, Name)
)

CREATE TABLE reagent.ReagentSpecies
(
    ReagentId INT NOT NULL,
    SpeciesId INT NOT NULL,

    CONSTRAINT PK_ReagentSpecies PRIMARY KEY (ReagentId, SpeciesId),
    CONSTRAINT FK_ReagentSpecies_Reagent FOREIGN KEY (ReagentId)
        REFERENCES reagent.reagents (rowid),
    CONSTRAINT FK_ReagentSpecies_Species FOREIGN KEY (SpeciesId)
        REFERENCES reagent.Species (RowId)
)

CREATE INDEX IX_ReagentSpecies ON reagent.ReagentSpecies (ReagentId)

ALTER TABLE reagent.Reagents ADD Lsid LsidType null;
ALTER TABLE reagent.Lots ADD Lsid LsidType null;
ALTER TABLE reagent.Vials ADD Lsid LsidType null;
ALTER TABLE reagent.Titrations ADD Lsid LsidType null;
GO

-- Add a Container column to ReagentSpecies to ease Container delete
ALTER TABLE reagent.ReagentSpecies ADD Container ENTITYID null
GO

UPDATE reagent.ReagentSpecies SET Container = (SELECT Container FROM reagent.Reagents r WHERE r.RowId = ReagentId)
GO

ALTER TABLE reagent.ReagentSpecies ALTER COLUMN Container ENTITYID NOT NULL
GO

-- Deleting Reagent will delete associated ReagentSpecies
ALTER TABLE reagent.ReagentSpecies DROP CONSTRAINT FK_ReagentSpecies_Reagent
GO

ALTER TABLE reagent.ReagentSpecies ADD CONSTRAINT
	FK_ReagentSpecies_Reagent FOREIGN KEY (ReagentId) REFERENCES reagent.Reagents (RowId)
	ON DELETE CASCADE
GO


-- Add Container FKs
ALTER TABLE reagent.Titrations ADD CONSTRAINT FK_Titrations_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Vials ADD CONSTRAINT FK_Vials_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Lots ADD CONSTRAINT FK_Lots_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Manufacturers ADD CONSTRAINT FK_Manufacturers_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.ReagentSpecies ADD CONSTRAINT FK_ReagentSpecies_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Species ADD CONSTRAINT FK_Species_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Reagents ADD CONSTRAINT FK_Reagents_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Labels ADD CONSTRAINT FK_Labels_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
ALTER TABLE reagent.Antigens ADD CONSTRAINT FK_Antigens_Container FOREIGN KEY (Container) REFERENCES core.Containers (EntityID)
GO

-- Add LSID FKs
ALTER TABLE reagent.Vials ADD CONSTRAINT FK_Vials_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI)
ALTER TABLE reagent.Titrations ADD CONSTRAINT FK_Titrations_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI)
ALTER TABLE reagent.Lots ADD CONSTRAINT FK_Lots_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI)
ALTER TABLE reagent.Reagents ADD CONSTRAINT FK_Reagents_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI)
GO

/* reagent-12.30-13.10.sql */

ALTER TABLE reagent.Titrations DROP CONSTRAINT FK_Titrations_LSID;
ALTER TABLE reagent.Vials DROP CONSTRAINT FK_Vials_LSID;
ALTER TABLE reagent.Lots DROP CONSTRAINT FK_Lots_LSID;
ALTER TABLE reagent.Reagents DROP CONSTRAINT FK_Reagents_LSID;