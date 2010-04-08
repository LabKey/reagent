/*
 * Copyright (c) 2009 LabKey Corporation
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

