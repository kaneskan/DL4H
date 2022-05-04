/*clean up non-ICU from prescriptions*/
create table mimiciii.prescriptions_icu as select * from mimiciii.prescriptions;

delete from mimiciii.prescriptions_icu where icustay_id is null; 

/*gender, age, weight, height, religion, language, marital status, and ethnicity*/
create table mimiciii.lw_patient_id
as
(
select distinct hadm_id
from mimiciii.admissions
);

create table mimiciii.lw_patient_main
as
(
select  a.subject_id, a.hadm_id, a.religion, a."language", a.marital_status, a.ethnicity
from mimiciii.admissions a, mimiciii.lw_patient_id b where a.hadm_id=b.hadm_id
);

/*gender*/
create table mimiciii.lw_patient_gender
as
(
select a.subject_id, a.hadm_id, b.gender 
from mimiciii.admissions a 
left join mimiciii.patients b
on a.subject_id = b.subject_id
);

/*height*/
create table mimiciii.lw_patient_height_1
as (
select a.subject_id, a.hadm_id, b.value::numeric height
from 
mimiciii.admissions a
left join 
mimiciii.chartevents b
on a.hadm_id=b.hadm_id and  b.itemid = 226730
);

create table mimiciii.lw_patient_height
as
(
select a.subject_id, a.hadm_id, avg(a.height) height
from mimiciii.lw_patient_height_1 a
group by a.hadm_id,subject_id
);

/*weight*/
create table mimiciii.lw_patient_weight_1
as (
select a.subject_id, a.hadm_id, b.value::numeric weight
from 
mimiciii.admissions a
left join 
mimiciii.chartevents b
on a.hadm_id=b.hadm_id and  b.itemid = 3693
);

create table mimiciii.lw_patient_weight
as
(
select a.subject_id, a.hadm_id, avg(a.weight) weight
from mimiciii.lw_patient_weight_1 a
group by a.hadm_id,subject_id
);

/*age*/
create table mimiciii.lw_patient_age_1
as
(
select a.subject_id, a.hadm_id, a.admittime, b.dob 
from mimiciii.admissions a 
left join mimiciii.patients b
on a.subject_id = b.subject_id
);

create table  mimiciii.lw_patient_age
as(
select a.subject_id, a.hadm_id, date_part('day',a.admittime::timestamp-a.dob::timestamp)/365.28 age  from mimiciii.lw_patient_age_1 a
);

/*basic feature*/
create table mimiciii.lw_patient
as
(
select a.*, b.age, c.weight, d.height, e.religion, e.language, e.marital_status, e.ethnicity
from 
mimiciii.lw_patient_gender a,
mimiciii.lw_patient_age b,
mimiciii.lw_patient_weight c,
mimiciii.lw_patient_height d,
mimiciii.lw_patient_main e
where
a.hadm_id= b.hadm_id and
a.hadm_id= c.hadm_id and
a.hadm_id= d.hadm_id and
a.hadm_id= e.hadm_id 
);

create table mimiciii.lw_patient_copy as select * from mimiciii.lw_patient;

update mimiciii.lw_patient_copy 
set height = 177 
where gender = 'M' and height is null and age>=18 and age <=89;

update mimiciii.lw_patient_copy 
set height = 169.2 
where gender = 'F' and height is null and age>=18 and age <=89;

update mimiciii.lw_patient_copy 
set height = 0 
where height is null;

update mimiciii.lw_patient_copy 
set weight = 28.3 * (height/100) * (height/100)
where gender = 'M';

update mimiciii.lw_patient_copy 
set weight = 26.3 * (height/100) * (height/100)
where gender = 'F';

update mimiciii.lw_patient_copy 
set religion = 'CATHOLIC'
where religion is null;

update mimiciii.lw_patient_copy 
set language = 'ENGL'
where language is null;

update mimiciii.lw_patient_copy 
set marital_status = 'SINGLE'
where marital_status is null and ((gender = 'M' and age <31) or (gender = 'F' and age <28));

update mimiciii.lw_patient_copy 
set marital_status = 'MARRIED'
where marital_status is null and age<80;

update mimiciii.lw_patient_copy 
set marital_status = 'SINGLE'
where marital_status is null and age>=80;

update mimiciii.lw_patient_copy 
set ethnicity = 'WHITE'
where ethnicity is null;

create table mimiciii.lw_patient_static_variables
as select * from mimiciii.lw_patient_copy; 

/*/
 * TOP 1000 drug
 */
create table mimiciii.lw_drug_name_1000
as 
(
select distinct a.drug, count(*) num from  mimiciii.prescriptions_icu a group by drug order by num desc limit 1000
);

create table mimiciii.lw_drug_name_800
as 
(
select distinct a.drug, count(*) num from  mimiciii.prescriptions_icu a group by drug order by num desc limit 800
);

create table mimiciii.lw_drug_name_600
as 
(
select distinct a.drug, count(*) num from  mimiciii.prescriptions_icu a group by drug order by num desc limit 600
);

create table mimiciii.lw_drug_name_400
as 
(
select distinct a.drug, count(*) num from  mimiciii.prescriptions_icu a group by drug order by num desc limit 400
);

create table mimiciii.lw_drug_name_200
as 
(
select distinct a.drug, count(*) num from  mimiciii.prescriptions_icu a group by drug order by num desc limit 200
);

create table mimiciii.lw_drug_use_all 
as
(
select distinct a.hadm_id,a.startdate, a.drug from mimiciii.prescriptions_icu a order by a.hadm_id,a.startdate, a.drug asc
);

create table mimiciii.lw_drug_use_1000 
as
(
select distinct a.hadm_id,a.startdate, a.drug
from mimiciii.lw_drug_use_all a, mimiciii.lw_drug_name_1000 b
where a.drug=b.drug
order by a.hadm_id,a.startdate, a.drug asc
);

create table mimiciii.lw_drug_use_1000_1
as 
(select distinct hadm_id,startdate from mimiciii.lw_drug_use_1000);

CREATE INDEX lw_drug_use_1000_index1 ON mimiciii.lw_drug_use_1000_1 (hadm_id, startdate);  

CREATE INDEX lw_drug_use_1000_index2 ON mimiciii.lw_drug_use_1000_1 (hadm_id);  

CREATE INDEX lw_drug_use_1000_index3 ON mimiciii.lw_drug_use_1000_1 (startdate);  

CREATE INDEX lw_drug_use_1000_index4 ON mimiciii.lw_drug_use_1000_1 USING hash (hadm_id);

CREATE INDEX lw_drug_use_1000_index5 ON mimiciii.lw_drug_use_1000_1 USING hash (startdate);

/*TOP 400 drug*/

create table mimiciii.lw_drug_use_400
as
(
select distinct a.hadm_id,a.startdate, a.drug
from mimiciii.lw_drug_use_all a, mimiciii.lw_drug_name_400 b
where a.drug=b.drug
order by a.hadm_id,a.startdate asc
);

create table mimiciii.lw_drug_use_400_1
as 
(select distinct hadm_id,startdate from mimiciii.lw_drug_use_400 order by hadm_id,startdate asc);

create table mimiciii.lw_drug_use_1000_1_copy as 
(select * from mimiciii.lw_drug_use_1000_1);

CREATE INDEX lw_drug_use_400_index1 ON mimiciii.lw_drug_use_400_1 (hadm_id, startdate);  

CREATE INDEX lw_drug_use_400_index2 ON mimiciii.lw_drug_use_400_1 (hadm_id);  

CREATE INDEX lw_drug_use_400_index3 ON mimiciii.lw_drug_use_400_1 (startdate);  

CREATE INDEX lw_drug_use_400_index4 ON mimiciii.lw_drug_use_400_1 USING hash (hadm_id);

CREATE INDEX lw_drug_use_400_index5 ON mimiciii.lw_drug_use_400_1 USING hash (startdate);

/*timeseq*/
--hadm_time 400/1000

create table mimiciii.lw_hadm_time--400 
as (select distinct a.hadm_id, a.startdate from mimiciii.lw_drug_use_400_1 a order by a.hadm_id, a.startdate asc);

create table mimiciii.lw_hadm_time_1000--1000
as (select distinct a.hadm_id, a.startdate from mimiciii.lw_drug_use_1000_1 a order by a.hadm_id, a.startdate asc);

CREATE INDEX lw_lw_hadm_time_index1 ON mimiciii.lw_hadm_time (hadm_id, startdate); 

CREATE INDEX lw_lw_hadm_time_index2 ON mimiciii.lw_hadm_time (hadm_id); 

CREATE INDEX lw_lw_hadm_time_index3 ON mimiciii.lw_hadm_time (startdate); 

CREATE INDEX lw_lw_hadm_time_index4 ON mimiciii.lw_hadm_time USING hash (hadm_id);

CREATE INDEX lw_lw_hadm_time_index5 ON mimiciii.lw_hadm_time USING hash (startdate);

CREATE INDEX lw_lw_hadm_time_1000_index1 ON mimiciii.lw_hadm_time_1000 (hadm_id, startdate); 

CREATE INDEX lw_lw_hadm_time_1000_index2 ON mimiciii.lw_hadm_time_1000 (hadm_id); 

CREATE INDEX lw_lw_hadm_time_1000_index3 ON mimiciii.lw_hadm_time_1000 (startdate); 

CREATE INDEX lw_lw_hadm_time_1000_index4 ON mimiciii.lw_hadm_time_1000 USING hash (hadm_id);

CREATE INDEX lw_lw_hadm_time_1000_index5 ON mimiciii.lw_hadm_time_1000 USING hash (startdate);

--HEART RATE
/*
 * 				-- HEART RATE
			  211, --"Heart Rate"
			  220045, --"Heart Rate"
 */

create table mimiciii.lw_timeseries_hr
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (211,220045) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

ALTER TABLE mimiciii.lw_timeseries_hr ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_hr_1
as(
select a.hadm_id, avg(value) avgheart_rate from mimiciii.lw_timeseries_hr a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_hr set value = a.avgheart_rate
from mimiciii.lw_timeseries_hr_1 a 
where mimiciii.lw_timeseries_hr.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_hr.value is null;

create table mimiciii.lw_timeseries_heart_rate
as (
select a.hadm_id, a.startdate, avg(value) heart_rate
from mimiciii.lw_timeseries_hr a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--RESPIRATORY RATE

create table mimiciii.lw_timeseries_rr
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (618,615,220210,224690) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_rr set value = '60' where value like '%>60%';

ALTER TABLE mimiciii.lw_timeseries_rr ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_rr_1
as(
select a.hadm_id, avg(value) avgrespiratory_rate from mimiciii.lw_timeseries_rr a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_rr set value = a.avgrespiratory_rate
from mimiciii.lw_timeseries_rr_1 a 
where mimiciii.lw_timeseries_rr.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_rr.value is null;

create table mimiciii.lw_timeseries_respiratory_rate
as (
select a.hadm_id, a.startdate, avg(value) respiratory_rate
from mimiciii.lw_timeseries_rr a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

-- --diastolic_blood_pressure
--  * 51, --	Arterial BP [Systolic]
-- 			  442, --	Manual BP [Systolic]
-- 			  455, --	NBP [Systolic]
-- 			  6701, --	Arterial BP #2 [Systolic]
-- 			  220179, --	Non Invasive Blood Pressure systolic
-- 			  220050, --	Arterial Blood Pressure systolic

-- 			  8368, --	Arterial BP [Diastolic]
-- 			  8440, --	Manual BP [Diastolic]
-- 			  8441, --	NBP [Diastolic]
-- 			  8555, --	Arterial BP #2 [Diastolic]
-- 			  220180, --	Non Invasive Blood Pressure diastolic
-- 			  220051, --	Arterial Blood Pressure diastolic

create table mimiciii.lw_timeseries_dbp
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (8368,8440,8441,8555,220180,220051) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

--drop table mimiciii.lw_timeseries_dbp;

ALTER TABLE mimiciii.lw_timeseries_dbp ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_dbp_1
as(
select a.hadm_id, avg(value) avgdbp from mimiciii.lw_timeseries_dbp a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_dbp set value = a.avgdbp
from 
mimiciii.lw_timeseries_dbp_1 a 
where 
mimiciii.lw_timeseries_dbp.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_dbp.value is null;

create table mimiciii.lw_timeseries_diastolic_blood_pressure
as (
select a.hadm_id, a.startdate, avg(value) diastolic_blood_pressure
from mimiciii.lw_timeseries_dbp a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--systolic blood pressure
/*
 * 
 * 
 * 51, --	Arterial BP [Systolic]
			  442, --	Manual BP [Systolic]
			  455, --	NBP [Systolic]
			  6701, --	Arterial BP #2 [Systolic]
			  220179, --	Non Invasive Blood Pressure systolic
			  220050, --	Arterial Blood Pressure systolic

			  8368, --	Arterial BP [Diastolic]
			  8440, --	Manual BP [Diastolic]
			  8441, --	NBP [Diastolic]
			  8555, --	Arterial BP #2 [Diastolic]
			  220180, --	Non Invasive Blood Pressure diastolic
			  220051, --	Arterial Blood Pressure diastolic
 */	


create table mimiciii.lw_timeseries_sbp
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51,442,455,6701,220179,220050) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

ALTER TABLE mimiciii.lw_timeseries_sbp ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_sbp_1
as(
select a.hadm_id, avg(value) avgsbp from mimiciii.lw_timeseries_sbp a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_sbp set value = a.avgsbp
from mimiciii.lw_timeseries_sbp_1 a 
where mimiciii.lw_timeseries_sbp.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_sbp.value is null;

create table mimiciii.lw_timeseries_systolic_blood_pressure
as (
select a.hadm_id, a.startdate, avg(value) systolic_blood_pressure
from mimiciii.lw_timeseries_sbp a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--TEMPERATURE
/*
 * 			  223762, -- "Temperature Celsius"
			  676,	-- "Temperature C"
			  223761, -- "Temperature Fahrenheit"
			  678 --	"Temperature F"
 */

create table mimiciii.lw_timeseries_bt
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (223762,676,223761,678) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

ALTER TABLE mimiciii.lw_timeseries_bt ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

update mimiciii.lw_timeseries_bt set value = (value *1.8)+32 where itemid in (223762,676) and value notnull;

create table mimiciii.lw_timeseries_bt_1
as(
select a.hadm_id, avg(value) avgsbp from mimiciii.lw_timeseries_bt a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_bt set value = a.avgsbp
from mimiciii.lw_timeseries_bt_1 a 
where mimiciii.lw_timeseries_bt.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_bt.value is null;

create table mimiciii.lw_timeseries_body_temperature
as (
select a.hadm_id, a.startdate, avg(value) body_temperature
from mimiciii.lw_timeseries_bt a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--GLUCOSE
/*
 * 			  -- GLUCOSE, both lab and fingerstick
			  807,--	Fingerstick Glucose
			  811,--	Glucose (70-105)
			  1529,--	Glucose
			  3745,--	BloodGlucose
			  3744,--	Blood Glucose
			  225664,--	Glucose finger stick
			  220621,--	Glucose (serum)
			  226537,--	Glucose (whole blood)
 */



create table mimiciii.lw_timeseries_bg
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (807,811,1529,3745,3744,225664,220621,226537) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_bg set value = '109' where value = '\109';

update mimiciii.lw_timeseries_bg set value = replace(lower(value), 'cs', '');

update mimiciii.lw_timeseries_bg set value = replace(lower(value), 'fs', '');

update mimiciii.lw_timeseries_bg set value = replace(lower(value), '\', '');

update mimiciii.lw_timeseries_bg set value = null where value like '';

update mimiciii.lw_timeseries_bg set value = null where value like '%,%';

update mimiciii.lw_timeseries_bg set value = null where value like '%``%';

update mimiciii.lw_timeseries_bg set value = '174' where value = '''174';

update mimiciii.lw_timeseries_bg set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_bg ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

delete from mimiciii.lw_timeseries_bg where value is null; 

create table mimiciii.lw_timeseries_bg_1
as(
select a.hadm_id, avg(value) avgsbp from mimiciii.lw_timeseries_bg a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_bg set value = a.avgsbp
from mimiciii.lw_timeseries_bg_1 a 
where mimiciii.lw_timeseries_bg.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_bg.value is null;

create table mimiciii.lw_timeseries_blood_glucose
as (
select a.hadm_id, a.startdate, avg(value) blood_glucose
from mimiciii.lw_timeseries_bg a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--spo2

create table mimiciii.lw_timeseries_spo
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (646,220277) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

ALTER TABLE mimiciii.lw_timeseries_spo ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_spo_1
as(
select a.hadm_id, avg(value) avgsbp from mimiciii.lw_timeseries_spo a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_spo set value = a.avgsbp
from mimiciii.lw_timeseries_spo_1 a 
where mimiciii.lw_timeseries_spo.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_spo.value is null;

create table mimiciii.lw_timeseries_SpO2
as (
select a.hadm_id, a.startdate, avg(value) SpO2
from mimiciii.lw_timeseries_spo a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);


--Glascow coma scale
/*
198		GCS Total
227011	GCSEye_ApacheIV
227012	GCSMotor_ApacheIV
227013	GcsScore_ApacheIV
227014	GCSVerbal_ApacheIV
220739	GCS - Eye Opening
228112	GCSVerbalApacheIIValue (intubated)
223900	GCS - Verbal Response
223901	GCS - Motor Response
226755	GcsApacheIIScore
226756	GCSEyeApacheIIValue
226757	GCSMotorApacheIIValue
226758	GCSVerbalApacheIIValue
 */

create table mimiciii.lw_timeseries_gcs
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (198) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

ALTER TABLE mimiciii.lw_timeseries_gcs ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_gcs_1
as(
select a.hadm_id, avg(value) avgsbp from mimiciii.lw_timeseries_gcs a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_gcs set value = a.avgsbp
from mimiciii.lw_timeseries_gcs_1 a 
where mimiciii.lw_timeseries_gcs.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_gcs.value is null;

create table mimiciii.lw_timeseries_glascow_coma_scale
as (
select a.hadm_id, a.startdate, avg(value)  glascow_coma_scale
from mimiciii.lw_timeseries_gcs a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--fio2
/*
1040	BIpap FIO2
1206	HFO FIO2:
185		FIO2 Alarm-High
186		FIO2 Alarm-Low
189		FiO2 (Analyzed)
190		FiO2 Set
191		FiO2/O2 Delivered
727		Vision FiO2
3420	FIO2
3421	FIO2 Alarm [Low]
3422	FIO2 [Meas]
1863	HFO-FiO2
5955	Analyzed INOV FiO2
2518	HFO- FIO2
2981	FiO2
7018	ecmo fio2
7041	vapotherm fio2
7570	FIO2 SET
8517	FIO2 Alarm [High]
227009	FiO2_ApacheIV_old
227010	FiO2_ApacheIV
226754	FiO2ApacheIIValue
3420
190
3422
3421
8517
186
185
189
 */

create table mimiciii.lw_timeseries_fio
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.chartevents b, mimiciii.d_items c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (3420,190,3422,3421,8517,186,185,189) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_fio set value=to_char(to_number(value,'99.99') *100.00, '99.99') where value notnull and value like '.%';

ALTER TABLE mimiciii.lw_timeseries_fio ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

update mimiciii.lw_timeseries_fio set value='100' where value='1';

create table mimiciii.lw_timeseries_fio_1
as(
select a.hadm_id, avg(value) avgfio2 from mimiciii.lw_timeseries_fio a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_fio set value = a.avgfio2
from mimiciii.lw_timeseries_fio_1 a 
where mimiciii.lw_timeseries_fio.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_fio.value is null;

create table mimiciii.lw_timeseries_fio2
as (
select a.hadm_id, a.startdate, avg(value) fio2
from mimiciii.lw_timeseries_fio a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood gas --blood oxygen saturation
/*
18	50817	Oxygen Saturation	Blood	Blood Gas	20564-1
 */
create table mimiciii.lw_timeseries_bos
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50817, 50816) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_bos set value = null where lower(value) like '%dis%';

update mimiciii.lw_timeseries_bos set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_bos ALTER COLUMN value TYPE numeric(255,0) USING value::numeric;

create table mimiciii.lw_timeseries_bos_1
as(
select a.hadm_id, avg(value) avgsbp from mimiciii.lw_timeseries_bos a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_bos set value = a.avgsbp
from mimiciii.lw_timeseries_bos_1 a 
where mimiciii.lw_timeseries_bos.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_bos.value is null;

create table mimiciii.lw_timeseries_blood_oxygen_saturation
as (
select a.hadm_id, a.startdate, avg(value)  blood_oxygen_saturation
from mimiciii.lw_timeseries_bos a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood gas --pH
/*
21	50820	pH	Blood	Blood Gas	11558-4
 */
create table mimiciii.lw_timeseries_ph
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50820) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_ph set value = null where lower(value) like '%c%';

update mimiciii.lw_timeseries_ph set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_ph set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_ph ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_ph_1
as(
select a.hadm_id, avg(value) avgph from mimiciii.lw_timeseries_ph a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_ph set value = a.avgph
from mimiciii.lw_timeseries_ph_1 a 
where mimiciii.lw_timeseries_ph.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_ph.value is null;

create table mimiciii.lw_timeseries_potential_of_hydrogen
as (
select a.hadm_id, a.startdate, avg(value)  pH
from mimiciii.lw_timeseries_ph a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood gas --PO2
/*
50821	pO2	Blood	Blood Gas	11556-8
 */
create table mimiciii.lw_timeseries_po
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50821) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_po set value = null where lower(value) like '%q%';

update mimiciii.lw_timeseries_po set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_po set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_po ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_po_1
as(
select a.hadm_id, avg(value) avgpo from mimiciii.lw_timeseries_po a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_po set value = a.avgpo
from mimiciii.lw_timeseries_po_1 a 
where mimiciii.lw_timeseries_po.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_po.value is null;

create table mimiciii.lw_timeseries_po2
as (
select a.hadm_id, a.startdate, avg(value)  po
from mimiciii.lw_timeseries_po a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood gas --PCO2
/*
19	50818	pCO2	Blood	Blood Gas	11557-6
 */
create table mimiciii.lw_timeseries_pco
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50818) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_pco set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_pco set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_pco set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_pco ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_pco_1
as(
select a.hadm_id, avg(value) avgpco from mimiciii.lw_timeseries_pco a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_pco set value = a.avgpco
from mimiciii.lw_timeseries_pco_1 a 
where mimiciii.lw_timeseries_pco.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_pco.value is null;

create table mimiciii.lw_timeseries_pco2
as (
select a.hadm_id, a.startdate, avg(value)  pco
from mimiciii.lw_timeseries_pco a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood gas --TCO2
/*
36	50835	Albumin, Ascites	Ascites	Chemistry	1749-1
63	50862	Albumin	Blood	Chemistry	1751-7
211	51011	<Albumin>	Cerebrospinal Fluid (CSF)	Chemistry	1746-7
219	51019	Albumin, Joint Fluid	Joint Fluid	Chemistry	
225	51025	Albumin, Body Fluid	Other Body Fluid	Chemistry	1747-5
246	51046	Albumin, Pleural	Pleural	Chemistry	1748-3
269	51069	Albumin, Urine	Urine	Chemistry	1754-1
270	51070	Albumin/Creatinine, Urine	Urine	Chemistry	14958-3
753	51555	SURFACTANT ALBUMIN RATIO	OTHER BODY FLUID	CHEMISTRY	
 */
create table mimiciii.lw_timeseries_co
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50804) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_co set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_co set value = null where lower(value) like '%-%';

update mimiciii.lw_timeseries_co set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_co set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_co ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_co_1
as(
select a.hadm_id, avg(value) avgco from mimiciii.lw_timeseries_co a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_co set value = a.avgco
from mimiciii.lw_timeseries_co_1 a 
where mimiciii.lw_timeseries_co.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_co.value is null;

create table mimiciii.lw_timeseries_co2
as (
select a.hadm_id, a.startdate, avg(value)  co
from mimiciii.lw_timeseries_co a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood gas --anion gap
/*
69	50868	Anion Gap	Blood	Chemistry	1863-0
 */
create table mimiciii.lw_timeseries_agap
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50868) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_agap set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_agap set value = null where lower(value) like '%-%';

update mimiciii.lw_timeseries_agap set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_agap set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_agap ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_agap_1
as(
select a.hadm_id, avg(value) avgagap from mimiciii.lw_timeseries_agap a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_agap set value = a.avgagap
from mimiciii.lw_timeseries_agap_1 a 
where mimiciii.lw_timeseries_agap.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_agap.value is null;

create table mimiciii.lw_timeseries_anion_gap
as (
select a.hadm_id, a.startdate, avg(value)  agap
from mimiciii.lw_timeseries_agap a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --Albumin
/*
36	50835	Albumin, Ascites	Ascites	Chemistry	1749-1
63	50862	Albumin	Blood	Chemistry	1751-7
211	51011	<Albumin>	Cerebrospinal Fluid (CSF)	Chemistry	1746-7
219	51019	Albumin, Joint Fluid	Joint Fluid	Chemistry	
225	51025	Albumin, Body Fluid	Other Body Fluid	Chemistry	1747-5
246	51046	Albumin, Pleural	Pleural	Chemistry	1748-3
269	51069	Albumin, Urine	Urine	Chemistry	1754-1
270	51070	Albumin/Creatinine, Urine	Urine	Chemistry	14958-3
753	51555	SURFACTANT ALBUMIN RATIO	OTHER BODY FLUID	CHEMISTRY	
 */

create table mimiciii.lw_timeseries_albu
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50862) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_albu set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_albu set value = null where lower(value) like '%add%';

update mimiciii.lw_timeseries_albu set value = '1.00' where lower(value) like '%less than%';

update mimiciii.lw_timeseries_albu set value = '1.00' where lower(value) like '%<1%';

update mimiciii.lw_timeseries_albu set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_albu set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_albu ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_albu_1
as(
select a.hadm_id, avg(value) avgalbu from mimiciii.lw_timeseries_albu a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_albu set value = a.avgalbu
from mimiciii.lw_timeseries_albu_1 a 
where mimiciii.lw_timeseries_albu.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_albu.value is null;

create table mimiciii.lw_timeseries_albumin
as (
select a.hadm_id, a.startdate, avg(value)  albu
from mimiciii.lw_timeseries_albu a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --bicarbonate
/*
4	50803	Calculated Bicarbonate, Whole Blood	Blood	Blood Gas	1959-6
38	50837	Bicarbonate, Ascites	Ascites	Chemistry	54360-3
83	50882	Bicarbonate	Blood	Chemistry	1963-8
227	51027	Bicarbonate, Other Fluid	Other Body Fluid	Chemistry	11211-0
248	51048	Bicarbonate, Pleural	Pleural	Chemistry	54361-1
261	51061	Bicarbonate, Stool	Stool	Chemistry	14040-0
276	51076	Bicarbonate, Urine	Urine	Chemistry	1964-6
 */


create table mimiciii.lw_timeseries_bica
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50882) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_bica set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_bica set value = null where lower(value) like '%un%';

update mimiciii.lw_timeseries_bica set value = '5.00' where lower(value) like '%less than 5%';

update mimiciii.lw_timeseries_bica set value = '50.00' where lower(value) like '%greater than 50%';

update mimiciii.lw_timeseries_bica set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_bica set value = '50.00' where lower(value) like '%>50%';

update mimiciii.lw_timeseries_bica set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_bica set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_bica ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_bica_1
as(
select a.hadm_id, avg(value) avgbica from mimiciii.lw_timeseries_bica a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_bica set value = a.avgbica
from mimiciii.lw_timeseries_bica_1 a 
where mimiciii.lw_timeseries_bica.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_bica.value is null;

create table mimiciii.lw_timeseries_bicarbonate
as (
select a.hadm_id, a.startdate, avg(value)  bica
from mimiciii.lw_timeseries_bica a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --sodium
/*
668	51468	sodium Carbonate Crystals	Urine	Hematology	5773-7
669	51469	sodium Oxalate Crystals	Urine	Hematology	5774-5
670	51470	sodium Phosphate Crystals	Urine	Hematology	5775-2
9	50808	Free sodium	Blood	Blood Gas	1994-3
94	50893	sodium, Total	Blood	Chemistry	2000-8
229	51029	sodium, Body Fluid	Other Body Fluid	Chemistry	15155-5
266	51066	24 hr sodium	Urine	Chemistry	6874-2
277	51077	sodium, Urine	Urine	Chemistry	2004-0
 */

-- create table mimiciii.lw_timeseries_sodi
-- as(
-- select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
-- mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
-- where 
-- a.hadm_id=b.hadm_id and 
-- b.itemid=c.itemid and 
-- c.itemid in (50893) and 
-- a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
-- order by hadm_id,charttime asc
-- );

-- ALTER TABLE mimiciii.lw_timeseries_sodi ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

-- update mimiciii.lw_timeseries_sodi set value = null where lower(value) = '-';

-- update mimiciii.lw_timeseries_sodi set value = null where lower(value) like '%add%';

-- update mimiciii.lw_timeseries_sodi set value = '0.00' where lower(value) like '%less than 0%';

-- update mimiciii.lw_timeseries_sodi set value = '50.00' where lower(value) like '%greater than 50%';

-- update mimiciii.lw_timeseries_sodi set value = '45.00' where lower(value) like '%greater than 45%';

-- update mimiciii.lw_timeseries_sodi set value = '50.00' where lower(value) like '%>50%';

-- update mimiciii.lw_timeseries_sodi set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

-- create table mimiciii.lw_timeseries_sodi_1
-- as(
-- select a.hadm_id, avg(value) avgsodi from mimiciii.lw_timeseries_sodi a where value notnull group by hadm_id order by hadm_id asc
-- );

-- update mimiciii.lw_timeseries_sodi set value = a.avgsodi
-- from mimiciii.lw_timeseries_sodi_1 a 
-- where mimiciii.lw_timeseries_sodi.hadm_id=a.hadm_id and
-- mimiciii.lw_timeseries_sodi.value is null;

-- create table mimiciii.lw_timeseries_sodium
-- as (
-- select a.hadm_id, a.startdate, avg(value)  sodi
-- from mimiciii.lw_timeseries_sodi a 
-- group by a.hadm_id,a.startdate
-- order by a.hadm_id,a.startdate asc
-- );

--LAB blood --sodium
/*
25	50824	Sodium, Whole Blood	Blood	Blood Gas	2947-0
35	50834	Sodium, Body Fluid	Other Body Fluid	Blood Gas	2950-4
49	50848	Sodium, Ascites	Ascites	Chemistry	49790-9
184	50983	Sodium	Blood	Chemistry	2951-2
242	51042	Sodium, Body Fluid	Other Body Fluid	Chemistry	2950-4
258	51058	Sodium, Pleural	Pleural	Chemistry	
265	51065	Sodium, Stool	Stool	Chemistry	15207-4
300	51100	Sodium, Urine	Urine	Chemistry	2955-3
 */

create table mimiciii.lw_timeseries_sodi
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50983) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_sodi set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_sodi set value = null where lower(value) like '%disre%';

update mimiciii.lw_timeseries_sodi set value = '10.00' where lower(value) like '%less than 10%';

update mimiciii.lw_timeseries_sodi set value = '180.00' where lower(value) like '%greater than 180%';

update mimiciii.lw_timeseries_sodi set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_sodi set value = '180.00' where lower(value) like '%>180%';

update mimiciii.lw_timeseries_sodi set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_sodi set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_sodi ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_sodi_1
as(
select a.hadm_id, avg(value) avgsodi from mimiciii.lw_timeseries_sodi a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_sodi set value = a.avgsodi
from mimiciii.lw_timeseries_sodi_1 a 
where mimiciii.lw_timeseries_sodi.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_sodi.value is null;

create table mimiciii.lw_timeseries_sodium
as (
select a.hadm_id, a.startdate, avg(value)  sodi
from mimiciii.lw_timeseries_sodi a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --potassium
/*
23	50822	Potassium, Whole Blood	Blood	Blood Gas	6298-4
34	50833	Potassium	Other Body Fluid	Blood Gas	2821-7
48	50847	Potassium, Ascites	Ascites	Chemistry	49789-1
172	50971	Potassium	Blood	Chemistry	2823-3
241	51041	Potassium, Body Fluid	Other Body Fluid	Chemistry	2821-7
257	51057	Potassium, Pleural	Pleural	Chemistry	
264	51064	Potassium, Stool	Stool	Chemistry	15202-5
297	51097	Potassium, Urine	Urine	Chemistry	2828-2
 */


create table mimiciii.lw_timeseries_pota
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50971) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_pota set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_pota set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_pota set value = '10.00' where lower(value) like '%less than 10%';

update mimiciii.lw_timeseries_pota set value = '10.00' where lower(value) like '%greater than 10%';

update mimiciii.lw_timeseries_pota set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_pota set value = '1.0' where lower(value) like '%<1.0%';

update mimiciii.lw_timeseries_pota set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_pota set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_pota ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_pota_1
as(
select a.hadm_id, avg(value) avgpota from mimiciii.lw_timeseries_pota a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_pota set value = a.avgpota
from mimiciii.lw_timeseries_pota_1 a 
where mimiciii.lw_timeseries_pota.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_pota.value is null;

create table mimiciii.lw_timeseries_potassium
as (
select a.hadm_id, a.startdate, avg(value)  pota
from mimiciii.lw_timeseries_pota a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --chloride
/*
7	50806	Chloride, Whole Blood	Blood	Blood Gas	2069-3
40	50839	Chloride, Ascites	Ascites	Chemistry	33366-6
103	50902	Chloride	Blood	Chemistry	2075-0
213	51013	Chloride, CSF	Cerebrospinal Fluid (CSF)	Chemistry	
230	51030	Chloride, Body Fluid	Other Body Fluid	Chemistry	2072-7
250	51050	Chloride, Pleural	Pleural	Chemistry	53627-6
262	51062	Chloride, Stool	Stool	Chemistry	15158-9
278	51078	Chloride, Urine	Urine	Chemistry	2078-4
 */

create table mimiciii.lw_timeseries_chlor
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value   from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50902) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_chlor set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_chlor set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_chlor set value = '10.00' where lower(value) like '%less than 10%';

update mimiciii.lw_timeseries_chlor set value = '140.00' where lower(value) like '%greater than 140%';

update mimiciii.lw_timeseries_chlor set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_chlor set value = '140.0' where lower(value) like '%>140%';

update mimiciii.lw_timeseries_chlor set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_chlor set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_chlor ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_chlor_1
as(
select a.hadm_id, avg(value) avgchlor from mimiciii.lw_timeseries_chlor a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_chlor set value = a.avgchlor
from mimiciii.lw_timeseries_chlor_1 a 
where mimiciii.lw_timeseries_chlor.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_chlor.value is null;

create table mimiciii.lw_timeseries_chloride
as (
select a.hadm_id, a.startdate, avg(value)  chlor
from mimiciii.lw_timeseries_chlor a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --lactate
/*
14	50813	Lactate	Blood	Blood Gas	32693-4
44	50843	Lactate Dehydrogenase, Ascites	Ascites	Chemistry	2531-2
155	50954	Lactate Dehydrogenase (LD)	Blood	Chemistry	2532-0
215	51015	Lactate Dehydrogenase, CSF	Cerebrospinal Fluid (CSF)	Chemistry	2528-8
254	51054	Lactate Dehydrogenase, Pleural	Pleural	Chemistry	2530-4
 */

create table mimiciii.lw_timeseries_lacta
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50813) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_lacta set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_lacta set value = null where lower(value) like '%unab%';

update mimiciii.lw_timeseries_lacta set value = '10.00' where lower(value) like '%less than 10%';

update mimiciii.lw_timeseries_lacta set value = '30.00' where lower(value) like '%greater than 30%';

update mimiciii.lw_timeseries_lacta set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_lacta set value = '30.0' where lower(value) like '%>30%';

update mimiciii.lw_timeseries_lacta set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_lacta set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_lacta ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_lacta_1
as(
select a.hadm_id, avg(value) avglacta from mimiciii.lw_timeseries_lacta a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_lacta set value = a.avglacta
from mimiciii.lw_timeseries_lacta_1 a 
where mimiciii.lw_timeseries_lacta.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_lacta.value is null;

create table mimiciii.lw_timeseries_lactate
as (
select a.hadm_id, a.startdate, avg(value)  lacta
from mimiciii.lw_timeseries_lacta a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --creatinine
/*
42	50841	Creatinine, Ascites	Ascites	Chemistry	12191-3
113	50912	Creatinine	Blood	Chemistry	2160-0
221	51021	Creatinine, Joint Fluid	Joint Fluid	Chemistry	14401-4
232	51032	Creatinine, Body Fluid	Other Body Fluid	Chemistry	12190-5
252	51052	Creatinine, Pleural	Pleural	Chemistry	14399-0
267	51067	24 hr Creatinine	Urine	Chemistry	2162-6
270	51070	Albumin/Creatinine, Urine	Urine	Chemistry	14958-3
273	51073	Amylase/Creatinine Ratio, Urine	Urine	Chemistry	34235-2
280	51080	Creatinine Clearance	Urine	Chemistry	33558-8
281	51081	Creatinine, Serum	Urine	Chemistry	
282	51082	Creatinine, Urine	Urine	Chemistry	2161-8
299	51099	Protein/Creatinine Ratio	Urine	Chemistry	2890-2
306	51106	Urine Creatinine	Urine	Chemistry	
 */

create table mimiciii.lw_timeseries_creatin
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50912) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_creatin set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_creatin set value = null where lower(value) like '%v%';

update mimiciii.lw_timeseries_creatin set value = '0.60' where lower(value) like '%less than 0.6%';

update mimiciii.lw_timeseries_creatin set value = '30.00' where lower(value) like '%greater than 30%';

update mimiciii.lw_timeseries_creatin set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_creatin set value = '0.50' where lower(value) like '%<0.5%';

update mimiciii.lw_timeseries_creatin set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_creatin set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_creatin ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_creatin_1
as(
select a.hadm_id, avg(value) avgcreatin from mimiciii.lw_timeseries_creatin a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_creatin set value = a.avgcreatin
from mimiciii.lw_timeseries_creatin_1 a 
where mimiciii.lw_timeseries_creatin.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_creatin.value is null;

create table mimiciii.lw_timeseries_creatinine
as (
select a.hadm_id, a.startdate, avg(value)  creatin
from mimiciii.lw_timeseries_creatin a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --ureanitrogen
/*
52	50851	Urea Nitrogen, Ascites	Ascites	Chemistry	12265-5
206	51006	Urea Nitrogen	Blood	Chemistry	3094-0
245	51045	Urea Nitrogen, Body Fluid	Other Body Fluid	Chemistry	3093-2
304	51104	Urea Nitrogen, Urine	Urine	Chemistry	3095-7
 */

create table mimiciii.lw_timeseries_ureanit
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51006) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_ureanit set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_ureanit set value = null where lower(value) like '%una%';

update mimiciii.lw_timeseries_ureanit set value = '0.60' where lower(value) like '%less than 0.6%';

update mimiciii.lw_timeseries_ureanit set value = '30.00' where lower(value) like '%greater than 30%';

update mimiciii.lw_timeseries_ureanit set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_ureanit set value = '0.50' where lower(value) like '%<0.5%';

update mimiciii.lw_timeseries_ureanit set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_ureanit set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_ureanit ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_ureanit_1
as(
select a.hadm_id, avg(value) avgureanit from mimiciii.lw_timeseries_ureanit a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_ureanit set value = a.avgureanit
from mimiciii.lw_timeseries_ureanit_1 a 
where mimiciii.lw_timeseries_ureanit.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_ureanit.value is null;

create table mimiciii.lw_timeseries_ureanitrogen
as (
select a.hadm_id, a.startdate, avg(value)  ureanit
from mimiciii.lw_timeseries_ureanit a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --partial thromboplastin time
/*
475	51275	PTT	Blood	Hematology	3173-2
 */

create table mimiciii.lw_timeseries_partial
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51275) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_partial set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_partial set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_partial set value = '0.60' where lower(value) like '%less than 0.6%';

update mimiciii.lw_timeseries_partial set value = '30.00' where lower(value) like '%greater than 30%';

update mimiciii.lw_timeseries_partial set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_partial set value = '26.00' where lower(value) like '%26..%';

update mimiciii.lw_timeseries_partial set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_partial set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_partial ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_partial_1
as(
select a.hadm_id, avg(value) avgpartial from mimiciii.lw_timeseries_partial a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_partial set value = a.avgpartial
from mimiciii.lw_timeseries_partial_1 a 
where mimiciii.lw_timeseries_partial.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_partial.value is null;

create table mimiciii.lw_timeseries_partialtt
as (
select a.hadm_id, a.startdate, avg(value)  partialt
from mimiciii.lw_timeseries_partial a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --international normalized ratio
/*
437	51237	INR(PT)	Blood	Hematology	5895-7
 */

create table mimiciii.lw_timeseries_interra
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51237) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_interra set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_interra set value = null where lower(value) like '%a%';

update mimiciii.lw_timeseries_interra set value = '0.60' where lower(value) like '%less than 0.6%';

update mimiciii.lw_timeseries_interra set value = '15.70' where lower(value) like '%greater than 15.7%';

update mimiciii.lw_timeseries_interra set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_interra set value = '23.70' where lower(value) like '%>23.%';

update mimiciii.lw_timeseries_interra set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_interra set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_interra ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_interra_1
as(
select a.hadm_id, avg(value) avginterra from mimiciii.lw_timeseries_interra a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_interra set value = a.avginterra
from mimiciii.lw_timeseries_interra_1 a 
where mimiciii.lw_timeseries_interra.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_interra.value is null;

create table mimiciii.lw_timeseries_interratio
as (
select a.hadm_id, a.startdate, avg(value)  interrat
from mimiciii.lw_timeseries_interra a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --Bilirubin
/*
664	51464	Bilirubin	Urine	Hematology	5770-3
665	51465	Bilirubin Crystals	Urine	Hematology	5771-1
39	50838	Bilirubin, Total, Ascites	Ascites	Chemistry	14422-0
84	50883	Bilirubin, Direct	Blood	Chemistry	1968-7
85	50884	Bilirubin, Indirect	Blood	Chemistry	1971-1
86	50885	Bilirubin, Total	Blood	Chemistry	1975-2
212	51012	Bilirubin, Total, CSF	Cerebrospinal Fluid (CSF)	Chemistry	1973-7
228	51028	Bilirubin, Total, Body Fluid	Other Body Fluid	Chemistry	1974-5
249	51049	Bilirubin, Total, Pleural	Pleural	Chemistry	14421-2
 */

create table mimiciii.lw_timeseries_biliru
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50885) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_biliru set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_biliru set value = null where lower(value) like '%a%';

update mimiciii.lw_timeseries_biliru set value = '2.00' where lower(value) like '%less than 2.0%';

update mimiciii.lw_timeseries_biliru set value = '2.00' where lower(value) like '%greater than 2.0%';

update mimiciii.lw_timeseries_biliru set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_biliru set value = '23.70' where lower(value) like '%>23.%';

update mimiciii.lw_timeseries_biliru set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_biliru set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_biliru ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_biliru_1
as(
select a.hadm_id, avg(value) avgbiliru from mimiciii.lw_timeseries_biliru a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_biliru set value = a.avgbiliru
from mimiciii.lw_timeseries_biliru_1 a 
where mimiciii.lw_timeseries_biliru.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_biliru.value is null;

create table mimiciii.lw_timeseries_bilirubin
as (
select a.hadm_id, a.startdate, avg(value)  bilirut
from mimiciii.lw_timeseries_biliru a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --hemoglobin
/*
6	50805	Carboxyhemoglobin	Blood	Blood Gas	20563-3
12	50811	Hemoglobin	Blood	Blood Gas	718-7
15	50814	Methemoglobin	Blood	Blood Gas	2614-6
53	50852	% Hemoglobin A1c	Blood	Chemistry	4548-4
56	50855	Absolute Hemoglobin	Blood	Chemistry	718-7
412	51212	Fetal Hemoglobin	Blood	Hematology	4576-5
422	51222	Hemoglobin	Blood	Hematology	718-7
423	51223	Hemoglobin A2	Blood	Hematology	4552-6
424	51224	Hemoglobin C	Blood	Hematology	4561-7
425	51225	Hemoglobin F	Blood	Hematology	9749-3
485	51285	Reticulocyte, Cellular Hemoglobin	Blood	Hematology	
 */

create table mimiciii.lw_timeseries_hemog
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value   from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51222) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_hemog set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_hemog set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_hemog set value = '2.00' where lower(value) like '%less than 2.0%';

update mimiciii.lw_timeseries_hemog set value = '2.00' where lower(value) like '%greater than 2.0%';

update mimiciii.lw_timeseries_hemog set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_hemog set value = '23.70' where lower(value) like '%>23.%';

update mimiciii.lw_timeseries_hemog set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_hemog set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_hemog ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_hemog_1
as(
select a.hadm_id, avg(value) avghemog from mimiciii.lw_timeseries_hemog a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_hemog set value = a.avghemog
from mimiciii.lw_timeseries_hemog_1 a 
where mimiciii.lw_timeseries_hemog.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_hemog.value is null;

create table mimiciii.lw_timeseries_hemoglobin
as (
select a.hadm_id, a.startdate, avg(value)  hemogt
from mimiciii.lw_timeseries_hemog a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --hematocrit
/*
548	51348	Hematocrit, CSF	Cerebrospinal Fluid (CSF)	Hematology	30398-2
569	51369	Hematocrit, Joint Fluid	Joint Fluid	Hematology	
622	51422	Hematocrit, Other Fluid	Other Body Fluid	Hematology	11153-4
645	51445	Hematocrit, Pleural	Pleural	Hematology	
11	50810	Hematocrit, Calculated	Blood	Blood Gas	20570-8
315	51115	Hematocrit, Ascites	Ascites	Hematology	
421	51221	Hematocrit	Blood	Hematology	4544-3
680	51480	Hematocrit	Urine	Hematology	17809-5
 */

create table mimiciii.lw_timeseries_hemat
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51221) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_hemat set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_hemat set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_hemat set value = '2.00' where lower(value) like '%less than 2.0%';

update mimiciii.lw_timeseries_hemat set value = '2.00' where lower(value) like '%greater than 2.0%';

update mimiciii.lw_timeseries_hemat set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_hemat set value = '23.70' where lower(value) like '%>23.%';

update mimiciii.lw_timeseries_hemat set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_hemat set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_hemat ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_hemat_1
as(
select a.hadm_id, avg(value) avghemat from mimiciii.lw_timeseries_hemat a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_hemat set value = a.avghemat
from mimiciii.lw_timeseries_hemat_1 a 
where mimiciii.lw_timeseries_hemat.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_hemat.value is null;

create table mimiciii.lw_timeseries_hematocrit
as (
select a.hadm_id, a.startdate, avg(value)  hematt
from mimiciii.lw_timeseries_hemat a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --white blood cell count
/*
501	51301	White Blood Cells	Blood	wbceology	804-5
 */

create table mimiciii.lw_timeseries_wbce
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (51301) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

update mimiciii.lw_timeseries_wbce set value = null where lower(value) = '-';

update mimiciii.lw_timeseries_wbce set value = null where lower(value) like '%e%';

update mimiciii.lw_timeseries_wbce set value = '2.00' where lower(value) like '%less than 2.0%';

update mimiciii.lw_timeseries_wbce set value = '2.00' where lower(value) like '%greater than 2.0%';

update mimiciii.lw_timeseries_wbce set value = '45.00' where lower(value) like '%greater than 45%';

update mimiciii.lw_timeseries_wbce set value = '0.10' where lower(value) like '%<0.1%';

update mimiciii.lw_timeseries_wbce set value = replace(value,'GREATER THAN ','') where lower(value) like '%g%';

update mimiciii.lw_timeseries_wbce set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_wbce ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_wbce_1
as(
select a.hadm_id, avg(value) avgwbce from mimiciii.lw_timeseries_wbce a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_wbce set value = a.avgwbce
from mimiciii.lw_timeseries_wbce_1 a 
where mimiciii.lw_timeseries_wbce.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_wbce.value is null;

create table mimiciii.lw_timeseries_wbcell
as (
select a.hadm_id, a.startdate, avg(value)  wbcet
from mimiciii.lw_timeseries_wbce a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

--LAB blood --calcium
/*
50893
 */

create table mimiciii.lw_timeseries_calc
as(
select a.hadm_id, a.startdate, b.itemid, b.charttime, c."label", b.value    from 
mimiciii.lw_hadm_time a, mimiciii.labevents b, mimiciii.d_labitems c
where 
a.hadm_id=b.hadm_id and 
b.itemid=c.itemid and 
c.itemid in (50893) and 
a.startdate = to_timestamp(to_char(b.charttime,'yyyy-MM-dd'), 'yyyy-MM-dd hh24:mi:ss') 
order by hadm_id,charttime asc
);

-- select distinct value from mimiciii.lw_timeseries_calc;

update mimiciii.lw_timeseries_calc set value = null where value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

ALTER TABLE mimiciii.lw_timeseries_calc ALTER COLUMN value TYPE numeric(255,2) USING value::numeric;

create table mimiciii.lw_timeseries_calc2
as(
select a.hadm_id, avg(value) avgcalc from mimiciii.lw_timeseries_calc a where value notnull group by hadm_id order by hadm_id asc
);

update mimiciii.lw_timeseries_calc set value = a.avgcalc
from mimiciii.lw_timeseries_calc2 a 
where mimiciii.lw_timeseries_calc.hadm_id=a.hadm_id and
mimiciii.lw_timeseries_calc.value is null;

create table mimiciii.lw_timeseries_calcium
as (
select a.hadm_id, a.startdate, avg(value)  calc
from mimiciii.lw_timeseries_calc a 
group by a.hadm_id,a.startdate
order by a.hadm_id,a.startdate asc
);

-- /*
--  * 
--  * 51221	881764
-- 50971	845737
-- 50983	808401
-- 50912	797389
-- 50902	795480
-- 51006	791838
-- 50882	780648
-- 51265	778365
-- 50868	769810
-- 51301	753221
-- 51222	752444
-- 50931	748896
-- 51249	748147
-- 51279	747999
-- 51248	747994
-- 51250	747977
-- 51277	746817
-- 50960	664123
-- 50893	591932
-- 50970	590502
-- 50820	530752
-- 50802	490651
-- 50804	490641
-- 50821	490628
-- 50818	490594
-- 51275	474930
-- 51237	471176
-- 51274	469083
-- 50800	404785
-- 50808	249110
-- 50885	238263
-- 50861	219462
-- 50878	219452
-- 50863	207847
-- 50809	196736
-- 50822	192949
-- 50813	187116
-- 50817	173418
-- 51244	172131
-- 51256	172131
-- 51254	172130
-- 51200	172126
-- 51146	172124
-- 50812	163680
-- 50862	146694
-- 50910	132400
-- 50825	129444
-- 50816	127960
-- 50911	115802
-- 50954	107120
-- 50810	89715
-- 50811	89712
-- 51003	87238
-- 50819	86911
-- 50826	83805
-- 50827	77611
-- 51144	75587
-- 50824	71504
-- 50956	65373
-- 50867	63664
-- 50920	63253
-- 51233	61634
-- 51137	61381
-- 51246	60837
-- 50828	60544
-- 51143	59334
-- 51251	59206
-- 51255	59158
-- 51252	58059
-- 51267	55886
-- 51009	54728
-- 50806	48188
-- 51268	47280
-- 51214	45935
-- 50883	45205
-- 50884	44385
-- 51266	44151
-- 50993	28220
-- 50933	26855
-- 51000	24987
-- 51218	24375
-- 50979	23831
-- 50908	22911
-- 50967	22453
-- 50823	22057
-- 50801	22016
-- 50887	21880
-- 50986	21630
-- 50907	19444
-- 50964	18816
-- 51007	18355
-- 50904	18260
-- 50952	18205
-- 50903	18128
-- 50924	17946
-- 50998	17283
-- 50953	17229
-- 50852	16618
-- 51257	16568
-- 50905	16486
-- 51260	16180
-- 50909	13554
-- 50815	12307
-- 50935	11970
-- 50976	11935
-- 51010	11868
-- 50880	11823
-- 50879	11761
-- 50999	11723
-- 51002	11468
-- 51287	10339
-- 51283	10073
--  */

create table mimiciii.lw_timeseries as 
(
select z33.*, z34.wbcet from
(
select z31.*, z32.ureanit from
(
select z29.*, z30.systolic_blood_pressure from
(
select z27.*, z28.spo2 from
(
select z25.*, z26.sodi from
(
select z23.*, z24.respiratory_rate from
(
select z21.*, z22.ph from
(
select z19.*, z20.pota from
(
select z17.*, z18.po from
(
select z15.*, z16.pco from
(
select z13.*, z14.partialt from
(
select z11.*, z12.lacta from
(
select z9.*, z10.interrat from
(
select z7.*, z8.hemogt from
(
select z5.*, z6.hematt from
(
select z3.*, z4.heart_rate from
(
select z1.*, z2.glascow_coma_scale from
(
select y.*, z.fio2 from
(
select w.*, x.diastolic_blood_pressure from
(
select u.*, v.creatin from
(
select s.*, t.co from
(
select q.*, r.chlor from
(
select o.*, p.calc from
(
select m.*, n.body_temperature from
(
select k.*, l.blood_oxygen_saturation from
(
select i.*, j.bilirut from
(
select g.*, h.bica from
(
select e.*, f.blood_glucose from
(
select c.*,d.albu from
(
select a.*, b.agap from mimiciii.lw_hadm_time a
left join 
mimiciii.lw_timeseries_anion_gap b 
on 
a.hadm_id =b.hadm_id and a.startdate = b.startdate
) c
left join
mimiciii.lw_timeseries_albumin d
on 
c.hadm_id =d.hadm_id and c.startdate = d.startdate
) e
left join
mimiciii.lw_timeseries_blood_glucose f
on
e.hadm_id =f.hadm_id and e.startdate = f.startdate
) g
left join
mimiciii.lw_timeseries_bicarbonate h
on 
g.hadm_id =h.hadm_id and g.startdate = h.startdate
) i
left join
mimiciii.lw_timeseries_bilirubin j
on
i.hadm_id =j.hadm_id and i.startdate = j.startdate
) k
left join
mimiciii.lw_timeseries_blood_oxygen_saturation l
on
k.hadm_id =l.hadm_id and k.startdate = l.startdate
) m
left join
mimiciii.lw_timeseries_body_temperature n
on
m.hadm_id =n.hadm_id and m.startdate = n.startdate
) o
left join
mimiciii.lw_timeseries_calcium p
on
o.hadm_id =p.hadm_id and o.startdate = p.startdate
) q
left join
mimiciii.lw_timeseries_chloride r
on
q.hadm_id =r.hadm_id and q.startdate = r.startdate
) s
left join
mimiciii.lw_timeseries_co2 t
on
s.hadm_id =t.hadm_id and s.startdate = t.startdate
) u
left join
mimiciii.lw_timeseries_creatinine v
on
u.hadm_id =v.hadm_id and u.startdate = v.startdate
) w
left join
mimiciii.lw_timeseries_diastolic_blood_pressure x
on
w.hadm_id =x.hadm_id and w.startdate = x.startdate
) y
left join
mimiciii.lw_timeseries_fio2 z
on
y.hadm_id =z.hadm_id and y.startdate = z.startdate
) z1
left join
mimiciii.lw_timeseries_glascow_coma_scale z2
on
z1.hadm_id =z2.hadm_id and z1.startdate = z2.startdate
) z3
left join
mimiciii.lw_timeseries_heart_rate z4
on
z3.hadm_id =z4.hadm_id and z3.startdate = z4.startdate
) z5
left join
mimiciii.lw_timeseries_hematocrit z6
on
z5.hadm_id =z6.hadm_id and z5.startdate = z6.startdate
) z7
left join
mimiciii.lw_timeseries_hemoglobin z8
on
z7.hadm_id =z8.hadm_id and z7.startdate = z8.startdate
) z9
left join
mimiciii.lw_timeseries_interratio z10
on
z9.hadm_id =z10.hadm_id and z9.startdate = z10.startdate
) z11
left join
mimiciii.lw_timeseries_lactate z12
on
z11.hadm_id =z12.hadm_id and z11.startdate = z12.startdate
) z13
left join
mimiciii.lw_timeseries_partialtt z14
on
z13.hadm_id =z14.hadm_id and z13.startdate = z14.startdate
) z15
left join
mimiciii.lw_timeseries_pco2 z16
on
z15.hadm_id =z16.hadm_id and z15.startdate = z16.startdate
) z17
left join
mimiciii.lw_timeseries_po2 z18
on
z17.hadm_id =z18.hadm_id and z17.startdate = z18.startdate
) z19
left join
mimiciii.lw_timeseries_potassium z20
on
z19.hadm_id =z20.hadm_id and z19.startdate = z20.startdate
) z21
left join
mimiciii.lw_timeseries_potential_of_hydrogen z22
on
z21.hadm_id =z22.hadm_id and z21.startdate = z22.startdate
) z23
left join
mimiciii.lw_timeseries_respiratory_rate z24
on
z23.hadm_id =z24.hadm_id and z23.startdate = z24.startdate
) z25
left join
mimiciii.lw_timeseries_sodium z26
on
z25.hadm_id =z26.hadm_id and z25.startdate = z26.startdate
) z27
left join
mimiciii.lw_timeseries_spo2 z28
on
z27.hadm_id =z28.hadm_id and z27.startdate = z28.startdate
) z29
left join
mimiciii.lw_timeseries_systolic_blood_pressure z30
on
z29.hadm_id =z30.hadm_id and z29.startdate = z30.startdate
) z31
left join
mimiciii.lw_timeseries_ureanitrogen z32
on
z31.hadm_id =z32.hadm_id and z31.startdate = z32.startdate
) z33
left join
mimiciii.lw_timeseries_wbcell z34
on
z33.hadm_id =z34.hadm_id and z33.startdate = z34.startdate
);

/*make data_set top 400 drug*/

CREATE INDEX lw_time ON mimiciii.lw_timeseries (hadm_id, startdate);    

CREATE INDEX lw_time2 ON mimiciii.lw_timeseries (hadm_id);

CREATE INDEX lw_time3 ON mimiciii.lw_timeseries (startdate);   

CREATE INDEX lw_time4 ON mimiciii.lw_patient (hadm_id);   

/*one hot*/
create table mimiciii.lw_patient_greater18 as
(
select * from mimiciii.lw_patient_copy where age >=18 and age <=89 order by hadm_id asc
); 

ALTER TABLE mimiciii.lw_patient_greater18 ADD hospital_expire_flag numeric(255,2) default 0.00;

-- notsure 
update mimiciii.lw_patient_greater18 set 
hospital_expire_flag=a.hospital_expire_flag
from 
mimiciii.admissions a
where 
mimiciii.lw_patient_greater18.hadm_id=a.hadm_id;

create table mimiciii.lw_x1
as (
select 
b.*,
a.gender,
a.age,
a.weight,
a.height,
a.religion,
a.language,
a.marital_status,
a.ethnicity,
a.hospital_expire_flag
from 
mimiciii.lw_patient_greater18 a,
mimiciii.lw_timeseries b
where 
a.hadm_id = b.hadm_id
order by b.hadm_id,b.startdate asc
);


create table mimiciii.lw_y
as(
select 
d.*
from 
mimiciii.lw_drug_use_400_1 d,
mimiciii.lw_x1 c
where 
d.hadm_id = c.hadm_id and 
d.startdate = c.startdate 
order by d.hadm_id,d.startdate asc
);

create index lwy on mimiciii.lw_y(hadm_id, startdate);

create table mimiciii.lw_x
as (
select a.* from mimiciii.lw_x1 a, mimiciii.lw_y b
where a.hadm_id =b.hadm_id and a.startdate = b.startdate
);

create index lwx on mimiciii.lw_x(hadm_id, startdate);

create table mimiciii.lw_hadm_days
as(
select a.hadm_id, count(*) num  from 
mimiciii.lw_x a
group by a.hadm_id
order by num desc  
);

-- delete visit = 1 and > 100
DELETE FROM mimiciii.lw_hadm_days
WHERE num = 1 or num > 100;

update mimiciii.lw_x set religion = replace(lower(religion),' ', '');

update mimiciii.lw_x set ethnicity = replace(lower(ethnicity),' ', '');

update mimiciii.lw_x set marital_status = replace(lower(marital_status),' ', '');

update mimiciii.lw_x set gender = replace(lower(gender),' ', '');

update mimiciii.lw_x set language = replace(lower(language),' ', '');

create table mimiciii.lw_dataset as(
select 
b.*,
--a.hadm_id,
a.agap,
a.albu,
a.blood_glucose,
a.bica,
a.bilirut,
a.blood_oxygen_saturation,
a.body_temperature,
a.calc,
a.chlor,
a.co,
a.creatin,
a.diastolic_blood_pressure,
a.fio2,
a.glascow_coma_scale,
a.heart_rate,
a.hematt,
a.hemogt,
a.interrat,
a.lacta,
a.partialt,
a.pco,
a.po,
a.pota,
a.ph,
a.respiratory_rate,
a.sodi,
a.spo2,
a.systolic_blood_pressure,
a.ureanit,
a.wbcet,
a.gender,
a.age,
a.weight,
a.height,
a.religion,
a.language,
a.marital_status,
a.ethnicity,
a.hospital_expire_flag
from mimiciii.lw_x a, mimiciii.lw_y b 
where a.hadm_id=b.hadm_id and a.startdate =b.startdate
);
