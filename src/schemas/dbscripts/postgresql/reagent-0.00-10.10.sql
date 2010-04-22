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

/* reagent-0.00-0.10.sql */

CREATE SCHEMA reagent;

CREATE TABLE reagent.Antigens (
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Antigens PRIMARY KEY (RowId),
    CONSTRAINT UQ_Antigens UNIQUE (Container, Name)
);

CREATE TABLE reagent.Labels (
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Labels PRIMARY KEY (RowId),
    CONSTRAINT UQ_Labels UNIQUE (Container, Name)
);

CREATE TABLE reagent.Manufacturers (
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    Name VARCHAR(255) NOT NULL,

    CONSTRAINT PK_Manufacturers PRIMARY KEY (RowId),
    CONSTRAINT UQ_Manufacturers UNIQUE (Container, Name)
);

CREATE TABLE reagent.Reagents (
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    AntigenId INT4 NOT NULL,
    LabelId INT4 NOT NULL,
    Clone VARCHAR(255),

    CONSTRAINT PK_Reagents PRIMARY KEY (RowId),
    CONSTRAINT FK_Reagents_Antigens FOREIGN KEY (AntigenId) REFERENCES reagent.Antigens(RowId),
    CONSTRAINT FK_Reagents_Labels FOREIGN KEY (LabelId) REFERENCES reagent.Labels(RowId),
    CONSTRAINT UQ_Reagents UNIQUE (Container, AntigenId, LabelId, Clone)
);

CREATE TABLE reagent.Lots (
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

    CONSTRAINT PK_Lots PRIMARY KEY (RowId),
    CONSTRAINT FK_Lots_Reagents FOREIGN KEY (ReagentId) REFERENCES reagent.Reagents(RowId),
    CONSTRAINT FK_Lots_Manufacturers FOREIGN KEY (ManufacturerId) REFERENCES reagent.Manufacturers(RowId),
    CONSTRAINT UQ_Lots UNIQUE (Container, ManufacturerId, LotNumber, CatalogNumber, ReagentId)
);

CREATE TABLE reagent.Vials (
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    LotId INT4 NOT NULL,
    Freezer VARCHAR(255),
    Box VARCHAR(30),
    Row INT4,
    Col INT4,
    Used BOOLEAN NOT NULL,

    CONSTRAINT PK_Vials PRIMARY KEY (RowId),
    CONSTRAINT FK_Vials_Lots FOREIGN KEY (LotId) REFERENCES reagent.Lots(RowId)
);

/* reagent-0.10-0.20.sql */

/* Empty */

/* reagent-0.20-0.30.sql */

ALTER TABLE reagent.vials RENAME freezer TO location;
ALTER TABLE reagent.vials ALTER "row" TYPE character varying(30);
ALTER TABLE reagent.vials ALTER col TYPE character varying(30);
ALTER TABLE reagent.vials ADD COLUMN owner character varying(30);

ALTER TABLE reagent.antigens ADD COLUMN aliases character varying(255);
ALTER TABLE reagent.labels ADD COLUMN aliases character varying(255);

/* reagent-0.30-0.40.sql */

ALTER TABLE reagent.Reagents ADD COLUMN Description TEXT null;

ALTER TABLE reagent.Lots ADD COLUMN Expiration TIMESTAMP null;
ALTER TABLE reagent.Lots ADD COLUMN Description TEXT null;

CREATE TABLE reagent.Titrations (
    RowId SERIAL NOT NULL,
    Container ENTITYID NOT NULL,
    CreatedBy USERID NOT NULL,
    Created TIMESTAMP NOT NULL,
    ModifiedBy USERID NOT NULL,
    Modified TIMESTAMP NOT NULL,

    LotId INT4 NOT NULL,
    ExperimentId VARCHAR(255),
    Owner VARCHAR(30),
    Type VARCHAR(30) NOT NULL, -- 'Surface', 'Intercellular', '0 Degree'
    Result VARCHAR(30) NOT NULL,
    Description TEXT,

    CONSTRAINT PK_Titrations PRIMARY KEY (RowId),
    CONSTRAINT FK_Titrations_Lots FOREIGN KEY (LotId) REFERENCES reagent.Lots(RowId)
);

/* reagent-0.40-0.50.sql */

ALTER TABLE reagent.Vials RENAME Owner TO OwnedBy;
ALTER TABLE reagent.Titrations RENAME Owner TO PerformedBy;
