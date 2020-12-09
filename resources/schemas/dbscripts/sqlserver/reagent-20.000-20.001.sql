
ALTER TABLE reagent.Antigens DROP CONSTRAINT UQ_Antigens;
ALTER TABLE reagent.Antigens ALTER COLUMN Name NVARCHAR(255) NULL;
ALTER TABLE reagent.Antigens ADD CONSTRAINT UQ_Antigens UNIQUE (Container, Name);
ALTER TABLE reagent.Antigens ALTER COLUMN Description NVARCHAR(max) NULL;
ALTER TABLE reagent.Antigens ALTER COLUMN Aliases NVARCHAR(255) NULL;

ALTER TABLE reagent.Labels DROP CONSTRAINT UQ_Labels;
ALTER TABLE reagent.Labels ALTER COLUMN Name NVARCHAR(255) NULL;
ALTER TABLE reagent.Labels ADD CONSTRAINT UQ_Labels UNIQUE (Container, Name);
ALTER TABLE reagent.Labels ALTER COLUMN Description NVARCHAR(max) NULL;
ALTER TABLE reagent.Labels ALTER COLUMN Aliases NVARCHAR(255) NULL;

ALTER TABLE reagent.Lots DROP CONSTRAINT UQ_Lots;
ALTER TABLE reagent.Lots ALTER COLUMN LotNumber NVARCHAR(255) NULL;
ALTER TABLE reagent.Lots ALTER COLUMN CatalogNumber NVARCHAR(255) NULL;
ALTER TABLE reagent.Lots ADD CONSTRAINT UQ_Lots UNIQUE (Container, ManufacturerId, LotNumber, CatalogNumber, ReagentId);
ALTER TABLE reagent.Lots ALTER COLUMN Description NVARCHAR(max) NULL;

ALTER TABLE reagent.Manufacturers DROP CONSTRAINT UQ_Manufacturers;
ALTER TABLE reagent.Manufacturers ALTER COLUMN Name NVARCHAR(255) NULL;
ALTER TABLE reagent.Manufacturers ADD CONSTRAINT UQ_Manufacturers UNIQUE (Container, Name);

ALTER TABLE reagent.Reagents DROP CONSTRAINT UQ_Reagents;
ALTER TABLE reagent.Reagents ALTER COLUMN Clone NVARCHAR(255) NULL;
ALTER TABLE reagent.Reagents ADD CONSTRAINT UQ_Reagents UNIQUE (Container, AntigenId, Clone, LabelId);
ALTER TABLE reagent.Reagents ALTER COLUMN Description NVARCHAR(max) NULL;

ALTER TABLE reagent.Species DROP CONSTRAINT UQ_Species;
ALTER TABLE reagent.Species ALTER COLUMN Name NVARCHAR(255) NULL;
ALTER TABLE reagent.Species ADD CONSTRAINT UQ_Species UNIQUE (Container, Name);

ALTER TABLE reagent.Titrations ALTER COLUMN ExperimentId NVARCHAR(255) NULL;
ALTER TABLE reagent.Titrations ALTER COLUMN PerformedBy NVARCHAR(30) NULL;
ALTER TABLE reagent.Titrations ALTER COLUMN Type NVARCHAR(30) NULL;
ALTER TABLE reagent.Titrations ALTER COLUMN Result NVARCHAR(30) NULL;
ALTER TABLE reagent.Titrations ALTER COLUMN Description NVARCHAR(max) NULL;

ALTER TABLE reagent.Vials ALTER COLUMN Location NVARCHAR(255) NULL;
ALTER TABLE reagent.Vials ALTER COLUMN Box NVARCHAR(30) NULL;
ALTER TABLE reagent.Vials ALTER COLUMN Row NVARCHAR(30) NULL;
ALTER TABLE reagent.Vials ALTER COLUMN Col NVARCHAR(30) NULL;
ALTER TABLE reagent.Vials ALTER COLUMN OwnedBy NVARCHAR(max) NULL;
