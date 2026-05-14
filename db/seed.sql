-- This file is applied after schema.sql; safe to run idempotently.
-- 25 work orders × 17 tasks = 425 task rows
-- Story rows per spec §7; task states per NAS ToBe applicability matrix

INSERT INTO wm_order VALUES
  ('ord-0012867','ORD0012867',100,'Completed','Test1 Customer','Borken','Willbecke 12',1,'SDU-GFTAL-NE4'),
  ('ord-0012864','ORD0012864',100,'Completed','Test4 Customer','Borken','Willbecke 13',1,'SDU-GFTAL-NE4'),
  ('ord-0012860','ORD0012860',100,'Completed','Test7 Customer','Borken','Willbecke 14',1,'SDU-GFTAL-HTP'),
  ('ord-0012865','ORD0012865',103,'in progress','Test3 Customer','Borken','Willbecke 15',1,'SDU-GFTAL-NE4'),
  ('ord-0012853','ORD0012853',103,'in progress','Test6 Customer','Borken','Willbecke 16',1,'SDU-GFTAL-NE4'),
  ('ord-0012849','ORD0012849',103,'in progress','Test9 Customer','Borken','Hauptstraße 5',1,'SDU-GFTAL-HTP'),
  ('ord-0012848','ORD0012848',108,'Fallout','Test2 Customer','Borken','Hauptstraße 7',1,'SDU-GFTAL-NE4'),
  ('ord-0012846','ORD0012846',108,'Fallout','Test5 Customer','Borken','Hauptstraße 9',1,'SDU-GFTAL-NE4'),
  ('ord-0012845','ORD0012845',101,'Open','Test8 Customer','Borken','Willbecke 17',1,'SDU-GFTAL-NE4'),
  ('ord-0012844','ORD0012844',101,'Open','Test10 Customer','Borken','Willbecke 18',1,'SDU-GFTAL-NE4'),
  ('ord-0012843','ORD0012843',102,'in progress','Test1 Customer','Borken','Willbecke 19',1,'SDU-GFTAL-NE4'),
  ('ord-0012842','ORD0012842',109,'Cancellation in progress','Test3 Customer','Borken','Hauptstraße 11',1,'SDU-GFTAL-HTP'),
  ('ord-0012841','ORD0012841',103,'in progress','Test2 Customer','Borken','Hauptstraße 3',4,'MDU-GFTAL-NE4'),
  ('ord-0012840','ORD0012840',103,'in progress','Test6 Customer','Borken','Hauptstraße 1',6,'MDU-PHA Full Expansion-NE4'),
  ('ord-0012839','ORD0012839',102,'in progress','Test4 Customer','Borken','Willbecke 20',1,'SDU-GFTAL-NE4'),
  ('ord-0012838','ORD0012838',101,'Open','Test7 Customer','Borken','Hauptstraße 13',1,'SDU-GFTAL-NE4'),
  ('ord-0012837','ORD0012837',101,'Open','Test9 Customer','Borken','Hauptstraße 15',1,'SDU-GFTAL-HTP'),
  ('ord-0012836','ORD0012836',103,'in progress','Test5 Customer','Borken','Hauptstraße 17',1,'SDU-GFTAL-NE4'),
  ('ord-0012835','ORD0012835',103,'in progress','Test8 Customer','Borken','Hauptstraße 19',1,'SDU-GFTAL-NE4'),
  ('ord-0012834','ORD0012834',102,'in progress','Test10 Customer','Borken','Hauptstraße 21',1,'SDU-GFTAL-NE4'),
  ('ord-0012833','ORD0012833',102,'in progress','Test1 Customer','Borken','Hauptstraße 23',1,'MDU-PHA Standard-NA'),
  ('ord-0012832','ORD0012832',105,'in progress','Test3 Customer','Borken','Willbecke 21',2,'MDU-GFTAL-NE4'),
  ('ord-0012831','ORD0012831',107,'in progress','Test6 Customer','Borken','Willbecke 22',1,'SDU-GFTAL-NE4'),
  ('ord-0012830','ORD0012830',103,'in progress','Test2 Customer','Borken','Hauptstraße 25',8,'MDU-PHA Full Expansion-NE4'),
  ('ord-0012828','ORD0012828',100,'Completed','Test4 Customer','Borken','Willbecke 23',1,'SDU-GFTAL-HTP');

-- ============================================================
-- TASKS
-- Task sys_id: wot-0050001 through wot-0050425
-- Task number: WOT0050001 through WOT0050425
-- 17 tasks per WO, in canonical sequence order
-- sys_updated_on distributed across last 30 days
-- ============================================================

-- ORD0012867 (tasks 1-17): status 100 Completed, All Done, SDU-GFTAL-NE4
-- Applicable: all 17; NE4 tasks apply (NE4 set); UV-S not applicable (SDU single unit)
INSERT INTO wm_task VALUES
  ('wot-0050001','WOT0050001','ord-0012867','HV-S','HV','Done','Field Ops Team A','2026-04-25T10:15:00Z'),
  ('wot-0050002','WOT0050002','ord-0012867','UV-S','UV','not applicable','','2026-04-25T10:15:00Z'),
  ('wot-0050003','WOT0050003','ord-0012867','HV-NE4','HV4','Done','Field Ops Team A','2026-04-26T09:00:00Z'),
  ('wot-0050004','WOT0050004','ord-0012867','UV-NE4','UV4','not applicable','','2026-04-25T10:15:00Z'),
  ('wot-0050005','WOT0050005','ord-0012867','GIS Planung','GP','Done','GIS Team','2026-04-10T14:00:00Z'),
  ('wot-0050006','WOT0050006','ord-0012867','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-11T11:00:00Z'),
  ('wot-0050007','WOT0050007','ord-0012867','Genehmigungen','PM','Done','Permits Team','2026-04-12T09:30:00Z'),
  ('wot-0050008','WOT0050008','ord-0012867','Tiefbau','CV','Done','Civil Works Team','2026-04-14T16:00:00Z'),
  ('wot-0050009','WOT0050009','ord-0012867','Spleißen','SP','Done','Fiber Ops Team','2026-04-18T11:00:00Z'),
  ('wot-0050010','WOT0050010','ord-0012867','Einblasen','BF','Done','Fiber Ops Team','2026-04-19T14:00:00Z'),
  ('wot-0050011','WOT0050011','ord-0012867','Gartenbohrung','GD','Done','Drilling Team','2026-04-20T10:00:00Z'),
  ('wot-0050012','WOT0050012','ord-0012867','Hauseinführung','WB','Done','Install Team','2026-04-21T15:00:00Z'),
  ('wot-0050013','WOT0050013','ord-0012867','HÜP','HÜP','Done','Install Team','2026-04-22T10:00:00Z'),
  ('wot-0050014','WOT0050014','ord-0012867','Leitungsweg NE4','CW4','Done','Install Team','2026-04-23T09:00:00Z'),
  ('wot-0050015','WOT0050015','ord-0012867','GFTA','GFTA','Done','Install Team','2026-04-24T14:00:00Z'),
  ('wot-0050016','WOT0050016','ord-0012867','ONT','ONT','Done','Install Team','2026-04-25T09:00:00Z'),
  ('wot-0050017','WOT0050017','ord-0012867','Patch','PCH','Done','Patch Team','2026-04-25T10:15:00Z');

-- ORD0012864 (tasks 18-34): status 100 Completed, All Done, SDU-GFTAL-NE4
INSERT INTO wm_task VALUES
  ('wot-0050018','WOT0050018','ord-0012864','HV-S','HV','Done','Field Ops Team B','2026-04-28T11:00:00Z'),
  ('wot-0050019','WOT0050019','ord-0012864','UV-S','UV','not applicable','','2026-04-28T11:00:00Z'),
  ('wot-0050020','WOT0050020','ord-0012864','HV-NE4','HV4','Done','Field Ops Team B','2026-04-28T14:00:00Z'),
  ('wot-0050021','WOT0050021','ord-0012864','UV-NE4','UV4','not applicable','','2026-04-28T11:00:00Z'),
  ('wot-0050022','WOT0050022','ord-0012864','GIS Planung','GP','Done','GIS Team','2026-04-13T09:00:00Z'),
  ('wot-0050023','WOT0050023','ord-0012864','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-14T10:00:00Z'),
  ('wot-0050024','WOT0050024','ord-0012864','Genehmigungen','PM','Done','Permits Team','2026-04-15T11:00:00Z'),
  ('wot-0050025','WOT0050025','ord-0012864','Tiefbau','CV','Done','Civil Works Team','2026-04-17T13:00:00Z'),
  ('wot-0050026','WOT0050026','ord-0012864','Spleißen','SP','Done','Fiber Ops Team','2026-04-20T09:00:00Z'),
  ('wot-0050027','WOT0050027','ord-0012864','Einblasen','BF','Done','Fiber Ops Team','2026-04-21T11:00:00Z'),
  ('wot-0050028','WOT0050028','ord-0012864','Gartenbohrung','GD','Done','Drilling Team','2026-04-22T09:00:00Z'),
  ('wot-0050029','WOT0050029','ord-0012864','Hauseinführung','WB','Done','Install Team','2026-04-23T14:00:00Z'),
  ('wot-0050030','WOT0050030','ord-0012864','HÜP','HÜP','Done','Install Team','2026-04-24T10:00:00Z'),
  ('wot-0050031','WOT0050031','ord-0012864','Leitungsweg NE4','CW4','Done','Install Team','2026-04-25T11:00:00Z'),
  ('wot-0050032','WOT0050032','ord-0012864','GFTA','GFTA','Done','Install Team','2026-04-26T14:00:00Z'),
  ('wot-0050033','WOT0050033','ord-0012864','ONT','ONT','Done','Install Team','2026-04-28T10:00:00Z'),
  ('wot-0050034','WOT0050034','ord-0012864','Patch','PCH','Done','Patch Team','2026-04-28T11:00:00Z');

-- ORD0012860 (tasks 35-51): status 100 Completed, All Done, SDU-GFTAL-HTP
-- HTP set: NE4 tasks (HV-NE4, UV-NE4, Leitungsweg NE4) not applicable
INSERT INTO wm_task VALUES
  ('wot-0050035','WOT0050035','ord-0012860','HV-S','HV','Done','Field Ops Team C','2026-04-30T10:00:00Z'),
  ('wot-0050036','WOT0050036','ord-0012860','UV-S','UV','not applicable','','2026-04-30T10:00:00Z'),
  ('wot-0050037','WOT0050037','ord-0012860','HV-NE4','HV4','not applicable','','2026-04-30T10:00:00Z'),
  ('wot-0050038','WOT0050038','ord-0012860','UV-NE4','UV4','not applicable','','2026-04-30T10:00:00Z'),
  ('wot-0050039','WOT0050039','ord-0012860','GIS Planung','GP','Done','GIS Team','2026-04-05T09:00:00Z'),
  ('wot-0050040','WOT0050040','ord-0012860','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-06T10:00:00Z'),
  ('wot-0050041','WOT0050041','ord-0012860','Genehmigungen','PM','Done','Permits Team','2026-04-07T11:00:00Z'),
  ('wot-0050042','WOT0050042','ord-0012860','Tiefbau','CV','Done','Civil Works Team','2026-04-10T14:00:00Z'),
  ('wot-0050043','WOT0050043','ord-0012860','Spleißen','SP','Done','Fiber Ops Team','2026-04-15T10:00:00Z'),
  ('wot-0050044','WOT0050044','ord-0012860','Einblasen','BF','Done','Fiber Ops Team','2026-04-16T11:00:00Z'),
  ('wot-0050045','WOT0050045','ord-0012860','Gartenbohrung','GD','Done','Drilling Team','2026-04-18T09:00:00Z'),
  ('wot-0050046','WOT0050046','ord-0012860','Hauseinführung','WB','Done','Install Team','2026-04-22T14:00:00Z'),
  ('wot-0050047','WOT0050047','ord-0012860','HÜP','HÜP','Done','Install Team','2026-04-25T10:00:00Z'),
  ('wot-0050048','WOT0050048','ord-0012860','Leitungsweg NE4','CW4','not applicable','','2026-04-30T10:00:00Z'),
  ('wot-0050049','WOT0050049','ord-0012860','GFTA','GFTA','Done','Install Team','2026-04-28T14:00:00Z'),
  ('wot-0050050','WOT0050050','ord-0012860','ONT','ONT','Done','Install Team','2026-04-29T10:00:00Z'),
  ('wot-0050051','WOT0050051','ord-0012860','Patch','PCH','Done','Patch Team','2026-04-30T10:00:00Z');

-- ORD0012865 (tasks 52-68): status 103 in progress, civil works done, mounting open, SDU-GFTAL-NE4
-- Pattern: GIS/LLD/PM/CV done; Spleißen/Einblasen Done; HÜP/GFTA/ONT/Patch Assigned; HV-S Done; HV-NE4 Scheduled
INSERT INTO wm_task VALUES
  ('wot-0050052','WOT0050052','ord-0012865','HV-S','HV','Done','Field Ops Team A','2026-05-02T09:00:00Z'),
  ('wot-0050053','WOT0050053','ord-0012865','UV-S','UV','not applicable','','2026-05-02T09:00:00Z'),
  ('wot-0050054','WOT0050054','ord-0012865','HV-NE4','HV4','Scheduled','Field Ops Team A','2026-05-10T10:00:00Z'),
  ('wot-0050055','WOT0050055','ord-0012865','UV-NE4','UV4','not applicable','','2026-05-02T09:00:00Z'),
  ('wot-0050056','WOT0050056','ord-0012865','GIS Planung','GP','Done','GIS Team','2026-04-20T09:00:00Z'),
  ('wot-0050057','WOT0050057','ord-0012865','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-21T10:00:00Z'),
  ('wot-0050058','WOT0050058','ord-0012865','Genehmigungen','PM','Done','Permits Team','2026-04-22T11:00:00Z'),
  ('wot-0050059','WOT0050059','ord-0012865','Tiefbau','CV','Done','Civil Works Team','2026-04-27T14:00:00Z'),
  ('wot-0050060','WOT0050060','ord-0012865','Spleißen','SP','Done','Fiber Ops Team','2026-05-01T10:00:00Z'),
  ('wot-0050061','WOT0050061','ord-0012865','Einblasen','BF','Done','Fiber Ops Team','2026-05-01T14:00:00Z'),
  ('wot-0050062','WOT0050062','ord-0012865','Gartenbohrung','GD','Done','Drilling Team','2026-04-30T09:00:00Z'),
  ('wot-0050063','WOT0050063','ord-0012865','Hauseinführung','WB','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050064','WOT0050064','ord-0012865','HÜP','HÜP','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050065','WOT0050065','ord-0012865','Leitungsweg NE4','CW4','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050066','WOT0050066','ord-0012865','GFTA','GFTA','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050067','WOT0050067','ord-0012865','ONT','ONT','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050068','WOT0050068','ord-0012865','Patch','PCH','Pending Dispatch','','2026-05-09T09:00:00Z');

-- ORD0012853 (tasks 69-85): status 103 in progress, SDU-GFTAL-NE4
-- Pattern: GIS/LLD/PM/CV done; Spleißen WIP; rest Assigned or Pending
INSERT INTO wm_task VALUES
  ('wot-0050069','WOT0050069','ord-0012853','HV-S','HV','Done','Field Ops Team B','2026-05-01T10:00:00Z'),
  ('wot-0050070','WOT0050070','ord-0012853','UV-S','UV','not applicable','','2026-05-01T10:00:00Z'),
  ('wot-0050071','WOT0050071','ord-0012853','HV-NE4','HV4','Done','Field Ops Team B','2026-05-02T10:00:00Z'),
  ('wot-0050072','WOT0050072','ord-0012853','UV-NE4','UV4','not applicable','','2026-05-01T10:00:00Z'),
  ('wot-0050073','WOT0050073','ord-0012853','GIS Planung','GP','Done','GIS Team','2026-04-18T09:00:00Z'),
  ('wot-0050074','WOT0050074','ord-0012853','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-19T10:00:00Z'),
  ('wot-0050075','WOT0050075','ord-0012853','Genehmigungen','PM','Done','Permits Team','2026-04-21T11:00:00Z'),
  ('wot-0050076','WOT0050076','ord-0012853','Tiefbau','CV','Done','Civil Works Team','2026-04-25T14:00:00Z'),
  ('wot-0050077','WOT0050077','ord-0012853','Spleißen','SP','Work In Progress','Fiber Ops Team','2026-05-10T08:00:00Z'),
  ('wot-0050078','WOT0050078','ord-0012853','Einblasen','BF','Assigned','Fiber Ops Team','2026-05-07T09:00:00Z'),
  ('wot-0050079','WOT0050079','ord-0012853','Gartenbohrung','GD','Done','Drilling Team','2026-04-29T10:00:00Z'),
  ('wot-0050080','WOT0050080','ord-0012853','Hauseinführung','WB','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050081','WOT0050081','ord-0012853','HÜP','HÜP','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050082','WOT0050082','ord-0012853','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050083','WOT0050083','ord-0012853','GFTA','GFTA','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050084','WOT0050084','ord-0012853','ONT','ONT','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050085','WOT0050085','ord-0012853','Patch','PCH','Pending Dispatch','','2026-05-09T09:00:00Z');

-- ORD0012849 (tasks 86-102): status 103 in progress, SDU-GFTAL-HTP
-- HTP: HV-NE4, UV-NE4, Leitungsweg NE4 not applicable
-- Pattern: GIS/LLD/PM done; Tiefbau WIP; rest Pending
INSERT INTO wm_task VALUES
  ('wot-0050086','WOT0050086','ord-0012849','HV-S','HV','Done','Field Ops Team C','2026-04-29T10:00:00Z'),
  ('wot-0050087','WOT0050087','ord-0012849','UV-S','UV','not applicable','','2026-04-29T10:00:00Z'),
  ('wot-0050088','WOT0050088','ord-0012849','HV-NE4','HV4','not applicable','','2026-04-29T10:00:00Z'),
  ('wot-0050089','WOT0050089','ord-0012849','UV-NE4','UV4','not applicable','','2026-04-29T10:00:00Z'),
  ('wot-0050090','WOT0050090','ord-0012849','GIS Planung','GP','Done','GIS Team','2026-04-15T09:00:00Z'),
  ('wot-0050091','WOT0050091','ord-0012849','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-16T10:00:00Z'),
  ('wot-0050092','WOT0050092','ord-0012849','Genehmigungen','PM','Done','Permits Team','2026-04-18T11:00:00Z'),
  ('wot-0050093','WOT0050093','ord-0012849','Tiefbau','CV','Work In Progress','Civil Works Team','2026-05-11T07:00:00Z'),
  ('wot-0050094','WOT0050094','ord-0012849','Spleißen','SP','Assigned','Fiber Ops Team','2026-05-08T09:00:00Z'),
  ('wot-0050095','WOT0050095','ord-0012849','Einblasen','BF','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050096','WOT0050096','ord-0012849','Gartenbohrung','GD','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050097','WOT0050097','ord-0012849','Hauseinführung','WB','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050098','WOT0050098','ord-0012849','HÜP','HÜP','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050099','WOT0050099','ord-0012849','Leitungsweg NE4','CW4','not applicable','','2026-04-29T10:00:00Z'),
  ('wot-0050100','WOT0050100','ord-0012849','GFTA','GFTA','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050101','WOT0050101','ord-0012849','ONT','ONT','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050102','WOT0050102','ord-0012849','Patch','PCH','Pending Dispatch','','2026-05-09T09:00:00Z');

-- ORD0012848 (tasks 103-119): status 108 Fallout, Genehmigungen Problem, SDU-GFTAL-NE4
-- Pattern: GIS/LLD Done; Genehmigungen = Problem; rest Pending Dispatch
INSERT INTO wm_task VALUES
  ('wot-0050103','WOT0050103','ord-0012848','HV-S','HV','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050104','WOT0050104','ord-0012848','UV-S','UV','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050105','WOT0050105','ord-0012848','HV-NE4','HV4','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050106','WOT0050106','ord-0012848','UV-NE4','UV4','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050107','WOT0050107','ord-0012848','GIS Planung','GP','Done','GIS Team','2026-04-20T09:00:00Z'),
  ('wot-0050108','WOT0050108','ord-0012848','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-22T10:00:00Z'),
  ('wot-0050109','WOT0050109','ord-0012848','Genehmigungen','PM','Problem','Permits Team','2026-05-13T14:00:00Z'),
  ('wot-0050110','WOT0050110','ord-0012848','Tiefbau','CV','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050111','WOT0050111','ord-0012848','Spleißen','SP','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050112','WOT0050112','ord-0012848','Einblasen','BF','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050113','WOT0050113','ord-0012848','Gartenbohrung','GD','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050114','WOT0050114','ord-0012848','Hauseinführung','WB','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050115','WOT0050115','ord-0012848','HÜP','HÜP','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050116','WOT0050116','ord-0012848','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050117','WOT0050117','ord-0012848','GFTA','GFTA','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050118','WOT0050118','ord-0012848','ONT','ONT','Pending Dispatch','','2026-05-05T09:00:00Z'),
  ('wot-0050119','WOT0050119','ord-0012848','Patch','PCH','Pending Dispatch','','2026-05-05T09:00:00Z');

-- ORD0012846 (tasks 120-136): status 108 Fallout, Tiefbau Problem, SDU-GFTAL-NE4
-- Pattern: GIS/LLD/PM Done; Tiefbau = Problem; rest Pending Dispatch
INSERT INTO wm_task VALUES
  ('wot-0050120','WOT0050120','ord-0012846','HV-S','HV','Done','Field Ops Team A','2026-04-30T10:00:00Z'),
  ('wot-0050121','WOT0050121','ord-0012846','UV-S','UV','not applicable','','2026-04-30T10:00:00Z'),
  ('wot-0050122','WOT0050122','ord-0012846','HV-NE4','HV4','Done','Field Ops Team A','2026-05-01T10:00:00Z'),
  ('wot-0050123','WOT0050123','ord-0012846','UV-NE4','UV4','not applicable','','2026-04-30T10:00:00Z'),
  ('wot-0050124','WOT0050124','ord-0012846','GIS Planung','GP','Done','GIS Team','2026-04-18T09:00:00Z'),
  ('wot-0050125','WOT0050125','ord-0012846','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-19T10:00:00Z'),
  ('wot-0050126','WOT0050126','ord-0012846','Genehmigungen','PM','Done','Permits Team','2026-04-21T11:00:00Z'),
  ('wot-0050127','WOT0050127','ord-0012846','Tiefbau','CV','Problem','Civil Works Team','2026-05-12T16:00:00Z'),
  ('wot-0050128','WOT0050128','ord-0012846','Spleißen','SP','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050129','WOT0050129','ord-0012846','Einblasen','BF','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050130','WOT0050130','ord-0012846','Gartenbohrung','GD','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050131','WOT0050131','ord-0012846','Hauseinführung','WB','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050132','WOT0050132','ord-0012846','HÜP','HÜP','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050133','WOT0050133','ord-0012846','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050134','WOT0050134','ord-0012846','GFTA','GFTA','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050135','WOT0050135','ord-0012846','ONT','ONT','Pending Dispatch','','2026-05-04T09:00:00Z'),
  ('wot-0050136','WOT0050136','ord-0012846','Patch','PCH','Pending Dispatch','','2026-05-04T09:00:00Z');

-- ORD0012845 (tasks 137-153): status 101 Open, All Pending Dispatch, SDU-GFTAL-NE4
-- Pattern: all applicable tasks = Pending Dispatch; UV-S/UV-NE4 not applicable (SDU)
INSERT INTO wm_task VALUES
  ('wot-0050137','WOT0050137','ord-0012845','HV-S','HV','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050138','WOT0050138','ord-0012845','UV-S','UV','not applicable','','2026-05-12T09:00:00Z'),
  ('wot-0050139','WOT0050139','ord-0012845','HV-NE4','HV4','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050140','WOT0050140','ord-0012845','UV-NE4','UV4','not applicable','','2026-05-12T09:00:00Z'),
  ('wot-0050141','WOT0050141','ord-0012845','GIS Planung','GP','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050142','WOT0050142','ord-0012845','Fremdleitungsplan','LLD','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050143','WOT0050143','ord-0012845','Genehmigungen','PM','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050144','WOT0050144','ord-0012845','Tiefbau','CV','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050145','WOT0050145','ord-0012845','Spleißen','SP','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050146','WOT0050146','ord-0012845','Einblasen','BF','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050147','WOT0050147','ord-0012845','Gartenbohrung','GD','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050148','WOT0050148','ord-0012845','Hauseinführung','WB','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050149','WOT0050149','ord-0012845','HÜP','HÜP','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050150','WOT0050150','ord-0012845','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050151','WOT0050151','ord-0012845','GFTA','GFTA','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050152','WOT0050152','ord-0012845','ONT','ONT','Pending Dispatch','','2026-05-12T09:00:00Z'),
  ('wot-0050153','WOT0050153','ord-0012845','Patch','PCH','Pending Dispatch','','2026-05-12T09:00:00Z');

-- ORD0012844 (tasks 154-170): status 101 Open, All Pending Dispatch, SDU-GFTAL-NE4
INSERT INTO wm_task VALUES
  ('wot-0050154','WOT0050154','ord-0012844','HV-S','HV','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050155','WOT0050155','ord-0012844','UV-S','UV','not applicable','','2026-05-13T10:00:00Z'),
  ('wot-0050156','WOT0050156','ord-0012844','HV-NE4','HV4','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050157','WOT0050157','ord-0012844','UV-NE4','UV4','not applicable','','2026-05-13T10:00:00Z'),
  ('wot-0050158','WOT0050158','ord-0012844','GIS Planung','GP','Draft','GIS Team','2026-05-13T10:00:00Z'),
  ('wot-0050159','WOT0050159','ord-0012844','Fremdleitungsplan','LLD','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050160','WOT0050160','ord-0012844','Genehmigungen','PM','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050161','WOT0050161','ord-0012844','Tiefbau','CV','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050162','WOT0050162','ord-0012844','Spleißen','SP','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050163','WOT0050163','ord-0012844','Einblasen','BF','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050164','WOT0050164','ord-0012844','Gartenbohrung','GD','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050165','WOT0050165','ord-0012844','Hauseinführung','WB','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050166','WOT0050166','ord-0012844','HÜP','HÜP','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050167','WOT0050167','ord-0012844','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050168','WOT0050168','ord-0012844','GFTA','GFTA','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050169','WOT0050169','ord-0012844','ONT','ONT','Pending Dispatch','','2026-05-13T10:00:00Z'),
  ('wot-0050170','WOT0050170','ord-0012844','Patch','PCH','Pending Dispatch','','2026-05-13T10:00:00Z');

-- ORD0012843 (tasks 171-187): status 102 in progress, Scheduled house visit, SDU-GFTAL-NE4
-- Pattern: GIS/LLD Done; HV-S Scheduled; rest Pending Dispatch
INSERT INTO wm_task VALUES
  ('wot-0050171','WOT0050171','ord-0012843','HV-S','HV','Scheduled','Field Ops Team B','2026-05-16T10:00:00Z'),
  ('wot-0050172','WOT0050172','ord-0012843','UV-S','UV','not applicable','','2026-05-10T09:00:00Z'),
  ('wot-0050173','WOT0050173','ord-0012843','HV-NE4','HV4','Scheduled','Field Ops Team B','2026-05-17T10:00:00Z'),
  ('wot-0050174','WOT0050174','ord-0012843','UV-NE4','UV4','not applicable','','2026-05-10T09:00:00Z'),
  ('wot-0050175','WOT0050175','ord-0012843','GIS Planung','GP','Done','GIS Team','2026-04-28T09:00:00Z'),
  ('wot-0050176','WOT0050176','ord-0012843','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-29T10:00:00Z'),
  ('wot-0050177','WOT0050177','ord-0012843','Genehmigungen','PM','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050178','WOT0050178','ord-0012843','Tiefbau','CV','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050179','WOT0050179','ord-0012843','Spleißen','SP','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050180','WOT0050180','ord-0012843','Einblasen','BF','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050181','WOT0050181','ord-0012843','Gartenbohrung','GD','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050182','WOT0050182','ord-0012843','Hauseinführung','WB','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050183','WOT0050183','ord-0012843','HÜP','HÜP','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050184','WOT0050184','ord-0012843','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050185','WOT0050185','ord-0012843','GFTA','GFTA','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050186','WOT0050186','ord-0012843','ONT','ONT','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050187','WOT0050187','ord-0012843','Patch','PCH','Pending Dispatch','','2026-05-10T09:00:00Z');

-- ORD0012842 (tasks 188-204): status 109 Cancellation in progress, Mostly Done, SDU-GFTAL-HTP
-- HTP: HV-NE4, UV-NE4, Leitungsweg NE4 not applicable
-- Cancellation: ONT + Patch become not applicable (cancelled before activation)
INSERT INTO wm_task VALUES
  ('wot-0050188','WOT0050188','ord-0012842','HV-S','HV','Done','Field Ops Team C','2026-04-20T10:00:00Z'),
  ('wot-0050189','WOT0050189','ord-0012842','UV-S','UV','not applicable','','2026-04-20T10:00:00Z'),
  ('wot-0050190','WOT0050190','ord-0012842','HV-NE4','HV4','not applicable','','2026-04-20T10:00:00Z'),
  ('wot-0050191','WOT0050191','ord-0012842','UV-NE4','UV4','not applicable','','2026-04-20T10:00:00Z'),
  ('wot-0050192','WOT0050192','ord-0012842','GIS Planung','GP','Done','GIS Team','2026-04-05T09:00:00Z'),
  ('wot-0050193','WOT0050193','ord-0012842','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-06T10:00:00Z'),
  ('wot-0050194','WOT0050194','ord-0012842','Genehmigungen','PM','Done','Permits Team','2026-04-08T11:00:00Z'),
  ('wot-0050195','WOT0050195','ord-0012842','Tiefbau','CV','Done','Civil Works Team','2026-04-12T14:00:00Z'),
  ('wot-0050196','WOT0050196','ord-0012842','Spleißen','SP','Done','Fiber Ops Team','2026-04-16T10:00:00Z'),
  ('wot-0050197','WOT0050197','ord-0012842','Einblasen','BF','Done','Fiber Ops Team','2026-04-17T11:00:00Z'),
  ('wot-0050198','WOT0050198','ord-0012842','Gartenbohrung','GD','Done','Drilling Team','2026-04-18T09:00:00Z'),
  ('wot-0050199','WOT0050199','ord-0012842','Hauseinführung','WB','Done','Install Team','2026-04-19T14:00:00Z'),
  ('wot-0050200','WOT0050200','ord-0012842','HÜP','HÜP','Done','Install Team','2026-04-20T09:00:00Z'),
  ('wot-0050201','WOT0050201','ord-0012842','Leitungsweg NE4','CW4','not applicable','','2026-04-20T10:00:00Z'),
  ('wot-0050202','WOT0050202','ord-0012842','GFTA','GFTA','Done','Install Team','2026-04-20T09:00:00Z'),
  ('wot-0050203','WOT0050203','ord-0012842','ONT','ONT','not applicable','','2026-04-20T10:00:00Z'),
  ('wot-0050204','WOT0050204','ord-0012842','Patch','PCH','not applicable','','2026-04-20T10:00:00Z');

-- ORD0012841 (tasks 205-221): status 103 in progress, MDU pattern, MDU-GFTAL-NE4, 4 units
-- MDU: HV-S not applicable; UV-S + UV-NE4 apply; GFTA applies
-- Pattern: GIS/LLD/PM/CV Done; UV-S/UV-NE4 Assigned; rest Pending
INSERT INTO wm_task VALUES
  ('wot-0050205','WOT0050205','ord-0012841','HV-S','HV','not applicable','','2026-05-03T09:00:00Z'),
  ('wot-0050206','WOT0050206','ord-0012841','UV-S','UV','Assigned','MDU Field Ops Team','2026-05-08T09:00:00Z'),
  ('wot-0050207','WOT0050207','ord-0012841','HV-NE4','HV4','not applicable','','2026-05-03T09:00:00Z'),
  ('wot-0050208','WOT0050208','ord-0012841','UV-NE4','UV4','Assigned','MDU Field Ops Team','2026-05-08T09:00:00Z'),
  ('wot-0050209','WOT0050209','ord-0012841','GIS Planung','GP','Done','GIS Team','2026-04-22T09:00:00Z'),
  ('wot-0050210','WOT0050210','ord-0012841','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-23T10:00:00Z'),
  ('wot-0050211','WOT0050211','ord-0012841','Genehmigungen','PM','Done','Permits Team','2026-04-25T11:00:00Z'),
  ('wot-0050212','WOT0050212','ord-0012841','Tiefbau','CV','Done','Civil Works Team','2026-04-30T14:00:00Z'),
  ('wot-0050213','WOT0050213','ord-0012841','Spleißen','SP','Done','Fiber Ops Team','2026-05-03T10:00:00Z'),
  ('wot-0050214','WOT0050214','ord-0012841','Einblasen','BF','Done','Fiber Ops Team','2026-05-03T14:00:00Z'),
  ('wot-0050215','WOT0050215','ord-0012841','Gartenbohrung','GD','Done','Drilling Team','2026-05-02T09:00:00Z'),
  ('wot-0050216','WOT0050216','ord-0012841','Hauseinführung','WB','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050217','WOT0050217','ord-0012841','HÜP','HÜP','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050218','WOT0050218','ord-0012841','Leitungsweg NE4','CW4','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050219','WOT0050219','ord-0012841','GFTA','GFTA','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050220','WOT0050220','ord-0012841','ONT','ONT','Pending Dispatch','','2026-05-09T09:00:00Z'),
  ('wot-0050221','WOT0050221','ord-0012841','Patch','PCH','Pending Dispatch','','2026-05-09T09:00:00Z');

-- ORD0012840 (tasks 222-238): status 103 in progress, MDU-PHA Full Expansion-NE4, 6 units
-- MDU: HV-S not applicable; UV-S + UV-NE4 apply
-- Pattern: GIS/LLD/PM Done; Tiefbau Done; UV-S Work In Progress; rest Assigned
INSERT INTO wm_task VALUES
  ('wot-0050222','WOT0050222','ord-0012840','HV-S','HV','not applicable','','2026-05-04T09:00:00Z'),
  ('wot-0050223','WOT0050223','ord-0012840','UV-S','UV','Work In Progress','MDU Field Ops Team','2026-05-12T08:00:00Z'),
  ('wot-0050224','WOT0050224','ord-0012840','HV-NE4','HV4','not applicable','','2026-05-04T09:00:00Z'),
  ('wot-0050225','WOT0050225','ord-0012840','UV-NE4','UV4','Work In Progress','MDU Field Ops Team','2026-05-12T08:00:00Z'),
  ('wot-0050226','WOT0050226','ord-0012840','GIS Planung','GP','Done','GIS Team','2026-04-24T09:00:00Z'),
  ('wot-0050227','WOT0050227','ord-0012840','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-25T10:00:00Z'),
  ('wot-0050228','WOT0050228','ord-0012840','Genehmigungen','PM','Done','Permits Team','2026-04-27T11:00:00Z'),
  ('wot-0050229','WOT0050229','ord-0012840','Tiefbau','CV','Done','Civil Works Team','2026-05-04T14:00:00Z'),
  ('wot-0050230','WOT0050230','ord-0012840','Spleißen','SP','Done','Fiber Ops Team','2026-05-07T10:00:00Z'),
  ('wot-0050231','WOT0050231','ord-0012840','Einblasen','BF','Done','Fiber Ops Team','2026-05-07T14:00:00Z'),
  ('wot-0050232','WOT0050232','ord-0012840','Gartenbohrung','GD','Done','Drilling Team','2026-05-06T09:00:00Z'),
  ('wot-0050233','WOT0050233','ord-0012840','Hauseinführung','WB','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050234','WOT0050234','ord-0012840','HÜP','HÜP','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050235','WOT0050235','ord-0012840','Leitungsweg NE4','CW4','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050236','WOT0050236','ord-0012840','GFTA','GFTA','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050237','WOT0050237','ord-0012840','ONT','ONT','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050238','WOT0050238','ord-0012840','Patch','PCH','Pending Dispatch','','2026-05-10T09:00:00Z');

-- ORD0012839 (tasks 239-255): status 102 in progress, Spleißen WIP, SDU-GFTAL-NE4
-- Pattern: GIS/LLD/PM/CV/HV-S Done; Spleißen WIP; rest Pending
INSERT INTO wm_task VALUES
  ('wot-0050239','WOT0050239','ord-0012839','HV-S','HV','Done','Field Ops Team A','2026-04-29T10:00:00Z'),
  ('wot-0050240','WOT0050240','ord-0012839','UV-S','UV','not applicable','','2026-05-06T09:00:00Z'),
  ('wot-0050241','WOT0050241','ord-0012839','HV-NE4','HV4','Done','Field Ops Team A','2026-04-30T10:00:00Z'),
  ('wot-0050242','WOT0050242','ord-0012839','UV-NE4','UV4','not applicable','','2026-05-06T09:00:00Z'),
  ('wot-0050243','WOT0050243','ord-0012839','GIS Planung','GP','Done','GIS Team','2026-04-16T09:00:00Z'),
  ('wot-0050244','WOT0050244','ord-0012839','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-17T10:00:00Z'),
  ('wot-0050245','WOT0050245','ord-0012839','Genehmigungen','PM','Done','Permits Team','2026-04-19T11:00:00Z'),
  ('wot-0050246','WOT0050246','ord-0012839','Tiefbau','CV','Done','Civil Works Team','2026-04-24T14:00:00Z'),
  ('wot-0050247','WOT0050247','ord-0012839','Spleißen','SP','Work In Progress','Fiber Ops Team','2026-05-13T07:30:00Z'),
  ('wot-0050248','WOT0050248','ord-0012839','Einblasen','BF','Assigned','Fiber Ops Team','2026-05-06T09:00:00Z'),
  ('wot-0050249','WOT0050249','ord-0012839','Gartenbohrung','GD','Done','Drilling Team','2026-04-28T09:00:00Z'),
  ('wot-0050250','WOT0050250','ord-0012839','Hauseinführung','WB','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050251','WOT0050251','ord-0012839','HÜP','HÜP','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050252','WOT0050252','ord-0012839','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050253','WOT0050253','ord-0012839','GFTA','GFTA','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050254','WOT0050254','ord-0012839','ONT','ONT','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050255','WOT0050255','ord-0012839','Patch','PCH','Pending Dispatch','','2026-05-06T09:00:00Z');

-- ORD0012838 (tasks 256-272): status 101 Open, Draft phase, SDU-GFTAL-NE4
-- Pattern: GIS Planung Draft; rest Pending Dispatch
INSERT INTO wm_task VALUES
  ('wot-0050256','WOT0050256','ord-0012838','HV-S','HV','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050257','WOT0050257','ord-0012838','UV-S','UV','not applicable','','2026-05-14T09:00:00Z'),
  ('wot-0050258','WOT0050258','ord-0012838','HV-NE4','HV4','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050259','WOT0050259','ord-0012838','UV-NE4','UV4','not applicable','','2026-05-14T09:00:00Z'),
  ('wot-0050260','WOT0050260','ord-0012838','GIS Planung','GP','Draft','GIS Team','2026-05-14T09:00:00Z'),
  ('wot-0050261','WOT0050261','ord-0012838','Fremdleitungsplan','LLD','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050262','WOT0050262','ord-0012838','Genehmigungen','PM','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050263','WOT0050263','ord-0012838','Tiefbau','CV','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050264','WOT0050264','ord-0012838','Spleißen','SP','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050265','WOT0050265','ord-0012838','Einblasen','BF','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050266','WOT0050266','ord-0012838','Gartenbohrung','GD','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050267','WOT0050267','ord-0012838','Hauseinführung','WB','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050268','WOT0050268','ord-0012838','HÜP','HÜP','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050269','WOT0050269','ord-0012838','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050270','WOT0050270','ord-0012838','GFTA','GFTA','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050271','WOT0050271','ord-0012838','ONT','ONT','Pending Dispatch','','2026-05-14T09:00:00Z'),
  ('wot-0050272','WOT0050272','ord-0012838','Patch','PCH','Pending Dispatch','','2026-05-14T09:00:00Z');

-- ORD0012837 (tasks 273-289): status 101 Open, Draft phase, SDU-GFTAL-HTP
-- HTP: HV-NE4, UV-NE4, Leitungsweg NE4 not applicable
-- Pattern: GIS Planung Draft; Fremdleitungsplan Draft; rest Pending Dispatch
INSERT INTO wm_task VALUES
  ('wot-0050273','WOT0050273','ord-0012837','HV-S','HV','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050274','WOT0050274','ord-0012837','UV-S','UV','not applicable','','2026-05-13T14:00:00Z'),
  ('wot-0050275','WOT0050275','ord-0012837','HV-NE4','HV4','not applicable','','2026-05-13T14:00:00Z'),
  ('wot-0050276','WOT0050276','ord-0012837','UV-NE4','UV4','not applicable','','2026-05-13T14:00:00Z'),
  ('wot-0050277','WOT0050277','ord-0012837','GIS Planung','GP','Draft','GIS Team','2026-05-13T14:00:00Z'),
  ('wot-0050278','WOT0050278','ord-0012837','Fremdleitungsplan','LLD','Draft','GIS Team','2026-05-13T14:00:00Z'),
  ('wot-0050279','WOT0050279','ord-0012837','Genehmigungen','PM','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050280','WOT0050280','ord-0012837','Tiefbau','CV','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050281','WOT0050281','ord-0012837','Spleißen','SP','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050282','WOT0050282','ord-0012837','Einblasen','BF','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050283','WOT0050283','ord-0012837','Gartenbohrung','GD','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050284','WOT0050284','ord-0012837','Hauseinführung','WB','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050285','WOT0050285','ord-0012837','HÜP','HÜP','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050286','WOT0050286','ord-0012837','Leitungsweg NE4','CW4','not applicable','','2026-05-13T14:00:00Z'),
  ('wot-0050287','WOT0050287','ord-0012837','GFTA','GFTA','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050288','WOT0050288','ord-0012837','ONT','ONT','Pending Dispatch','','2026-05-13T14:00:00Z'),
  ('wot-0050289','WOT0050289','ord-0012837','Patch','PCH','Pending Dispatch','','2026-05-13T14:00:00Z');

-- ORD0012836 (tasks 290-306): status 103 in progress, HÜP Done, Hauseinführung Problem, SDU-GFTAL-NE4
-- Pattern: GIS/LLD/PM/CV/Spleißen/Einblasen/Gartenbohrung Done; HÜP Done; Hauseinführung Problem; rest Assigned
INSERT INTO wm_task VALUES
  ('wot-0050290','WOT0050290','ord-0012836','HV-S','HV','Done','Field Ops Team B','2026-04-30T10:00:00Z'),
  ('wot-0050291','WOT0050291','ord-0012836','UV-S','UV','not applicable','','2026-05-07T09:00:00Z'),
  ('wot-0050292','WOT0050292','ord-0012836','HV-NE4','HV4','Done','Field Ops Team B','2026-05-01T10:00:00Z'),
  ('wot-0050293','WOT0050293','ord-0012836','UV-NE4','UV4','not applicable','','2026-05-07T09:00:00Z'),
  ('wot-0050294','WOT0050294','ord-0012836','GIS Planung','GP','Done','GIS Team','2026-04-17T09:00:00Z'),
  ('wot-0050295','WOT0050295','ord-0012836','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-18T10:00:00Z'),
  ('wot-0050296','WOT0050296','ord-0012836','Genehmigungen','PM','Done','Permits Team','2026-04-20T11:00:00Z'),
  ('wot-0050297','WOT0050297','ord-0012836','Tiefbau','CV','Done','Civil Works Team','2026-04-25T14:00:00Z'),
  ('wot-0050298','WOT0050298','ord-0012836','Spleißen','SP','Done','Fiber Ops Team','2026-04-29T10:00:00Z'),
  ('wot-0050299','WOT0050299','ord-0012836','Einblasen','BF','Done','Fiber Ops Team','2026-04-29T14:00:00Z'),
  ('wot-0050300','WOT0050300','ord-0012836','Gartenbohrung','GD','Done','Drilling Team','2026-04-28T09:00:00Z'),
  ('wot-0050301','WOT0050301','ord-0012836','Hauseinführung','WB','Problem','Install Team','2026-05-13T11:00:00Z'),
  ('wot-0050302','WOT0050302','ord-0012836','HÜP','HÜP','Done','Install Team','2026-05-05T10:00:00Z'),
  ('wot-0050303','WOT0050303','ord-0012836','Leitungsweg NE4','CW4','Assigned','Install Team','2026-05-07T09:00:00Z'),
  ('wot-0050304','WOT0050304','ord-0012836','GFTA','GFTA','Pending Dispatch','','2026-05-08T09:00:00Z'),
  ('wot-0050305','WOT0050305','ord-0012836','ONT','ONT','Pending Dispatch','','2026-05-08T09:00:00Z'),
  ('wot-0050306','WOT0050306','ord-0012836','Patch','PCH','Pending Dispatch','','2026-05-08T09:00:00Z');

-- ORD0012835 (tasks 307-323): status 103 in progress, Two parallel Problems, SDU-GFTAL-NE4
-- Pattern: GIS/LLD Done; Genehmigungen Problem; Tiefbau Problem; rest Pending Dispatch
INSERT INTO wm_task VALUES
  ('wot-0050307','WOT0050307','ord-0012835','HV-S','HV','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050308','WOT0050308','ord-0012835','UV-S','UV','not applicable','','2026-05-06T09:00:00Z'),
  ('wot-0050309','WOT0050309','ord-0012835','HV-NE4','HV4','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050310','WOT0050310','ord-0012835','UV-NE4','UV4','not applicable','','2026-05-06T09:00:00Z'),
  ('wot-0050311','WOT0050311','ord-0012835','GIS Planung','GP','Done','GIS Team','2026-04-22T09:00:00Z'),
  ('wot-0050312','WOT0050312','ord-0012835','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-23T10:00:00Z'),
  ('wot-0050313','WOT0050313','ord-0012835','Genehmigungen','PM','Problem','Permits Team','2026-05-11T15:00:00Z'),
  ('wot-0050314','WOT0050314','ord-0012835','Tiefbau','CV','Problem','Civil Works Team','2026-05-12T09:00:00Z'),
  ('wot-0050315','WOT0050315','ord-0012835','Spleißen','SP','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050316','WOT0050316','ord-0012835','Einblasen','BF','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050317','WOT0050317','ord-0012835','Gartenbohrung','GD','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050318','WOT0050318','ord-0012835','Hauseinführung','WB','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050319','WOT0050319','ord-0012835','HÜP','HÜP','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050320','WOT0050320','ord-0012835','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050321','WOT0050321','ord-0012835','GFTA','GFTA','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050322','WOT0050322','ord-0012835','ONT','ONT','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050323','WOT0050323','ord-0012835','Patch','PCH','Pending Dispatch','','2026-05-06T09:00:00Z');

-- ORD0012834 (tasks 324-340): status 102 in progress, healthy mid-flow, SDU-GFTAL-NE4
-- Pattern: GIS/LLD/PM Done; HV-S Done; Tiefbau Work In Progress; rest Assigned/Pending
INSERT INTO wm_task VALUES
  ('wot-0050324','WOT0050324','ord-0012834','HV-S','HV','Done','Field Ops Team A','2026-05-03T10:00:00Z'),
  ('wot-0050325','WOT0050325','ord-0012834','UV-S','UV','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050326','WOT0050326','ord-0012834','HV-NE4','HV4','Done','Field Ops Team A','2026-05-04T10:00:00Z'),
  ('wot-0050327','WOT0050327','ord-0012834','UV-NE4','UV4','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050328','WOT0050328','ord-0012834','GIS Planung','GP','Done','GIS Team','2026-04-21T09:00:00Z'),
  ('wot-0050329','WOT0050329','ord-0012834','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-22T10:00:00Z'),
  ('wot-0050330','WOT0050330','ord-0012834','Genehmigungen','PM','Done','Permits Team','2026-04-24T11:00:00Z'),
  ('wot-0050331','WOT0050331','ord-0012834','Tiefbau','CV','Work In Progress','Civil Works Team','2026-05-13T06:30:00Z'),
  ('wot-0050332','WOT0050332','ord-0012834','Spleißen','SP','Assigned','Fiber Ops Team','2026-05-05T09:00:00Z'),
  ('wot-0050333','WOT0050333','ord-0012834','Einblasen','BF','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050334','WOT0050334','ord-0012834','Gartenbohrung','GD','Assigned','Drilling Team','2026-05-05T09:00:00Z'),
  ('wot-0050335','WOT0050335','ord-0012834','Hauseinführung','WB','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050336','WOT0050336','ord-0012834','HÜP','HÜP','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050337','WOT0050337','ord-0012834','Leitungsweg NE4','CW4','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050338','WOT0050338','ord-0012834','GFTA','GFTA','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050339','WOT0050339','ord-0012834','ONT','ONT','Pending Dispatch','','2026-05-06T09:00:00Z'),
  ('wot-0050340','WOT0050340','ord-0012834','Patch','PCH','Pending Dispatch','','2026-05-06T09:00:00Z');

-- ORD0012833 (tasks 341-357): status 102 in progress, healthy mid-flow, MDU-PHA Standard-NA
-- MDU: HV-S not applicable; UV-S applies; HV-NE4/UV-NE4 not applicable (Standard-NA set)
-- Pattern: GIS/LLD/PM Done; Tiefbau Done; Spleißen Done; UV-S Assigned; rest Assigned/Pending
INSERT INTO wm_task VALUES
  ('wot-0050341','WOT0050341','ord-0012833','HV-S','HV','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050342','WOT0050342','ord-0012833','UV-S','UV','Assigned','MDU Field Ops Team','2026-05-09T09:00:00Z'),
  ('wot-0050343','WOT0050343','ord-0012833','HV-NE4','HV4','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050344','WOT0050344','ord-0012833','UV-NE4','UV4','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050345','WOT0050345','ord-0012833','GIS Planung','GP','Done','GIS Team','2026-04-20T09:00:00Z'),
  ('wot-0050346','WOT0050346','ord-0012833','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-21T10:00:00Z'),
  ('wot-0050347','WOT0050347','ord-0012833','Genehmigungen','PM','Done','Permits Team','2026-04-23T11:00:00Z'),
  ('wot-0050348','WOT0050348','ord-0012833','Tiefbau','CV','Done','Civil Works Team','2026-04-28T14:00:00Z'),
  ('wot-0050349','WOT0050349','ord-0012833','Spleißen','SP','Done','Fiber Ops Team','2026-05-02T10:00:00Z'),
  ('wot-0050350','WOT0050350','ord-0012833','Einblasen','BF','Done','Fiber Ops Team','2026-05-02T14:00:00Z'),
  ('wot-0050351','WOT0050351','ord-0012833','Gartenbohrung','GD','Done','Drilling Team','2026-05-01T09:00:00Z'),
  ('wot-0050352','WOT0050352','ord-0012833','Hauseinführung','WB','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050353','WOT0050353','ord-0012833','HÜP','HÜP','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050354','WOT0050354','ord-0012833','Leitungsweg NE4','CW4','not applicable','','2026-05-05T09:00:00Z'),
  ('wot-0050355','WOT0050355','ord-0012833','GFTA','GFTA','Assigned','Install Team','2026-05-09T09:00:00Z'),
  ('wot-0050356','WOT0050356','ord-0012833','ONT','ONT','Pending Dispatch','','2026-05-10T09:00:00Z'),
  ('wot-0050357','WOT0050357','ord-0012833','Patch','PCH','Pending Dispatch','','2026-05-10T09:00:00Z');

-- ORD0012832 (tasks 358-374): status 105 in progress, MDU-GFTAL-NE4, 2 units
-- MDU: HV-S not applicable; UV-S + UV-NE4 apply
-- Pattern: all core infrastructure Done; UV-S/UV-NE4 Done; HÜP/Leitungsweg/GFTA Done; ONT Assigned; Patch Pending
INSERT INTO wm_task VALUES
  ('wot-0050358','WOT0050358','ord-0012832','HV-S','HV','not applicable','','2026-05-08T09:00:00Z'),
  ('wot-0050359','WOT0050359','ord-0012832','UV-S','UV','Done','MDU Field Ops Team','2026-05-06T10:00:00Z'),
  ('wot-0050360','WOT0050360','ord-0012832','HV-NE4','HV4','not applicable','','2026-05-08T09:00:00Z'),
  ('wot-0050361','WOT0050361','ord-0012832','UV-NE4','UV4','Done','MDU Field Ops Team','2026-05-06T11:00:00Z'),
  ('wot-0050362','WOT0050362','ord-0012832','GIS Planung','GP','Done','GIS Team','2026-04-15T09:00:00Z'),
  ('wot-0050363','WOT0050363','ord-0012832','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-16T10:00:00Z'),
  ('wot-0050364','WOT0050364','ord-0012832','Genehmigungen','PM','Done','Permits Team','2026-04-18T11:00:00Z'),
  ('wot-0050365','WOT0050365','ord-0012832','Tiefbau','CV','Done','Civil Works Team','2026-04-23T14:00:00Z'),
  ('wot-0050366','WOT0050366','ord-0012832','Spleißen','SP','Done','Fiber Ops Team','2026-04-28T10:00:00Z'),
  ('wot-0050367','WOT0050367','ord-0012832','Einblasen','BF','Done','Fiber Ops Team','2026-04-28T14:00:00Z'),
  ('wot-0050368','WOT0050368','ord-0012832','Gartenbohrung','GD','Done','Drilling Team','2026-04-27T09:00:00Z'),
  ('wot-0050369','WOT0050369','ord-0012832','Hauseinführung','WB','Done','Install Team','2026-05-02T14:00:00Z'),
  ('wot-0050370','WOT0050370','ord-0012832','HÜP','HÜP','Done','Install Team','2026-05-05T10:00:00Z'),
  ('wot-0050371','WOT0050371','ord-0012832','Leitungsweg NE4','CW4','Done','Install Team','2026-05-06T09:00:00Z'),
  ('wot-0050372','WOT0050372','ord-0012832','GFTA','GFTA','Done','Install Team','2026-05-06T14:00:00Z'),
  ('wot-0050373','WOT0050373','ord-0012832','ONT','ONT','Assigned','Install Team','2026-05-08T09:00:00Z'),
  ('wot-0050374','WOT0050374','ord-0012832','Patch','PCH','Pending Dispatch','','2026-05-09T09:00:00Z');

-- ORD0012831 (tasks 375-391): status 107 in progress, long-tail: only ONT + Patch left, SDU-GFTAL-NE4
-- Pattern: all tasks Done except ONT (Assigned) and Patch (Pending Dispatch)
INSERT INTO wm_task VALUES
  ('wot-0050375','WOT0050375','ord-0012831','HV-S','HV','Done','Field Ops Team C','2026-04-20T10:00:00Z'),
  ('wot-0050376','WOT0050376','ord-0012831','UV-S','UV','not applicable','','2026-05-10T09:00:00Z'),
  ('wot-0050377','WOT0050377','ord-0012831','HV-NE4','HV4','Done','Field Ops Team C','2026-04-21T10:00:00Z'),
  ('wot-0050378','WOT0050378','ord-0012831','UV-NE4','UV4','not applicable','','2026-05-10T09:00:00Z'),
  ('wot-0050379','WOT0050379','ord-0012831','GIS Planung','GP','Done','GIS Team','2026-04-05T09:00:00Z'),
  ('wot-0050380','WOT0050380','ord-0012831','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-06T10:00:00Z'),
  ('wot-0050381','WOT0050381','ord-0012831','Genehmigungen','PM','Done','Permits Team','2026-04-08T11:00:00Z'),
  ('wot-0050382','WOT0050382','ord-0012831','Tiefbau','CV','Done','Civil Works Team','2026-04-13T14:00:00Z'),
  ('wot-0050383','WOT0050383','ord-0012831','Spleißen','SP','Done','Fiber Ops Team','2026-04-17T10:00:00Z'),
  ('wot-0050384','WOT0050384','ord-0012831','Einblasen','BF','Done','Fiber Ops Team','2026-04-17T14:00:00Z'),
  ('wot-0050385','WOT0050385','ord-0012831','Gartenbohrung','GD','Done','Drilling Team','2026-04-16T09:00:00Z'),
  ('wot-0050386','WOT0050386','ord-0012831','Hauseinführung','WB','Done','Install Team','2026-04-20T14:00:00Z'),
  ('wot-0050387','WOT0050387','ord-0012831','HÜP','HÜP','Done','Install Team','2026-04-22T10:00:00Z'),
  ('wot-0050388','WOT0050388','ord-0012831','Leitungsweg NE4','CW4','Done','Install Team','2026-04-24T09:00:00Z'),
  ('wot-0050389','WOT0050389','ord-0012831','GFTA','GFTA','Done','Install Team','2026-04-26T14:00:00Z'),
  ('wot-0050390','WOT0050390','ord-0012831','ONT','ONT','Assigned','Install Team','2026-05-10T09:00:00Z'),
  ('wot-0050391','WOT0050391','ord-0012831','Patch','PCH','Pending Dispatch','','2026-05-11T09:00:00Z');

-- ORD0012830 (tasks 392-408): status 103 in progress, Multi-unit MDU, MDU-PHA Full Expansion-NE4, 8 units
-- MDU: HV-S not applicable; UV-S + UV-NE4 apply
-- Pattern: GIS/LLD/PM/CV Done; Spleißen/Einblasen Done; UV-S Assigned; UV-NE4 Assigned; Hauseinführung WIP; rest Pending
INSERT INTO wm_task VALUES
  ('wot-0050392','WOT0050392','ord-0012830','HV-S','HV','not applicable','','2026-05-06T09:00:00Z'),
  ('wot-0050393','WOT0050393','ord-0012830','UV-S','UV','Assigned','MDU Field Ops Team','2026-05-10T09:00:00Z'),
  ('wot-0050394','WOT0050394','ord-0012830','HV-NE4','HV4','not applicable','','2026-05-06T09:00:00Z'),
  ('wot-0050395','WOT0050395','ord-0012830','UV-NE4','UV4','Assigned','MDU Field Ops Team','2026-05-10T09:00:00Z'),
  ('wot-0050396','WOT0050396','ord-0012830','GIS Planung','GP','Done','GIS Team','2026-04-19T09:00:00Z'),
  ('wot-0050397','WOT0050397','ord-0012830','Fremdleitungsplan','LLD','Done','GIS Team','2026-04-20T10:00:00Z'),
  ('wot-0050398','WOT0050398','ord-0012830','Genehmigungen','PM','Done','Permits Team','2026-04-22T11:00:00Z'),
  ('wot-0050399','WOT0050399','ord-0012830','Tiefbau','CV','Done','Civil Works Team','2026-04-29T14:00:00Z'),
  ('wot-0050400','WOT0050400','ord-0012830','Spleißen','SP','Done','Fiber Ops Team','2026-05-05T10:00:00Z'),
  ('wot-0050401','WOT0050401','ord-0012830','Einblasen','BF','Done','Fiber Ops Team','2026-05-05T14:00:00Z'),
  ('wot-0050402','WOT0050402','ord-0012830','Gartenbohrung','GD','Done','Drilling Team','2026-05-04T09:00:00Z'),
  ('wot-0050403','WOT0050403','ord-0012830','Hauseinführung','WB','Work In Progress','Install Team','2026-05-14T07:00:00Z'),
  ('wot-0050404','WOT0050404','ord-0012830','HÜP','HÜP','Assigned','Install Team','2026-05-10T09:00:00Z'),
  ('wot-0050405','WOT0050405','ord-0012830','Leitungsweg NE4','CW4','Assigned','Install Team','2026-05-10T09:00:00Z'),
  ('wot-0050406','WOT0050406','ord-0012830','GFTA','GFTA','Pending Dispatch','','2026-05-11T09:00:00Z'),
  ('wot-0050407','WOT0050407','ord-0012830','ONT','ONT','Pending Dispatch','','2026-05-11T09:00:00Z'),
  ('wot-0050408','WOT0050408','ord-0012830','Patch','PCH','Pending Dispatch','','2026-05-11T09:00:00Z');

-- ORD0012828 (tasks 409-425): status 100 Completed, Reference happy-path, SDU-GFTAL-HTP
-- HTP: HV-NE4, UV-NE4, Leitungsweg NE4 not applicable
INSERT INTO wm_task VALUES
  ('wot-0050409','WOT0050409','ord-0012828','HV-S','HV','Done','Field Ops Team A','2026-04-15T10:00:00Z'),
  ('wot-0050410','WOT0050410','ord-0012828','UV-S','UV','not applicable','','2026-04-15T10:00:00Z'),
  ('wot-0050411','WOT0050411','ord-0012828','HV-NE4','HV4','not applicable','','2026-04-15T10:00:00Z'),
  ('wot-0050412','WOT0050412','ord-0012828','UV-NE4','UV4','not applicable','','2026-04-15T10:00:00Z'),
  ('wot-0050413','WOT0050413','ord-0012828','GIS Planung','GP','Done','GIS Team','2026-03-25T09:00:00Z'),
  ('wot-0050414','WOT0050414','ord-0012828','Fremdleitungsplan','LLD','Done','GIS Team','2026-03-26T10:00:00Z'),
  ('wot-0050415','WOT0050415','ord-0012828','Genehmigungen','PM','Done','Permits Team','2026-03-28T11:00:00Z'),
  ('wot-0050416','WOT0050416','ord-0012828','Tiefbau','CV','Done','Civil Works Team','2026-04-02T14:00:00Z'),
  ('wot-0050417','WOT0050417','ord-0012828','Spleißen','SP','Done','Fiber Ops Team','2026-04-07T10:00:00Z'),
  ('wot-0050418','WOT0050418','ord-0012828','Einblasen','BF','Done','Fiber Ops Team','2026-04-07T14:00:00Z'),
  ('wot-0050419','WOT0050419','ord-0012828','Gartenbohrung','GD','Done','Drilling Team','2026-04-06T09:00:00Z'),
  ('wot-0050420','WOT0050420','ord-0012828','Hauseinführung','WB','Done','Install Team','2026-04-10T14:00:00Z'),
  ('wot-0050421','WOT0050421','ord-0012828','HÜP','HÜP','Done','Install Team','2026-04-12T10:00:00Z'),
  ('wot-0050422','WOT0050422','ord-0012828','Leitungsweg NE4','CW4','not applicable','','2026-04-15T10:00:00Z'),
  ('wot-0050423','WOT0050423','ord-0012828','GFTA','GFTA','Done','Install Team','2026-04-13T14:00:00Z'),
  ('wot-0050424','WOT0050424','ord-0012828','ONT','ONT','Done','Install Team','2026-04-14T10:00:00Z'),
  ('wot-0050425','WOT0050425','ord-0012828','Patch','PCH','Done','Patch Team','2026-04-15T10:00:00Z');
