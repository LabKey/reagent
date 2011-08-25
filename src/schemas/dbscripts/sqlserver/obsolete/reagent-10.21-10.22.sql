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

/*
 * This script, reagent-10.21-10.22.sql, is the same as reagent-0.00-10.21.sql.
 * The 0.00-10.21 script was checked in after the module version was already set to 10.21 so was never run on some machines.
 * This script should add the reagent schema to those machines.
 */

/* reagent-0.00-0.10.sql */

IF NOT EXISTS (SELECT * from sysusers WHERE name = 'reagent')
BEGIN
  EXEC sp_addapprole 'reagent', 'password'

  CREATE TABLE reagent.Antigens (
      RowId int IDENTITY(1,1) NOT NULL,
      Container EntityID NOT NULL,
      Name VARCHAR(255) NOT NULL,
      Description TEXT,

      CONSTRAINT PK_Antigens PRIMARY KEY (RowId),
      CONSTRAINT UQ_Antigens UNIQUE (Container, Name)
  )

  CREATE TABLE reagent.Labels (
      RowId int IDENTITY(1,1) NOT NULL,
      Container EntityID NOT NULL,
      Name VARCHAR(255) NOT NULL,
      Description TEXT,

      CONSTRAINT PK_Labels PRIMARY KEY (RowId),
      CONSTRAINT UQ_Labels UNIQUE (Container, Name)
  )

  CREATE TABLE reagent.Manufacturers (
      RowId int IDENTITY(1,1) NOT NULL,
      Container EntityID NOT NULL,
      Name VARCHAR(255) NOT NULL,

      CONSTRAINT PK_Manufacturers PRIMARY KEY (RowId),
      CONSTRAINT UQ_Manufacturers UNIQUE (Container, Name)
  )

  CREATE TABLE reagent.Reagents (
      RowId int IDENTITY(1,1) NOT NULL,
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

  CREATE TABLE reagent.Lots (
      RowId int IDENTITY(1,1) NOT NULL,
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

  CREATE TABLE reagent.Vials (
      RowId int IDENTITY(1,1) NOT NULL,
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

  /* reagent-0.10-0.20.sql */

  /* Empty */

  /* reagent-0.20-0.30.sql */

  EXEC sp_rename 'reagent.Vials.Freezer', 'Location', 'COLUMN'
  ALTER TABLE reagent.Vials ALTER COLUMN [Row] VARCHAR(30)
  ALTER TABLE reagent.Vials ALTER COLUMN Col VARCHAR(30)
  ALTER TABLE reagent.Vials ADD Owner VARCHAR(30) NULL

  ALTER TABLE reagent.Antigens ADD Aliases VARCHAR(255) NULL
  ALTER TABLE reagent.Labels ADD Aliases VARCHAR(255) NULL

  /* reagent-0.30-0.40.sql */

  ALTER TABLE Reagent.Reagents ADD Description TEXT NULL

  ALTER TABLE Reagent.Lots ADD Expiration DATETIME NULL
  ALTER TABLE Reagent.Lots ADD Description TEXT NULL

  CREATE TABLE reagent.Titrations (
      RowId int IDENTITY(1,1) NOT NULL,
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

  /* reagent-0.40-0.50.sql */

  EXEC sp_rename 'reagent.Vials.Owner', 'OwnedBy', 'COLUMN'
  EXEC sp_rename 'reagent.Titrations.Owner', 'PerformedBy', 'COLUMN'

  /* reagent-10.20-10.21.sql */

  CREATE TABLE reagent.Species
  (
    RowId int IDENTITY(1,1) NOT NULL,
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

END
