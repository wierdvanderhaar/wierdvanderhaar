DECLARE
   CURSOR c_job_list
   IS
      SELECT jobs.owner, jobs.job_name
        FROM 	dba_scheduler_jobs jobs,
	  (select log.OWNER as logowner, log.JOB_NAME as logname, log.STATUS as maxstatus 
	  from DBA_SCHEDULER_JOB_LOG log 
	  where TRUNC(LOG_DATE) like (select trunc(max(LOG_DATE)) from DBA_SCHEDULER_JOB_LOG) group by OWNER, JOB_NAME, STATUS) logs
	  WHERE jobs.failure_count > 0
	  AND   logs.maxstatus = 'SUCCEEDED'
	  AND	LOGS.logowner=jobs.owner
	  AND 	LOGS.logname=jobs.job_name;
   l_owner      dba_scheduler_jobs.owner%TYPE;
   l_job_name    dba_scheduler_jobs.job_name%TYPE;
BEGIN
   OPEN c_job_list; 
   LOOP
      FETCH c_job_list
       INTO l_owner, l_job_name; 
      EXIT WHEN c_job_list%NOTFOUND;
      DBMS_SCHEDULER.DISABLE (NAME       => l_owner || '.' || l_job_name,
                              FORCE      => TRUE
                             );
      DBMS_SCHEDULER.ENABLE (NAME => l_owner || '.' || l_job_name);
   END LOOP;
END;
/
