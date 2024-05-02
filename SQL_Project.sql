Create database Bug_Master;
Use Bug_master;
Create table Incident_Master (Incident_ID varchar(50)
 ,Bug_id varchar(50),Resolved_Timing timestamp, Invoked_Time timestamp,
System_ID varchar(50)
, Live_Status varchar(30),Engineer_ID varchar(30),ETA int,Customer_ID Varchar(40),Customer_Status  varchar(40) ); 
Create table System_Status (Bug_id varchar(50) ,
System_ID varchar(50)
,Live_Status varchar(30),Invoked_Time timestamp); 
create table Quality_Team (Incident_ID varchar(30),
Resolved_time timestamp ,Engineer varchar(30))
;create table front_office (Incident_ID varchar(30),
Customer varchar(40),Customer_ID varchar(40),Customer_status varchar(40));
Create table engineeringDept(Engineer_Name varchar(30) , 
ID varchar(30), System_Speciality varchar(30));
Create table systems (SystemID varchar(30), Bug_ID varchar(30)) ; 

DELIMITER //
CREATE TRIGGER Bug_Insert_Master_Table1
AFTER INSERT ON System_Status1
FOR EACH ROW
BEGIN
    INSERT INTO Incident_Master1 ( Bug_id, Invoked_Time, System_ID, Live_Status,date)
    VALUES ( NEW.Bug_id, NEW.Invoked_Time, NEW.System_ID, NEW.Live_Status, NEW.date);
END //

DELIMITER ;


DELIMITER //
CREATE TRIGGER before_insert_incident_master1
BEFORE INSERT ON Incident_Master1
FOR EACH ROW
BEGIN
    
    SET NEW.Incident_ID = CONCAT(DATE_FORMAT(NEW.Invoked_Time, '%Y_%m_%d'),'_', NEW.Bug_ID,'_', NEW.System_ID);
END //

DELIMITER ;

DELIMITER // 
CREATE TRIGGER Front_Office_Update
AFTER INSERT ON front_office
FOR EACH ROW
BEGIN
    UPDATE Incident_Master
    SET Customer_ID = NEW.Customer_ID, Customer_Status =new.Customer_Status
    WHERE Incident_ID = NEW.Incident_ID;
END//

Delimiter ;

DELIMITER // 
CREATE TRIGGER Quality_Team_Update
AFTER INSERT ON Quality_Team
FOR EACH ROW
BEGIN
    UPDATE Incident_Master
    SET Engineer_ID = NEW.Engineer_ID , Resolved_Timing = new.Resolved_Timing
    WHERE Incident_ID = NEW.Incident_ID;
END//

Delimiter ;


SELECT BugID, AVG(Downtime) AS AverageDowntime
FROM BugDowntime
GROUP BY BugID;


DELIMITER //

CREATE PROCEDURE GetAverageDowntimeForBug(IN P_BugID INT, OUT P_AverageDowntime DECIMAL(10,2))
BEGIN
    SELECT AVG(Downtime) INTO P_AverageDowntime
    FROM BugDowntime
    WHERE BugID = P_BugID;
END //

DELIMITER ;

WITH Bug_Downtime_Ranked AS (
    SELECT
        BugID,
        Downtime,
        ROW_NUMBER() OVER (ORDER BY Downtime DESC) AS RowNum
    FROM
        BugDowntime
)
SELECT
    BugID,
    Downtime
FROM
    BugDowntimeRanked
WHERE
    RowNum <= 5;



WITH System_Total_Downtime_Ranked AS (
    SELECT
        System_ID,
        SUM(Downtime) AS TotalDowntime,
        ROW_NUMBER() OVER (ORDER BY SUM(Downtime) DESC) AS RowNum
    FROM
        SystemBugs
    GROUP BY
        SystemID
)
SELECT
    SystemID,
    TotalDowntime
FROM
    SystemTotalDowntimeRanked
WHERE
    RowNum <= 5;

CREATE VIEW frontdesk AS
SELECT Incident_ID, Bug_ID, ETA, Live_Status
FROM Incident_Master
WHERE Live_Status = 'Active';


CREATE VIEW Quality  AS
SELECT Incident_ID, Bug_ID, ETA, Live_Status, Engineer_ID,Engineer
FROM Incident_Master
WHERE Live_Status = 'Active';


CREATE VIEW Engineer  AS
SELECT Incident_ID, Bug_ID, ETA, Live_Status 
FROM Incident_Master
WHERE Live_Status = 'Active';



CREATE VIEW Master_View  AS  
select * from Incident_Master;


CREATE TABLE Daily_Backup AS SELECT * FROM Incident_Master WHERE 1=0;

DELIMITER //

CREATE PROCEDURE BackupMyTable()
BEGIN
    INSERT INTO Daily_Backup SELECT * FROM Incident_Master;
END //

DELIMITER ;

CREATE EVENT daily_backup
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '00:00:00')
DO
CALL BackupMyTable();



SET GLOBAL event_scheduler = ON;
