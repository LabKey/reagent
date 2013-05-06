-- Null out any LSIDs that were created that don't have an associated exp.Object
UPDATE reagent.titrations r SET lsid = NULL WHERE r.lsid IS NOT NULL AND r.lsid NOT IN (SELECT objecturi FROM exp.object);
UPDATE reagent.vials r      SET lsid = NULL WHERE r.lsid IS NOT NULL AND r.lsid NOT IN (SELECT objecturi FROM exp.object);
UPDATE reagent.lots r       SET lsid = NULL WHERE r.lsid IS NOT NULL AND r.lsid NOT IN (SELECT objecturi FROM exp.object);
UPDATE reagent.reagents r   SET lsid = NULL WHERE r.lsid IS NOT NULL AND r.lsid NOT IN (SELECT objecturi FROM exp.object);

-- Restore LSID FKs
ALTER TABLE reagent.Titrations ADD CONSTRAINT FK_Titrations_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Vials ADD CONSTRAINT FK_Vials_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Lots ADD CONSTRAINT FK_Lots_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);
ALTER TABLE reagent.Reagents ADD CONSTRAINT FK_Reagents_LSID FOREIGN KEY (Lsid) REFERENCES exp.Object (ObjectURI);

