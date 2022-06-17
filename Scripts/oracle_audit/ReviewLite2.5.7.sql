REM     ORACLE - Licence Management Services
REM              Oracle Review Lite Script
REM
REM     Usage:
REM
REM        - Use SQL*PLUS to connect to the database with any user with following privileges
REM               - CREATE SESSION
REM               - SELECT ANY TABLE
REM               - SELECT ANY DICTIONARY (for Oracle 9i or higher)
REM          Hint: SYS or SYSTEM are good choices
REM          Example:
REM               sqlplus system/password@orcl1prod
REM
REM        - Run the script:
REM               @ReviewLite2.5.7.sql 
REM          
REM
REM
REM     Change History
REM     Date:     Rev:    Author:           Description:
REM     MM/DD/YY
REM     03/04/05  1.0                      Database Options Script
REM     08/07/05  2.0     Andres Herrera   Added Users defined, HWM, devices and conc
REM     10/03/05  2.1     Fernando LLanos  Database CPU count, Standby configuration
REM     10/06/05  2.1     Andres Herrera   Revision and formating
REM     10/09/06  2.2     Ellice Siytiu    Added OEM repository check, changed spatial query
REM     11/13/06  2.2     Ellice Siytiu    Added new options queries (Data Mining, Database Vault,
REM                                        Audit Vault, CONTENT DATABASE, RECORDS DATABASE)
REM     05/01/07  2.2     esiytiu          changed USER_SDO_GEOM_METADATA to ALL_SDO_GEOM_METADATA
REM     05/01/07  2.2     esiytiu          RAC analysis changed from counting host to instances
REM     07/24/07  2.3.1   esiytiu          additional ',' added to Segments query to fix "exceed length" error
REM     10/25/07  2.3.1   beparu           Added the section for automatic processing option
REM     12/28/07  2.4.1   esiytiu          Segment query - added count, min and max name instead of details;
REM                                        Added new query for OEM 10g that checks SYSMAN.MGMT% tables and for packs;
REM                                        Removed nested Select from Content query;
REM                                        Added select from DBA_REGISTRY to identify spatial over locator.
REM     02/23/08  2.5     sserban          Added usage notes; Added cpu_count isdefault;
REM                                        Check and modify OUTPUT_PATH to end with / or \;
REM     04/22/08  2.5.1   sserban          Added mgmt_licenses and mgmt_targets queries for OEM 10g;
REM                                        Marked the 2 OEM sections: prior and after 10g
REM     11/11/08  2.5.2   sserban          Fixed bug: missing '"' after mgmt_license_definitions.pack_display_label
REM     02/06/09  2.5.3   beparu           Altered linesize for sessions file
REM                                        Added V$PARAMETER Query for RAC - CLUSTER_DATABASE
REM                                        Added PARALLEL SERVER query to RAC queries
REM     03/12/09  2.5.4   sserban          Added License Agreement
REM                                        Removed DBA_REGISTRY query for version 9i_r2 (9.2)
REM                                        Added V$PARAMETER query for diag+tuning packs in 11g databases:
REM                                              CONTROL_MANAGEMENT_PACK_ACCESS
REM                                        Added V$PARAMETER query in the automatic processing area
REM     07/24/09  2.5.5   beparu           Added Advanced Security Queries
REM                                            - sessions using network encryption and strong authentication
REM                                            - columns using TDE (transparent data encryption)
REM                                            - tablespaces using TDE (transparent data encryption)
REM                                        Altered linesize for options file
REM     01/15/10  2.5.6   beparu           Removed paramter for directory name; output is spooled in a directory formed by host_name and instance_name
REM                                        Included BANNER in double quotes, since there are banners that contain commas
REM     04/13/10  2.5.7   beparu           Included OWB repositories queries
REM     05/06/10  2.5.7   beparu           Added SQL Profile Query for Tuning Pack (#37237)
REM     05/06/10  2.5.7   beparu           Enhancement for Data Mining (#37170)
REM	05/06/10  2.5.7   beparu           DBA_Feature_Usage_Statistics output is included in double quotes (#39429)
REM
REM
REM     This script checks
REM      * Database version installed
REM      * Database CPU number
REM      * Stand by server name  (if is installed on OEE)
REM
REM     Also checks for the options installed and confirms if
REM     options are being used:
REM      * OLAP              * SPATIAL
REM      * PARTITIONING      * RAC (REAL APPLICATION CLUSTER)
REM      * LABEL SECURITY    * OEM (Oracle Enterprise Manager)
REM      * DATA MINING       * AUDIT VAULT
REM      * DATBASE VAULT     * CONTENT DATABASE
REM      * RECORDS DATABASE
REM
define SCRIPT_RELEASE=2.5.7


-- PREPARE AND DISPLAY LICENSE AGREEMENT
SET TERMOUT OFF
SET ECHO OFF

SPOOL lms_license_agreement.txt
PROMPT Oracle License Management Services License Terms
PROMPT
PROMPT Export Controls on the Programs
PROMPT
PROMPT Inputting "y" at the "Accept License Agreement" prompt is a confirmation
PROMPT of your agreement that you comply, now and during the trial term, with each of
PROMPT the following statements:
PROMPT
PROMPT -You are not a citizen, national, or resident of, and are not under control of,
PROMPT the government of Cuba, Iran, Sudan, Libya, North Korea, Syria, nor any country
PROMPT to which the United States has prohibited export.
PROMPT
PROMPT -You will not download or otherwise export or re-export the Programs, directly
PROMPT or indirectly, to the above mentioned countries nor to citizens, nationals or
PROMPT residents of those countries.
PROMPT
PROMPT -You are not listed on the United States Department of Treasury lists of
PROMPT Specially Designated Nationals, Specially Designated Terrorists, and
PROMPT Specially Designated Narcotic Traffickers, nor are you listed on the
PROMPT United States Department of Commerce Table of Denial Orders
PROMPT
PROMPT You will not download or otherwise export or re-export the Programs, directly
PROMPT or indirectly, to persons on the above mentioned lists.
PROMPT
PROMPT You will not use the Programs for, and will not allow the Programs to be used
PROMPT for, any purposes prohibited by United States law, including, without
PROMPT limitation, for the development, design, manufacture or production of nuclear,
PROMPT chemical or biological weapons of mass destruction.
PROMPT
PROMPT    EXPORT RESTRICTIONS
PROMPT You agree that U.S. export control laws and other applicable export and import
PROMPT laws govern your use of the programs, including technical data; additional
PROMPT information can be found on Oracle's Global Trade Compliance web
PROMPT site (http://www.oracle.com/products/export).
PROMPT
PROMPT    You agree that neither the programs nor any direct product thereof will be
PROMPT exported, directly, or indirectly, in violation of these laws, or will be used
PROMPT for any purpose prohibited by these laws including, without limitation,
PROMPT nuclear, chemical, or biological weapons proliferation.
PROMPT    The LMS License Agreement terms below supersede any other license terms.
PROMPT
PROMPT    Oracle License Management Services Development License Agreement
PROMPT
PROMPT "We," "us," and "our" refers to Oracle USA, Inc., for and on behalf of itself
PROMPT and its subsidiaries and affiliates under common control. "You" and "your"
PROMPT refers to the individual or entity that wishes to use the programs from Oracle.
PROMPT "Programs" refers to the Oracle software product you wish to access via CD/DVD
PROMPT and use and program documentation. "License" refers to your right to use the
PROMPT programs under the terms of this agreement. This agreement is governed by the
PROMPT substantive and procedural laws of California. You and Oracle agree to submit
PROMPT to the exclusive jurisdiction of, and venue in, the courts of San Francisco,
PROMPT San Mateo, or Santa Clara counties in California in any dispute arising out of
PROMPT or relating to this agreement.
PROMPT
PROMPT    We are willing to license the programs to you only upon the condition that
PROMPT you accept all of the terms contained in this agreement. Read the terms
PROMPT carefully and select the "Accept License Agreement" button to confirm your
PROMPT acceptance. If you are not willing to be bound by these terms, select the
PROMPT "Decline License Agreement" button and the registration process will not
PROMPT continue.
PROMPT
PROMPT    LICENSE RIGHTS
PROMPT We grant you a nonexclusive, nontransferable limited license to use the
PROMPT programs only for the purpose of measuring and monitoring your usage of Oracle
PROMPT Programs, and not for any other purpose. We may audit your use of the programs.
PROMPT Program documentation will be provided with the tool.
PROMPT
PROMPT    Ownership and Restrictions
PROMPT We retain all ownership and intellectual property rights in the programs.
PROMPT The programs may be installed on one or more servers; provided, however, you
PROMPT may make one copy of the programs for backup or archival purposes.
PROMPT    You may not: - use the programs for your own internal data processing or
PROMPT for any commercial or production purposes, or use the programs for any purpose
PROMPT except the purpose stated herein;
PROMPT
PROMPT - use the application for any commercial or production purposes;
PROMPT - remove or modify any program markings or any notice of our proprietary rights;
PROMPT
PROMPT - make the programs available in any manner to any third party, without the
PROMPT prior written approval of Oracle;
PROMPT
PROMPT - use the programs to provide third party training;
PROMPT
PROMPT - assign this agreement or give or transfer the programs or an interest in
PROMPT them to another individual or entity; - cause or permit reverse engineering
PROMPT (unless required by law for interoperability), disassembly or decompilation
PROMPT of the programs;
PROMPT
PROMPT - disclose results of any program benchmark tests without our prior consent;
PROMPT or, - use any Oracle name, trademark or logo.
PROMPT    Export
PROMPT You agree that U.S. export control laws and other applicable export and import
PROMPT laws govern your use of the programs, including technical data; additional
PROMPT information can be found on Oracle's Global Trade Compliance web site located
PROMPT at http://www.oracle.com/products/export/index.html?content.html. You agree
PROMPT that neither the programs nor any direct product thereof will be exported,
PROMPT directly, or indirectly, in violation of these laws, or will be used for any
PROMPT purpose prohibited by these laws including, without limitation, nuclear,
PROMPT chemical, or biological weapons proliferation.
PROMPT
PROMPT    Disclaimer of Warranty and Exclusive Remedies
PROMPT    THE PROGRAMS ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. WE FURTHER
PROMPT DISCLAIM ALL WARRANTIES, EXPRESS AND IMPLIED, INCLUDING WITHOUT LIMITATION,
PROMPT ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR
PROMPT NON INFRINGEMENT.
PROMPT    IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL,
PROMPT PUNITIVE OR CONSEQUENTIAL DAMAGES, OR DAMAGES FOR LOSS OF PROFITS, REVENUE,
PROMPT DATA OR DATA USE, INCURRED BY YOU OR ANY THIRD PARTY, WHETHER IN AN ACTION IN
PROMPT CONTRACT OR TORT, EVEN IF WE HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH
PROMPT DAMAGES. OUR ENTIRE LIABILITY FOR DAMAGES HEREUNDER SHALL IN NO EVENT EXCEED
PROMPT ONE THOUSAND DOLLARS (U.S. $1,000).
PROMPT    No Technical Support
PROMPT Our technical support organization will not provide technical support, phone
PROMPT support, or updates to you for the programs licensed under this agreement.
PROMPT    End of Agreement
PROMPT You may terminate this agreement by destroying all copies of the programs. We
PROMPT have the right to terminate your right to use the programs if you fail to
PROMPT comply with any of the terms of this agreement, in which case you shall
PROMPT destroy all copies of the programs.
PROMPT    Relationship Between the Parties
PROMPT The relationship between you and us is that of licensee/licensor. Neither party
PROMPT will represent that it has any authority to assume or create any obligation,
PROMPT express or implied, on behalf of the other party, nor to represent the other
PROMPT party as agent, employee, franchisee, or in any other capacity. Nothing in
PROMPT this agreement shall be construed to limit either party's right to
PROMPT independently develop or distribute software that is functionally similar to
PROMPT the other party's products, so long as proprietary information of the other
PROMPT party is not included in such software.
PROMPT    Open Source
PROMPT "Open Source" software - software available without charge for use,
PROMPT modification and distribution - is often licensed under terms that require the
PROMPT user to make the user's modifications to the Open Source software or any
PROMPT software that the user 'combines' with the Open Source software freely
PROMPT available in source code form. If you use Open Source software in conjunction
PROMPT with the programs, you must ensure that your use does not: (i) create, or
PROMPT purport to create, obligations of us with respect to the Oracle programs;
PROMPT or (ii) grant, or purport to grant, to any third party any rights to or
PROMPT immunities under our intellectual property or proprietary rights in the Oracle
PROMPT programs. For example, you may not develop a software program using an Oracle
PROMPT program and an Open Source program where such use results in a program file(s)
PROMPT that contains code from both the Oracle program and the Open Source program
PROMPT (including without limitation libraries) if the Open Source program is licensed
PROMPT under a license that requires any "modifications" be made freely available.
PROMPT You also may not combine the Oracle program with programs licensed under the
PROMPT GNU General Public License ("GPL") in any manner that could cause, or could be
PROMPT interpreted or asserted to cause, the Oracle program or any modifications
PROMPT thereto to become subject to the terms of the GPL.
PROMPT    Entire Agreement
PROMPT You agree that this agreement is the complete agreement for the programs and
PROMPT licenses, and this agreement supersedes all prior or contemporaneous agreements
PROMPT or representations. If any term of this agreement is found to be invalid or
PROMPT unenforceable, the remaining provisions will remain effective.
PROMPT    Last updated: 11/05/07
PROMPT    Should you have any questions concerning this License Agreement, or if you
PROMPT desire to contact Oracle for any reason, please write:
PROMPT
PROMPT Oracle USA, Inc.
PROMPT 500 Oracle Parkway
PROMPT Redwood City, CA 94065

SPOOL OFF

HOST more lms_license_agreement.txt
HOST rm   lms_license_agreement.txt
HOST del  lms_license_agreement.txt

-- PROMT FOR LICENSE AGREEMENT ACCEPTANCE
DEFINE LANSWER=N
SET TERMOUT ON
ACCEPT LANSWER FORMAT A1 PROMPT 'Accept License Agreement? (y\n): '

-- FORCE "divisor is equal to zero" AND SQLERROR EXIT IF NOT ACCEPTED
SET TERMOUT OFF
WHENEVER SQLERROR EXIT
select 1/decode('&LANSWER', 'Y', null, 'y', null, 0) as " " from dual;
WHENEVER SQLERROR CONTINUE
SET TERMOUT ON

alter session set NLS_DATE_FORMAT='YYYY-MM-DD_HH24:MI:SS';

SET TERMOUT OFF
SET TAB OFF
SET TRIMOUT OFF
SET TRIMSPOOL OFF
SET PAGESIZE 5000
SET LINESIZE 300


-- Get host_name and instance_name
col C1 new_val INSTANCE_NAME
col C2 new_val HOST_NAME
-- Oracle7
SELECT min(machine) C2 FROM v$session WHERE type = 'BACKGROUND';
SELECT name    C1 FROM v$database;
-- Oracle8 and higher
SELECT instance_name C1, host_name C2 FROM v$instance;

col C3 new_val OUTPUT_PATH
SELECT '&&HOST_NAME'||'_'||'&&INSTANCE_NAME' C3 FROM DUAL;

HOST mkdir &&OUTPUT_PATH

Establish separator character for output path
col PATH_SEPARATOR new_val PATH_SEPARATOR
select decode(instr('&&OUTPUT_PATH', '/'), 0,
       decode(instr('&&OUTPUT_PATH', '\'), 0, '/', '\'), '/') as PATH_SEPARATOR
from dual;
If case, append separator at the end of otput path
col OUTPUT_PATH new_val OUTPUT_PATH
select decode(instr('&&OUTPUT_PATH', '&&PATH_SEPARATOR', -1),
              length('&&OUTPUT_PATH'), '&&OUTPUT_PATH', '&&OUTPUT_PATH&&PATH_SEPARATOR&&OUTPUT_PATH._') OUTPUT_PATH
from dual;

SET TERMOUT ON

spool &&OUTPUT_PATH.summary.csv
PROMPT HOST_NAME: &&HOST_NAME., INSTANCE_NAME: &&INSTANCE_NAME.
SHOW USER
PROMPT OUTPUT PATH is &&OUTPUT_PATH

REM Setting Format output...

SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET TERMOUT ON
SET PAUSE OFF

col parameter     format a40
COL Options       format a40
COL value         format a10
COL CPU           format a10
COL HOST_NAME     format a40 wrap
COL Instance_name format a15

SELECT 'LMS ReviewLite &SCRIPT_RELEASE. output file created at: ' || SYSDATE FROM DUAL;

PROMPT
PROMPT DB CPU COUNT
PROMPT ==========================================================
SELECT 'DATABASE CPU COUNT: ' || value ||
       decode(ISDEFAULT, 'TRUE', ' (ISDEFAULT)', ' (IS NOT DEFAULT !!!: '|| ISDEFAULT ||')')
       from V$PARAMETER where UPPER(name) like '%CPU_COUNT%';
PROMPT
PROMPT CPU Count as set on the database, could have been modified manually.
PROMPT Please verify using CPU Query and also check for Hyper Threading and
PROMPT Multi-core technology in the server.

PROMPT
PROMPT
PROMPT STAND BY SERVER CONFIGURATION
PROMPT ==========================================================
SELECT 'Standby values for Client: ' ||value from V$PARAMETER where UPPER(name) like '%FAL_CLIENT%';
SELECT 'Standby values for Server: ' ||value from V$PARAMETER where UPPER(name) like '%FAL_SERVER%';
PROMPT IF NO INFORMATION SHOWED THEN DB DOES NOT HAVE A STANDBY DB
PROMPT
PROMPT

SET HEADING ON
SET FEEDBACK ON
COL "Distinct username" FORMAT A30
PROMPT USERS CREATED AND CREATION DATE
PROMPT ==========================================================

SELECT DISTINCT USERNAME as "Distinct username", Created as "Created" FROM DBA_USERS ORDER BY CREATED ASC;


SPOOL OFF


SPOOL &&OUTPUT_PATH.version.csv

SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300

PROMPT DATABASE VERSION
PROMPT -------------------------------------------

PROMPT AUDIT_ID,BANNER,HOST_NAME,INSTANCE_NAME,SYSDATE

SELECT
0                  ||','||
'"'||BANNER||'"'   ||','||
'&&HOST_NAME'      ||','||
'&&INSTANCE_NAME'  ||','||
SYSDATE            ||','
FROM V$VERSION;

SPOOL OFF


-- Prepare to select EXPIRY_DATE only from versions > 7
define EXPIRY_DATE_DYN=''''''
col C4 new_val EXPIRY_DATE_DYN
-- This will work only on Oracle8 and higher
SELECT min(EXPIRY_DATE) C, 'EXPIRY_DATE' C4 FROM DBA_USERS;
col C4 clear


SPOOL &&OUTPUT_PATH.users.csv

SET HEADING OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300

PROMPT
PROMPT USERS CREATED
PROMPT -------------------------------------------

COL username format a18
COL userid format a7
COL default_Tablespace format a13
COL temporary_Tablespace format a13
COL profile format a10

PROMPT AUDIT_ID,USERNAME,USER_ID,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE,CREATED,PROFILE,EXPIRY_DATE,HOST_NAME,INSTANCE_NAME,SYSDATE

SELECT DISTINCT
0                     ||','||
USERNAME              ||','||
USER_ID               ||','||
DEFAULT_TABLESPACE    ||','||
TEMPORARY_TABLESPACE  ||','||
CREATED               ||','||
PROFILE               ||','||
&EXPIRY_DATE_DYN.     ||','||
'&&HOST_NAME'         ||','||
'&&INSTANCE_NAME'     ||','||
SYSDATE               ||','
FROM DBA_USERS;

SPOOL OFF

SPOOL &&OUTPUT_PATH.parameter.csv
SET HEADING OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300

COL VALUE format a10
COL ISDEFAULT format a7
COL DESCRIPTION format a60

PROMPT
PROMPT DATABASE PARAMETER
PROMPT -------------------------------------------

PROMPT AUDIT_ID,NAME,VALUE,ISDEFAULT,DESCRIPTION,HOST_NAME,INSTANCE_NAME,SYSDATE

SELECT
0                  ||','||
NAME               ||','||
VALUE              ||','||
ISDEFAULT          ||','||
DESCRIPTION        ||','||
'&&HOST_NAME'      ||','||
'&&INSTANCE_NAME'  ||','||
SYSDATE            ||','
FROM V$PARAMETER
WHERE UPPER(NAME) = 'CPU_COUNT';

SPOOL OFF

SPOOL &&OUTPUT_PATH.segments.csv
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300

COL segment_type format a10
col segment_name format a30
COL OWNER format a10
COL Partition_name format a15

PROMPT
PROMPT PARTITIONED DBA SEGMENTS (not applicable for release 7)
PROMPT -------------------------------------------------------

PROMPT AUDIT_ID,OWNER,SEGMENT_TYPE,SEGMENT_NAME,PARTITION_COUNT,PARTITION_MIN,PARTITION_MAX,HOST_NAME,INSTANCE_NAME,SYSDATE

SELECT
0                    ||','||
OWNER                ||','||
SEGMENT_TYPE         ||','||
SEGMENT_NAME         ||','||
COUNT(*)             ||','||
MIN(PARTITION_NAME)  ||','||
MAX(PARTITION_NAME)  ||','||
'&&HOST_NAME'        ||','||
'&&INSTANCE_NAME'    ||','||
SYSDATE              ||','
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE '%PARTITION%'
   OR PARTITION_NAME IS NOT NULL
GROUP BY OWNER, SEGMENT_TYPE, SEGMENT_NAME
ORDER BY 1;

SPOOL OFF

SPOOL &&OUTPUT_PATH.license.csv
SET HEADING OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300

PROMPT
PROMPT
PROMPT LICENSE INFORMATION
PROMPT -------------------------------------------

PROMPT
PROMPT AUDIT_ID,SESSIONS_MAX,SESSIONS_WARNING,SESSIONS_CURRENT,SESSIONS_HIGHWATER,USERS_MAX,HOST_NAME,INSTANCE_NAME,SYSDATE

select
0                     ||','||
SESSIONS_MAX          ||','||
SESSIONS_WARNING      ||','||
SESSIONS_CURRENT      ||','||
SESSIONS_HIGHWATER    ||','||
USERS_MAX             ||','||
'&&HOST_NAME'         ||','||
'&&INSTANCE_NAME'     ||','||
SYSDATE               ||','
FROM V$LICENSE;

SPOOL OFF


SPOOL &&OUTPUT_PATH.session.csv
SET HEADING OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 500

PROMPT
PROMPT
PROMPT SESSIONS INFORMATION
PROMPT -------------------------------------------

PROMPT
PROMPT AUDIT_ID,SID,USER#,USERNAME,COMMAND,S.STATUS,SERVER,SCHEMANAME,OSUSER,PROCESS,MACHINE,TERMINAL,PROGRAM,TYPE,MODULE,ACTION,CLIENT_INFO,LAST_CALL_ET,LOGON_TIME,HOST_NAME,INSTANCE_NAME,SYSDATE

select
0                     || ',' ||
SID                   || ',' ||
SERIAL#               || ',"'||
USERNAME              ||'","'||
COMMAND               ||'","'||
STATUS                ||'","'||
SERVER                ||'","'||
SCHEMANAME            ||'","'||
OSUSER                ||'","'||
PROCESS               ||'","'||
MACHINE               ||'","'||
TERMINAL              ||'","'||
PROGRAM               ||'","'||
TYPE                  ||'","'||
MODULE                ||'","'||
ACTION                ||'","'||
CLIENT_INFO           ||'","'||
LAST_CALL_ET          ||'","'||
LOGON_TIME            ||'",' ||
'&&HOST_NAME'         || ',' ||
'&&INSTANCE_NAME'     || ',' ||
SYSDATE               || ','
FROM V$SESSION;

SPOOL OFF

SPOOL &&OUTPUT_PATH.v_option.csv
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300

PROMPT
PROMPT DATABASE OPTIONS
PROMPT -------------------------------------------

PROMPT AUDIT_ID,PARAMETER,VALUE,HOST_NAME,INSTANCE_NAME,SYSDATE

SELECT DISTINCT
0                 ||','||
PARAMETER         ||','||
VALUE             ||','||
'&&HOST_NAME'     ||','||
'&&INSTANCE_NAME' ||','||
SYSDATE           ||','
FROM V$OPTION;

SPOOL OFF

SPOOL &&OUTPUT_PATH.dba_feature.csv

SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 500

Column name format a45
Column detected_usages format 9999

PROMPT
PROMPT
PROMPT 10g DBA_FEATURE_USAGE_STATISTICS
PROMPT -------------------------------------------

PROMPT

PROMPT AUDIT_ID,DBID,NAME,VERSION,DETECTED_USAGES,TOTAL_SAMPLES,CURRENTLY_USED,FIRST_USAGE_DATE,LAST_USAGE_DATE,AUX_COUNT,FEATURE_INFO,LAST_SAMPLE_DATE,LAST_SAMPLE_PERIOD,SAMPLE_INTERVAL,DESCRIPTION,HOST_NAME,INSTANCE_NAME,SYSDATE

SELECT
0                     ||',"' ||
DBID                  ||'","'||
NAME                  ||'","'||
VERSION               ||'","'||
DETECTED_USAGES       ||'","'||
TOTAL_SAMPLES         ||'","'||
CURRENTLY_USED        ||'","'||
FIRST_USAGE_DATE      ||'","'||
LAST_USAGE_DATE       ||'","'||
AUX_COUNT             ||'","'||
''                    ||'","'|| -- skip FEATURE_INFO clob
LAST_SAMPLE_DATE      ||'","'||
LAST_SAMPLE_PERIOD    ||'","'||
SAMPLE_INTERVAL       ||'","'||
DESCRIPTION           ||'","'||
'&&HOST_NAME'         ||'","'||
'&&INSTANCE_NAME'     ||'","'||
SYSDATE               ||'",'
from DBA_FEATURE_USAGE_STATISTICS;

SPOOL OFF



SPOOL &&OUTPUT_PATH.options.csv
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 5000
SET LINESIZE 300


PROMPT
PROMPT PARTITIONING
PROMPT -------------------------------------------

SET HEADING OFF

SELECT 'ORACLE PARTITIONING INSTALLED: '||value from v$option where
parameter='Partitioning';

SET FEEDBACK ON
SET HEADING ON
COL OWNER        FORMAT A20 WRAP
COL SEGMENT_TYPE FORMAT A17 WRAP
COL SEGMENT_NAME FORMAT A30 WRAP

SELECT DISTINCT OWNER, SEGMENT_TYPE, SEGMENT_NAME
FROM DBA_SEGMENTS
WHERE SEGMENT_TYPE LIKE '%PARTITION%'
ORDER BY 1, 2, 3;

PROMPT IF NO ROWS ARE RETURNED, THEN PARTITIONING IS NOT BEING USED.
PROMPT
PROMPT IF ROWS ARE RETURNED, CHECK THAT BOTH OWNER AND SEGMENT ARE
PROMPT ORACLE CREATED. IF NOT, THEN PARTITIONING IS BEING USED.
PROMPT

SET HEADING OFF
SET FEEDBACK OFF
PROMPT
PROMPT OLAP
PROMPT -------------------------------------------

SELECT 'ORACLE OLAP INSTALLED: '|| value from v$option where parameter='OLAP';

PROMPT
PROMPT
PROMPT CHECKING TO SEE IF OLAP IS INSTALLED / USED...

select value from v$option where parameter = 'OLAP';

PROMPT
PROMPT If the value is TRUE then the OLAP option IS INSTALLED
PROMPT If the value is FALSE then the OLAP option IS NOT INSTALLED
PROMPT If NO rows are selected then the option is NOT being used.

PROMPT
PROMPT
PROMPT CHECKING TO SEE IF THE OLAP OPTION IS BEING USED...
PROMPT
PROMPT CHECKING FOR OLAP CATALOGS...
PROMPT

SET HEADING ON
SET FEEDBACK OFF

SELECT
   count(*) "OLAP CATALOGS"
FROM
   olapsys.dba$olap_cubes
WHERE
   OWNER <>'SH' ;

PROMPT
PROMPT IF THE COUNT IS > 0 THEN CHECK THE WORKSPACES BEING USED
PROMPT IF THE COUNT IS = 0 THEN THE OLAP OPTION IS NOT BEING USED
PROMPT IF THE TABLE DOES NOT EXIST (ORA-00942) ...THEN THE OLAP CATALOGS ARE NOT BEING USED
PROMPT

PROMPT CHECKING FOR ANALYTICAL WORK SPACES...
PROMPT

SELECT count(*) "Analytical Workspaces"
FROM   dba_aws;

PROMPT
PROMPT IF THE COUNT IS >1 THEN CHECK WORKSPACES AND ITS OWNER
PROMPT IF THE COUNT IS 0 OR 1 THEN ANALYTICAL WORKSPACES ARE NOT BEING USED
PROMPT IF THE TABLE DOES NOT EXIST (ORA-00942) ...THEN ANALYTICAL WORKSPACES ARE NOT BEING USED

PROMPT
PROMPT CHECKING FOR ANALYTICAL WORKSPACE OWNERS...
PROMPT

SET HEADING ON
SET FEEDBACK ON

SELECT OWNER, AW_NUMBER, AW_NAME, PAGESPACES, GENERATIONS FROM
DBA_AWS;

PROMPT
PROMPT NOTE: A positive result FROM either QUERY indicates the use of the OLAP option.
PROMPT    Check the Workspace owners to detemine if Workspaces are Oracle created.
PROMPT

PROMPT
PROMPT RAC (REAL APPLICATION CLUSTERS)
PROMPT -------------------------------------------

SET HEADING OFF
SET FEEDBACK OFF
SELECT 'ORACLE RAC INSTALLED: '||value from v$option where
parameter in ('Real Application Clusters','Parallel Server');

SET HEADING ON

PROMPT
PROMPT CHECKING TO SEE IF RAC IS INSTALLED AND BEING USED...
PROMPT RAC (Real Application Cluster)= Former OPS(Oracle Parallel Server)
PROMPT

SELECT name, value
FROM   gv$parameter
WHERE  name = 'cluster_database';

PROMPT
PROMPT Checking V$PARAMETER (for DB version 9.0.1 and above)
PROMPT If the value returned is TRUE, then RAC/OPS is being used.
PROMPT even if the following query only returns one row.

SELECT instance_name, host_name
FROM   gv$instance
ORDER BY instance_name;

PROMPT
PROMPT If only one row is returned, then RAC/OPS is NOT being used.
PROMPT If more than one row is returned, then RAC/OPS IS being used for this database.

PROMPT
PROMPT LABEL SECURITY
PROMPT -------------------------------------------

SET HEADING OFF
SET FEEDBACK OFF

SELECT 'ORACLE LABEL SECURITY INSTALLED: '||value from v$option where
parameter='Label Security';

PROMPT
PROMPT
PROMPT CHECKING TO SEE IF LABEL SECURITY IS INSTALLLED / USED...

select value
from   v$option
where  parameter = 'Oracle Label Security';

PROMPT
PROMPT If the value is TRUE then the LABEL SECURITY OPTION IS installed
PROMPT If the value is FALSE then the LABEL SECURITY OPTION IS NOT installed
PROMPT If NO rows are selected then the option is NOT being used
PROMPT
PROMPT

PROMPT CHECKING TO SEE IF THE LABEL SECURITY OPTION IS BEING USED....
PROMPT

select count(*) from lbacsys.lbac$polt where owner <> 'SA_DEMO';

PROMPT
PROMPT If the COUNT > 0 then the LABEL SECURITY OPTION IS being used
PROMPT If the COUNT IS = 0 then the LABEL SECURITY OPTION IS NOT being used
PROMPT If TABLE DOES NOT EXIST (ORA-00942) ...Then LABEL SECURITY OPTION IS NOT being used
PROMPT

PROMPT OEM
PROMPT -------------------------------------------

PROMPT
PROMPT CHECKING FOR OEM VERSIONS PRIOR TO 10g
PROMPT -------------------------------------------

SET HEADING ON
SET FEEDBACK OFF

PROMPT
PROMPT CHECKING TO SEE IF OEM PROGRAMS ARE RUNNING
PROMPT DURING THE MEASUREMENT PERIOD...
PROMPT

SET FEEDBACK on

SELECT DISTINCT
   program
FROM
   v$session
WHERE
   upper(program) LIKE '%XPNI.EXE%'
   OR upper(program) LIKE '%VMS.EXE%'
   OR upper(program) LIKE '%EPC.EXE%'
   OR upper(program) LIKE '%TDVAPP.EXE%'
   OR upper(program) LIKE 'VDOSSHELL%'
   OR upper(program) LIKE '%VMQ%'
   OR upper(program) LIKE '%VTUSHELL%'
   OR upper(program) LIKE '%JAVAVMQ%'
   OR upper(program) LIKE '%XPAUTUNE%'
   OR upper(program) LIKE '%XPCOIN%'
   OR upper(program) LIKE '%XPKSH%'
   OR upper(program) LIKE '%XPUI%';

PROMPT
PROMPT CHECKING FOR OEM REPOSITORIES...
PROMPT

   SET SERVEROUTPUT ON

      DECLARE
      cursor1 integer;
   v_count number(1);
      v_schema dba_tables.owner%TYPE;
      v_version varchar2(10);
      v_component varchar2(20);
      v_i_name varchar2(10);
      v_h_name varchar2(30);
      stmt varchar2(200);
      rows_processed integer;

      CURSOR schema_array IS
      SELECT owner
      FROM dba_tables WHERE table_name = 'SMP_REP_VERSION';

      CURSOR schema_array_v2 IS
      SELECT owner
      FROM dba_tables WHERE table_name = 'SMP_VDS_REPOS_VERSION';

      BEGIN
         DBMS_OUTPUT.PUT_LINE ('.');
         DBMS_OUTPUT.PUT_LINE ('OEM REPOSITORY LOCATIONS');

         select instance_name,host_name into v_i_name, v_h_name from
            v$instance;
            DBMS_OUTPUT.PUT_LINE ('Instance: '||v_i_name||' on host: '||v_h_name);

            OPEN schema_array;
            OPEN schema_array_v2;

            cursor1:=dbms_sql.open_cursor;

            v_count := 0;

            LOOP -- this loop steps through each valid schema.
            FETCH schema_array INTO v_schema;
            EXIT WHEN schema_array%notfound;
            v_count := v_count + 1;
            dbms_sql.parse(cursor1,'select c_current_version, c_component from
            '||v_schema||'.smp_rep_version', dbms_sql.native);
            dbms_sql.define_column(cursor1, 1, v_version, 10);
            dbms_sql.define_column(cursor1, 2, v_component, 20);

            rows_processed:=dbms_sql.execute ( cursor1 );

            loop -- to step through cursor1 to find console version.
            if dbms_sql.fetch_rows(cursor1) >0 then
            dbms_sql.column_value (cursor1, 1, v_version);
            dbms_sql.column_value (cursor1, 2, v_component);
            if v_component = 'CONSOLE' then
            dbms_output.put_line ('Schema '||rpad(v_schema,15)||' has a repository
            version '||v_version);
            exit;

            end if;
            else
               exit;
            end if;
            end loop;

            END LOOP;

            LOOP -- this loop steps through each valid V2 schema.
            FETCH schema_array_v2 INTO v_schema;
            EXIT WHEN schema_array_v2%notfound;

            v_count := v_count + 1;
            dbms_output.put_line ( 'Schema '||rpad(v_schema,15)||' has a repository
            version 2.x' );
            end loop;

            dbms_sql.close_cursor (cursor1);
            close schema_array;
            close schema_array_v2;
            if v_count = 0 then
            dbms_output.put_line ( 'There are NO OEM repositories with version prior to 10g on this instance.');
            end if;
   end;
/

prompt
prompt If NO ROWS are returned then OEM is not being used.
prompt If ROWS are returned, then OEM is being utilized.
prompt

PROMPT
PROMPT CHECKING FOR OEM VERSIONS 10g OR HIGHER
PROMPT -------------------------------------------

prompt
prompt CHECKING FOR MANAGEMENT PACKS BEING USED (10g or higher)
prompt

col OEM_PACK       format A40 wrap
col PACK_ACCESS_GRANTED format A19
col PACK_ACCESS_AGREED  format A19
col TABLE_NAME_    format A40 wrap
col C_             format A24 wrap

define OEMOWNER=SYSMAN
col OEMOWNER new_val OEMOWNER format a30 wrap
col OEM_PACK format a75 wrap
select 'OEM REPOSITORY SCHEMA:' C_, owner as OEMOWNER from dba_tables where table_name = 'MGMT_ADMIN_LICENSES';
select distinct
       a.pack_display_label as OEM_PACK,
       decode(b.pack_name, null, 'NO', 'YES') as PACK_ACCESS_GRANTED,
       PACK_ACCESS_AGREED
  from &&OEMOWNER..MGMT_LICENSE_DEFINITIONS a,
       &&OEMOWNER..MGMT_ADMIN_LICENSES      b,
      (select decode(count(*), 0, 'NO', 'YES') as PACK_ACCESS_AGREED
        from &&OEMOWNER..MGMT_LICENSES where upper(I_AGREE)='YES') c
  where a.pack_label = b.pack_name   (+)
  order by 1, 2;

col I_AGREE format a10 wrap
prompt OEM PACK ACCESS AGREEMENTS (10g or higher)
select USERNAME, TIMESTAMP, I_AGREE
  from &&OEMOWNER..MGMT_LICENSES
  order by TIMESTAMP;


col TARGET_NAME    format a30 wrap
prompt OEM MANAGED DATABASES (10g or higher)
select TARGET_NAME, HOST_NAME, LOAD_TIMESTAMP
  from &&OEMOWNER..MGMT_TARGETS
  where TARGET_TYPE = 'oracle_database'
  order by TARGET_NAME;


COL VALUE_ format a18
prompt
prompt CHECKING FOR CONTROL_MANAGEMENT_PACK_ACCESS (11g or higher)
prompt

select name, value as value_, isdefault
  from V$PARAMETER where UPPER(name) like '%CONTROL_MANAGEMENT_PACK_ACCESS%'
  order by 1;

prompt
prompt CHECKING FOR USE OF SQL PROFILES
prompt If the number returned is > 0, SQL Profiles are IN USE - this means TUNING PACK must be licensed

select count(*) from dba_sql_profiles;


SET HEADING OFF
SET FEEDBACK OFF

PROMPT SPATIAL
PROMPT -------------------------------------------

SELECT 'ORACLE SPATIAL INSTALLED: '||value from v$option where
parameter='Spatial';

SET HEADING ON
SET FEEDBACK ON

PROMPT
PROMPT CHECKING TO SEE IF SPATIAL FUNCTIONS ARE BEING USED...
PROMPT

select count(*) "ALL_SDO_GEOM_METADATA"
from ALL_SDO_GEOM_METADATA;

PROMPT
PROMPT If value returned is 0, then SPATIAL is NOT being used.
PROMPT If value returned is > 0, then SPATIAL OR LOCATOR IS being used.
PROMPT
PROMPT For version 10g and higher, check DBA_FEATURE_USAGE_STATISTICS
PROMPT whether Spatial is currently used.
PROMPT
PROMPT For version 9i and below, confirm with the customer
PROMPT whether Spatial or Locator is being used.
PROMPT

SET HEADING OFF
SET FEEDBACK OFF

PROMPT
PROMPT DATA MINING
PROMPT -------------------------------------------

SELECT 'ORACLE DATA MINING INSTALLED: '||value from v$option where
parameter like '%Data Mining';

SET HEADING ON
SET FEEDBACK ON

PROMPT
PROMPT CHECKING TO SEE IF DATA MINING IS BEING USED:
PROMPT

PROMPT FOR 9i DATABASE:
PROMPT
select count(*) "Data_Mining_Model" from odm.odm_mining_model;

PROMPT
PROMPT FOR 10g v1 DATABASE:
PROMPT
select count(*) "Data_Mining_Objects" from dmsys.dm$object;
select count(*) "Data_Mining_Models" from dmsys.dm$model;
PROMPT
PROMPT FOR 10g v2 DATABASE:
PROMPT
select count(*) "Data_Mining_Objects" from dmsys.dm$p_model;
PROMPT
PROMPT FOR 11g DATABASE:
PROMPT
select count(*) from SYS.MODEL$;

prompt If no rows are returned, then Data Mining is NOT being used.
prompt If rows are returned then Data Mining IS being used.
prompt

PROMPT
PROMPT DATABASE VAULT
PROMPT -------------------------------------------

PROMPT
PROMPT CHECKING TO SEE IF DATABASE VAULT SCHEMAS ARE INSTALLED...

SET HEADING OFF
SET FEEDBACK OFF

select decode(upper(max(username)), 'DVSYS', 'Audit Vault Schema DVSYS exist', 'Audit Vault schema DVSYS does not exist')
  from dba_users where UPPER(username)='DVSYS';

select decode(upper(max(username)), 'DVF', 'Audit Vault Schema DVF exist', 'Audit Vault schema DVF does not exist')
  from dba_users where UPPER(username)='DVF';

SET FEEDBACK ON

PROMPT
PROMPT Checking if there are Database Vault Realms created...
PROMPT
SELECT decode(count(*), 0, 'No realms were created', count(*) ||' Realms were created')
FROM DVSYS.DBA_DV_REALM;

PROMPT If DVSYS and DVF schema exist
PROMPT and DBA_DV_REALM table exist with REALMS created
PROMPT then DATABASE VAULT is installed and being used.
PROMPT

PROMPT
PROMPT AUDIT VAULT
PROMPT -------------------------------------------
PROMPT
PROMPT NOTE: "Audit Vault Server" and "Audit Vault Collection Agent"
PROMPT .      are standalone products
PROMPT .      and not Enterprise Edition Options

SET HEADING OFF
SET FEEDBACK OFF

PROMPT
PROMPT CHECKING TO SEE IF AUDIT VAULT SCHEMAS ARE INSTALLED...

select decode(upper(max(username)), 'AVSYS', 'Audit Vault Schema AVSYS exist', 'Audit Vault schema AVSYS does not exist')
  from dba_users where UPPER(username)='AVSYS';

PROMPT
PROMPT If AVSYS schema exist,
PROMPT Then AUDIT VAULT is installed and being used.
PROMPT

PROMPT
PROMPT
PROMPT CONTENT DATABASE and RECORDS DATABASE
PROMPT -------------------------------------------

PROMPT
PROMPT CHECKING TO SEE IF SCHEMA FOR BOTH CONTENT and RECORDS DATABASE IS INSTALLED...

SET HEADING OFF
SET FEEDBACK OFF

select decode(upper(max(username)), 'CONTENT', 'CONTENT schema exist', 'CONTENT schema does not exist')
  from dba_users where UPPER(username)='CONTENT';

SET HEADING ON
SET FEEDBACK ON
PROMPT
PROMPT CHECKING TO SEE IF CONTENT DATABASE IS BEING USED...
PROMPT

SELECT (Count(*) - 9004) "ODM_Document Customer Objects"
FROM odm_document;

PROMPT If ODM_DOCUMENT table exist and number of objects are more than
PROMPT or equal to 1 then CONTENT DATABASE is installed and being used.
PROMPT
PROMPT
PROMPT CHECKING TO SEE IF RECORDS DATABASE IS BEING USED...
PROMPT

SELECT Count(*) "ODM_RECORD Customer Objects"
FROM odm_record;

PROMPT If ODM_RECORD table exist and number of objects are more than
PROMPT or equal to 1 then RECORDS DATABASE is installed and being used.








PROMPT
PROMPT
PROMPT ADVANCED SECURITY
PROMPT -------------------------------------------

PROMPT CHECKING IF ADVANCED SECURITY OPTION FUNCTIONALITIES ARE IN USE ...
PROMPT
PROMPT LOOKING FOR SESSIONS USING NETWORK ENCRYPTION AND STRONG AUTHENTICATION

SET HEADING ON
SET FEEDBACK ON

PROMPT
PROMPT AUTHENTICATION_TYPE,SID,OSUSER,NETWORK_SERVICE_BANNER,
SELECT AUTHENTICATION_TYPE||','||SID||','||OSUSER||',"'||NETWORK_SERVICE_BANNER||'",'
  FROM V$SESSION_CONNECT_INFO
  WHERE LOWER(NETWORK_SERVICE_BANNER) LIKE '%authentication service%'
     OR LOWER(NETWORK_SERVICE_BANNER) LIKE '%encryption service%'
     OR LOWER(NETWORK_SERVICE_BANNER) LIKE '%crypto_checksumming%'
  ORDER BY 1;

PROMPT
PROMPT Look for non-standard encryption, checksumming or authentication algorithms in the BANNER field
PROMPT encryption:|AES256|, |AES192|, |AES128|, |3DES168|, |3DES112|, |DES56C|, |DES40C|,|RC4_256|, |RC4_128|, |RC4_56|, |RC4_40|
PROMPT checksumming:MD5, SHA1
PROMPT authentication:RADIUS, Kerberos, SSL
PROMPT If any of these is present, ADVANCED SECURITY is IN USE

PROMPT
PROMPT LOOKING FOR COLUMNS USING TDE (TRANSPARENT DATA ENCRYPTION)
PROMPT

PROMPT OWNER,TABLE_NAME,COLUMN_NAME,
SELECT OWNER||','||TABLE_NAME||','||COLUMN_NAME FROM DBA_ENCRYPTED_COLUMNS ORDER BY 1;
PROMPT
PROMPT If rows are returned, ADVANCED SECURITY is IN USE

PROMPT LOOKING FOR TABLESPACES USING TDE (TRANSPARENT DATA ENCRYPTION) - 11G AND ABOVE
PROMPT
PROMPT TABLESPACE_NAME,ENCRYPTED,
SELECT TABLESPACE_NAME||','||ENCRYPTED FROM DBA_TABLESPACES WHERE encrypted ='YES';
PROMPT
PROMPT If rows are returned, ADVANCED SECURITY is IN USE

PROMPT
PROMPT
PROMPT Oracle Warehouse Builder
PROMPT -------------------------------------------

PROMPT CHECKING IF THERE ARE OWB REPOSITORIES ON THE DATABASE INSTANCE
PROMPT

DECLARE

  CURSOR schema_array IS
  SELECT owner
  FROM dba_tables WHERE table_name = 'CMPSYSCLASSES';

  c_installed_ver   integer;
  rows_processed    integer;
  v_schema          dba_tables.owner%TYPE;
  v_schema_cnt		integer;
  v_version         varchar2(15);
  
BEGIN
  OPEN schema_array;
  c_installed_ver := dbms_sql.open_cursor;
 
  <<owb_schema_loop>>
  LOOP -- For each valid schema...
    FETCH schema_array INTO v_schema;
    EXIT WHEN schema_array%notfound;
	
    --Determine if current schema is valid (contains CMPInstallation_V view)
    dbms_sql.parse(c_installed_ver,'select installedversion from '|| v_schema || '.CMPInstallation_v where name = ''Oracle Warehouse Builder''',dbms_sql.native);
	dbms_sql.define_column(c_installed_ver, 1, v_version, 15);
    
	rows_processed:=dbms_sql.execute ( c_installed_ver );

    loop -- Find OWB version.
      if dbms_sql.fetch_rows(c_installed_ver) > 0 then
        dbms_sql.column_value (c_installed_ver, 1, v_version);
        v_schema_cnt := v_schema_cnt + 1;

        dbms_output.put_line ('.');
        dbms_output.put_line ('Schema '||v_schema||' contains a version '||v_version||' repository');
      else
        exit;
      end if;
    end loop;
  end loop; 
END;
/
PROMPT
PROMPT If no repository is found, OWB IS NOT IN USE.
PROMPT If any repository is found, please run the additional OWB standalone script to determine if licenses are needed
PROMPT

PROMPT
PROMPT END OF SCRIPT
PROMPT
PROMPT
PROMPT *****************************************************
PROMPT *****************************************************
PROMPT *****************************************************
PROMPT *****                                           *****
PROMPT *****     Please ignore the section below.      *****
PROMPT ***** It is used for automatic processing only. *****
PROMPT *****                                           *****
PROMPT *****************************************************
PROMPT *****************************************************
PROMPT *****************************************************
PROMPT
PROMPT
PROMPT
PROMPT

-------------------------------------------
-------------------------------------------
-- Second stage, output for GREP command --
-------------------------------------------
-------------------------------------------

SET HEADING OFF
SET FEEDBACK OFF
--SET COLSEP ','
SET PAGESIZE 5000
SET LINESIZE 500
SET VERIFY OFF

col C3 new_val GREP_PREFIX noprint
SELECT 'GREP'||'ME>>,&&HOST_NAME.,&&INSTANCE_NAME.,' || SYSDATE || ',&&HOST_NAME.,' || name as C3 FROM v$database;

prompt &&GREP_PREFIX.,REVIEW_LITE,VERSION,,,&SCRIPT_RELEASE.,



-- DB Version
-------------
define  OPTION_NAME=V$VERSION
define OPTION_QUERY=NULL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM V$VERSION;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,"'||
        BANNER           ||'",'
  FROM V$VERSION;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- DB Options Installed
-----------------------
define  OPTION_NAME=V$OPTION
define OPTION_QUERY=NULL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM V$OPTION;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,"'||
        PARAMETER    ||'","'||
        VALUE        ||'",'
  FROM V$OPTION;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- DBA_REGISTRY (9i_r2 and higher)
----------------------------------
define  OPTION_NAME=DBA_REGISTRY
define OPTION_QUERY=>=9i_r2
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from DBA_REGISTRY;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        '"' || COMP_NAME || '",' || VERSION || ',' || STATUS || ',' || MODIFIED || ',' || SCHEMA || ','
  from DBA_REGISTRY;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- 10g DBA_FEATURE_USAGE_STATISTICS (10g and higher)
----------------------------------------------------
define  OPTION_NAME=DBA_FEATURE_USAGE_STATISTICS
define OPTION_QUERY=10g
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM DBA_FEATURE_USAGE_STATISTICS;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,"'||
        NAME               || '","'||
        VERSION            || '","'||
        DETECTED_USAGES    || '","'||
        TOTAL_SAMPLES      || '","'||
        CURRENTLY_USED     || '","'||
        FIRST_USAGE_DATE   || '","'||
        LAST_USAGE_DATE    || '","'||
        LAST_SAMPLE_DATE   || '","'||
        SAMPLE_INTERVAL    || '",'
  FROM DBA_FEATURE_USAGE_STATISTICS;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- Partitioning
---------------
define  OPTION_NAME=PARTITIONING
define OPTION_QUERY=PARTITIONED_SEGMENTS
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(distinct OWNER||','||SEGMENT_TYPE||','||SEGMENT_NAME)))) as OCOUNT
  FROM DBA_SEGMENTS
  WHERE SEGMENT_TYPE LIKE '%PARTITION%';

select distinct
        '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        OWNER||','||SEGMENT_TYPE||','||SEGMENT_NAME||','
  FROM DBA_SEGMENTS
  WHERE SEGMENT_TYPE LIKE '%PARTITION%';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- OLAP
-------
-- CUBES
define  OPTION_NAME=OLAP
define OPTION_QUERY=CUBES_COUNT
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM  OLAPSYS.DBA$OLAP_CUBES
  WHERE OWNER <>'SH';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) ||','
  FROM  OLAPSYS.DBA$OLAP_CUBES
  WHERE OWNER <>'SH';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);

-- ANALYTIC WORKSPACES
define  OPTION_NAME=OLAP
define OPTION_QUERY=ANALYTIC_WORKSPACES
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM DBA_AWS;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        OWNER        ||','||
        AW_NUMBER    ||','||
        AW_NAME      ||','||
        PAGESPACES   ||','||
        GENERATIONS  ||','
  FROM DBA_AWS;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- RAC (REAL APPLICATION CLUSTERS)
----------------------------------
define  OPTION_NAME=RAC
define OPTION_QUERY=GV$INSTANCE
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM GV$INSTANCE;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        instance_name    ||','||
        host_name        ||','||
        INST_ID          ||','
  FROM GV$INSTANCE;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- LABEL SECURITY
-----------------
define  OPTION_NAME=LABEL_SECURITY
define OPTION_QUERY=LBAC$POLT_COUNT
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM  LBACSYS.LBAC$POLT
  WHERE OWNER <> 'SA_DEMO';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) ||','
  FROM  LBACSYS.LBAC$POLT
  WHERE OWNER <> 'SA_DEMO';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);



-- OEM
------
-- Check for running known OEM Programs
define  OPTION_NAME=OEM
define OPTION_QUERY=RUNNING_PROGRAMS
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(distinct program)))) as OCOUNT
  FROM V$SESSION
  WHERE
      upper(program) LIKE '%XPNI.EXE%'
   OR upper(program) LIKE '%VMS.EXE%'
   OR upper(program) LIKE '%EPC.EXE%'
   OR upper(program) LIKE '%TDVAPP.EXE%'
   OR upper(program) LIKE 'VDOSSHELL%'
   OR upper(program) LIKE '%VMQ%'
   OR upper(program) LIKE '%VTUSHELL%'
   OR upper(program) LIKE '%JAVAVMQ%'
   OR upper(program) LIKE '%XPAUTUNE%'
   OR upper(program) LIKE '%XPCOIN%'
   OR upper(program) LIKE '%XPKSH%'
   OR upper(program) LIKE '%XPUI%';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,"'||
        PROGRAM   ||'",'
  FROM V$SESSION
  WHERE
      upper(program) LIKE '%XPNI.EXE%'
   OR upper(program) LIKE '%VMS.EXE%'
   OR upper(program) LIKE '%EPC.EXE%'
   OR upper(program) LIKE '%TDVAPP.EXE%'
   OR upper(program) LIKE 'VDOSSHELL%'
   OR upper(program) LIKE '%VMQ%'
   OR upper(program) LIKE '%VTUSHELL%'
   OR upper(program) LIKE '%JAVAVMQ%'
   OR upper(program) LIKE '%XPAUTUNE%'
   OR upper(program) LIKE '%XPCOIN%'
   OR upper(program) LIKE '%XPKSH%'
   OR upper(program) LIKE '%XPUI%';

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);

-- PL/SQL anonymous block to Check for known OEM tables
DECLARE
    cursor1 integer;
    v_count number(1);
    v_schema dba_tables.owner%TYPE;
    v_version varchar2(10);
    v_component varchar2(20);
    v_i_name varchar2(10);
    v_h_name varchar2(30);
    stmt varchar2(200);
    rows_processed integer;

    CURSOR schema_array IS
    SELECT owner
    FROM dba_tables WHERE table_name = 'SMP_REP_VERSION';

    CURSOR schema_array_v2 IS
    SELECT owner
    FROM dba_tables WHERE table_name = 'SMP_VDS_REPOS_VERSION';

BEGIN
    --DBMS_OUTPUT.PUT_LINE ('.');
    --DBMS_OUTPUT.PUT_LINE ('OEM REPOSITORY LOCATIONS');

    SELECT instance_name,host_name INTO v_i_name, v_h_name FROM v$instance;

    --DBMS_OUTPUT.PUT_LINE ('Instance: '||v_i_name||' on host: '||v_h_name);

    OPEN schema_array;
    OPEN schema_array_v2;

    cursor1 := dbms_sql.open_cursor;
    v_count := 0;

    LOOP -- this loop steps through each valid schema.
       FETCH schema_array INTO v_schema;
       EXIT WHEN schema_array%notfound;
       v_count := v_count + 1;
       dbms_sql.parse(cursor1,'select c_current_version, c_component from'||v_schema||'.smp_rep_version', dbms_sql.native);
       dbms_sql.define_column(cursor1, 1, v_version, 10);
       dbms_sql.define_column(cursor1, 2, v_component, 20);

       rows_processed:=dbms_sql.execute ( cursor1 );

       loop -- to step through cursor1 to find console version.
          if dbms_sql.fetch_rows(cursor1) >0 then
             dbms_sql.column_value (cursor1, 1, v_version);
             dbms_sql.column_value (cursor1, 2, v_component);
             if v_component = 'CONSOLE' then
                dbms_output.put_line ('&&GREP_PREFIX.,OEM,REPOSITORY1,'||v_count||',dbms_output,Schema '||rpad(v_schema,15)||' has a repository version '||v_version);
                exit;
             end if;
          else
             exit;
          end if;
       end loop;
    END LOOP;

    LOOP -- this loop steps through each valid V2 schema.
       FETCH schema_array_v2 INTO v_schema;
       EXIT WHEN schema_array_v2%notfound;
       v_count := v_count + 1;
       dbms_output.put_line ('&&GREP_PREFIX.,OEM,REPOSITORY2,'||v_count||',dbms_output,Schema '||rpad(v_schema,15)||' has a repository version 2.x' );
    end loop;
    dbms_sql.close_cursor (cursor1);
    close schema_array;
    close schema_array_v2;
    if v_count = 0 then
       dbms_output.put_line ('&&GREP_PREFIX.,OEM,NO_REPOSITORY,'||v_count||',dbms_output,There are NO OEM repositories with version prior to 10g on this instance - '||v_i_name||' on host '||v_h_name);
    end if;
END;
/

--- OEM 10G AND HIGHER
----------------------
define OEMOWNER=SYSMAN
col OEMOWNER new_val OEMOWNER format a30 wrap
select owner as OEMOWNER from dba_tables where table_name = 'MGMT_ADMIN_LICENSES';

define  OPTION_NAME=OEM
define OPTION_QUERY=MGMT_ADMIN_LICENSES
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from &&OEMOWNER..MGMT_LICENSE_DEFINITIONS a,
       &&OEMOWNER..MGMT_ADMIN_LICENSES      b,
      (select decode(count(*), 0, 'NO', 'YES') as PACK_ACCESS_AGREED
        from &&OEMOWNER..MGMT_LICENSES where upper(I_AGREE)='YES') c
  where a.pack_label = b.pack_name   (+);

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
       b.pack_name || ',' || a.pack_label || ',' || a.target_type || ',"' || a.pack_display_label || '","' || c.PACK_ACCESS_AGREED || '",'
  from &&OEMOWNER..MGMT_LICENSE_DEFINITIONS a,
       &&OEMOWNER..MGMT_ADMIN_LICENSES      b,
      (select decode(count(*), 0, 'NO', 'YES') as PACK_ACCESS_AGREED
        from &&OEMOWNER..MGMT_LICENSES where upper(I_AGREE)='YES') c
  where a.pack_label = b.pack_name   (+)
  order by 1;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);


-- OEM PACK ACCESS AGREEMENTS (10g or higher)
define  OPTION_NAME=OEM
define OPTION_QUERY=MGMT_LICENSES
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from &&OEMOWNER..MGMT_LICENSES
  ;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
       USERNAME || ',' || TIMESTAMP || ',"' || I_AGREE || '",'
  from &&OEMOWNER..MGMT_LICENSES
  order by TIMESTAMP;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);


-- OEM MANAGED DATABASES (10g or higher)
define  OPTION_NAME=OEM
define OPTION_QUERY=MGMT_TARGETS
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from &&OEMOWNER..MGMT_TARGETS
  where TARGET_TYPE = 'oracle_database'
  ;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
       '"' || TARGET_NAME || '","' || HOST_NAME || '",' || LOAD_TIMESTAMP || ','
  from &&OEMOWNER..MGMT_TARGETS
  where TARGET_TYPE = 'oracle_database'
  order by TARGET_NAME;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);


-- OEM MGMT_LICENSE_CONFIRMATION (10g or higher)
define  OPTION_NAME=OEM
define OPTION_QUERY=MGMT_LICENSE_CONFIRMATION
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from &&OEMOWNER..MGMT_LICENSE_CONFIRMATION a,
       &&OEMOWNER..MGMT_TARGETS b
  where a.target_guid = b.target_guid (+)
  ;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,"'||
       a.confirmation      || '","'  ||
       a.confirmed_by      || '","'  ||
       a.confirmed_time    || '","'  ||
       b.target_name       || '","'  ||
       b.target_type       || '","'  ||
       b.type_display_name || '",'
  from &&OEMOWNER..MGMT_LICENSE_CONFIRMATION a,
       &&OEMOWNER..MGMT_TARGETS b
  where a.target_guid = b.target_guid (+)
  order by 1;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);

-- OEM - SQL PROFILES USAGE (10g or higher)
define  OPTION_NAME=OEM
define OPTION_QUERY=SQL_PROFILES
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select count(*) as OCOUNT
  from dba_sql_profiles;
  
select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||count(*)
  from dba_sql_profiles;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);


-- SPATIAL
----------
define  OPTION_NAME=SPATIAL
define OPTION_QUERY=ALL_SDO_GEOM_METADATA
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from ALL_SDO_GEOM_METADATA;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        OWNER || ',' || TABLE_NAME || ',' || substr(COLUMN_NAME, 1, 250) || ','
  from ALL_SDO_GEOM_METADATA;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



-- DATA MINING
--------------

-- 9i
define  OPTION_NAME=DATA_MINING
define OPTION_QUERY=09i.ODM_MINING_MODEL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from ODM.ODM_MINING_MODEL;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from ODM.ODM_MINING_MODEL;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);


-- 10gv1
define  OPTION_NAME=DATA_MINING
define OPTION_QUERY=10gv1.DM$OBJECT
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from DMSYS.DM$OBJECT;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from DMSYS.DM$OBJECT;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);


define  OPTION_NAME=DATA_MINING
define OPTION_QUERY=10gv1.DM$MODEL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from DMSYS.DM$MODEL;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from DMSYS.DM$MODEL;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);


-- 10gv2
define  OPTION_NAME=DATA_MINING
define OPTION_QUERY=10gv2.DM$P_MODEL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from DMSYS.DM$P_MODEL;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from DMSYS.DM$P_MODEL;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. = -942;


-- 11g
define  OPTION_NAME=DATA_MINING
define OPTION_QUERY=11g.DM$P_MODEL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from SYS.MODEL$;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from SYS.MODEL$;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. = -942;


-- DATABASE VAULT
-----------------
select '&&GREP_PREFIX.,DATABASE_VAULT,DVSYS_SCHEMA,'||count(*)||',count,'||MAX(username)||','
  from dba_users where UPPER(username)='DVSYS';

select '&&GREP_PREFIX.,DATABASE_VAULT,DVF_SCHEMA,'||count(*)||',count,'||MAX(username)||','
  from dba_users where UPPER(username)='DVF';


define  OPTION_NAME=DATABASE_VAULT
define OPTION_QUERY=DBA_DV_REALM
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from DVSYS.DBA_DV_REALM;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from DVSYS.DBA_DV_REALM;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);



-- AUDIT VAULT
--------------
select '&&GREP_PREFIX.,AUDIT_VAULT*,AVSYS_SCHEMA,'||count(*)||',count,'||MAX(username)||','
  from dba_users where UPPER(username)='AVSYS';



-- CONTENT DATABASE and RECORDS DATABASE
----------------------------------------
select '&&GREP_PREFIX.,CONTENT_AND_RECORDS,CONTENT_SCHEMA,'||count(*)||',count,'||MAX(username)||','
  from dba_users where UPPER(username)='CONTENT';

-- CONTENT
define  OPTION_NAME=CONTENT_DATABASE
define OPTION_QUERY=ODM_DOCUMENT
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from ODM_DOCUMENT;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from ODM_DOCUMENT;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);

-- RECORDS
define  OPTION_NAME=RECORDS_DATABASE
define OPTION_QUERY=ODM_RECORD
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  from ODM_RECORD;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        count(*) || ','
  from ODM_RECORD;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942);

-- ASO
define OPTION_NAME=ADVANCED_SECURITY
define OPTION_QUERY=SESSION_SCAN
col    OCOUNT new_val OCOUNT noprint
SELECT COUNT(AUTHENTICATION_TYPE||','||SID||','||OSUSER||',"'||NETWORK_SERVICE_BANNER||'",') as OCOUNT
  FROM V$SESSION_CONNECT_INFO
 WHERE LOWER(NETWORK_SERVICE_BANNER) like '%authentication service%'
    OR LOWER(NETWORK_SERVICE_BANNER) like '%encryption service%'
    OR LOWER(NETWORK_SERVICE_BANNER) like '%crypto_checksumming%';

SELECT '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        AUTHENTICATION_TYPE||','||SID||','||OSUSER||',"'||NETWORK_SERVICE_BANNER || '",'
  FROM V$SESSION_CONNECT_INFO
 WHERE LOWER(NETWORK_SERVICE_BANNER) like '%authentication service%'
    OR LOWER(NETWORK_SERVICE_BANNER) like '%encryption service%'
    OR LOWER(NETWORK_SERVICE_BANNER) like '%crypto_checksumming%';

SELECT '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  FROM DUAL WHERE &&OCOUNT. in (-942);

DEFINE OPTION_QUERY=COLUMN_ENCRYPTION
COL    OCOUNT new_val OCOUNT noprint
SELECT COUNT(*) as OCOUNT
  FROM DBA_ENCRYPTED_COLUMNS;

SELECT '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
       OWNER || ',' || TABLE_NAME || ',' ||COLUMN_NAME || ',' FROM DBA_ENCRYPTED_COLUMNS;

SELECT '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  FROM DUAL WHERE &&OCOUNT. in (-942);
  
DEFINE OPTION_QUERY=TABLESPACE_ENCRYPTION
COL    OCOUNT new_val OCOUNT noprint
SELECT COUNT(*) as OCOUNT
  FROM DBA_TABLESPACES 
 WHERE ENCRYPTED ='YES';
 
SELECT '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
       TABLESPACE_NAME || ',' || ENCRYPTED ||','
  FROM DBA_TABLESPACES 
 WHERE ENCRYPTED ='YES';  

SELECT '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
       decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  FROM DUAL WHERE &&OCOUNT. in (-942);
  
  
-- OWB
define OPTION_NAME=OWB
define OPTION_QUERY=REPOSITORY

DECLARE

  CURSOR schema_array IS
  SELECT owner
  FROM dba_tables WHERE table_name = 'CMPSYSCLASSES';

  c_installed_ver   integer;
  rows_processed    integer;
  v_schema          dba_tables.owner%TYPE;
  v_schema_cnt		integer;
  v_version         varchar2(15);
  
BEGIN
  OPEN schema_array;
  c_installed_ver := dbms_sql.open_cursor;
 
  <<owb_schema_loop>>
  LOOP -- For each valid schema...
    FETCH schema_array INTO v_schema;
    EXIT WHEN schema_array%notfound;
	
    --Determine if current schema is valid (contains CMPInstallation_V view)
    dbms_sql.parse(c_installed_ver,'select installedversion from '|| v_schema || '.CMPInstallation_v where name = ''Oracle Warehouse Builder''',dbms_sql.native);
	dbms_sql.define_column(c_installed_ver, 1, v_version, 15);
    
	rows_processed:=dbms_sql.execute ( c_installed_ver );

      loop -- Find OWB version.
        if dbms_sql.fetch_rows(c_installed_ver) > 0 then
          dbms_sql.column_value (c_installed_ver, 1, v_version);
          v_schema_cnt := v_schema_cnt + 1;

          dbms_output.put_line ('.');
          dbms_output.put_line ('&&GREP_PREFIX.,&&OPTION_NAME.,&&OPTION_QUERY.'||',1,1,'||'Schema '||v_schema||' contains a version '||v_version||' repository');
        else
          exit;
        end if;
      end loop;
  end loop; 
END;
/

  
  
-- CPU/CORES/SOCKETS (For 10g_r2 and higher)
--------------------------------------------
define  OPTION_NAME=CPU_CORES_SOCKETS
define OPTION_QUERY=10g_r2.V$LICENSE
define OCOUNT=-904
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(CPU_CORE_COUNT_HIGHWATER||CPU_SOCKET_COUNT_HIGHWATER)))) as OCOUNT
  from V$LICENSE;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        SESSIONS_HIGHWATER         ||','||
        CPU_COUNT_CURRENT          ||','||
        CPU_CORE_COUNT_CURRENT     ||','||
        CPU_SOCKET_COUNT_CURRENT   ||','||
        CPU_COUNT_HIGHWATER        ||','||
        CPU_CORE_COUNT_HIGHWATER   ||','||
        CPU_SOCKET_COUNT_HIGHWATER ||','
  from V$LICENSE;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00904: invalid column name",')
  from dual where &&OCOUNT. in (-904, 0);


-- GV$PARAMETER
--------------------------------------------
define  OPTION_NAME=GV$PARAMETER
define OPTION_QUERY=NULL
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM GV$PARAMETER
  where  upper(name) like '%CPU_COUNT%'
      or upper(name) like '%FAL_CLIENT%'
      or upper(name) like '%FAL_SERVER%'
      or upper(name) like '%CLUSTER%'
      or upper(name) like '%CONTROL_MANAGEMENT_PACK_ACCESS%'
  ;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,"'||
        INST_ID      ||'","'||
        NAME         ||'","'||
        VALUE        ||'","'||
        ISDEFAULT    ||'","'||
        DESCRIPTION  ||'",'
  FROM GV$PARAMETER
  where  upper(name) like '%CPU_COUNT%'
      or upper(name) like '%FAL_CLIENT%'
      or upper(name) like '%FAL_SERVER%'
      or upper(name) like '%CLUSTER%'
      or upper(name) like '%CONTROL_MANAGEMENT_PACK_ACCESS%'
  order by NAME, INST_ID;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);



PROMPT *** EXTRA INFO *** ReviewLite_conc
------------------------------------------

-- V$LICENSE
define  OPTION_NAME=EXTRA_INFO
define OPTION_QUERY=V$LICENSE
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM V$LICENSE;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        SESSIONS_MAX          ||','||
        SESSIONS_WARNING      ||','||
        SESSIONS_CURRENT      ||','||
        SESSIONS_HIGHWATER    ||','||
        USERS_MAX             ||','
  FROM V$LICENSE;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);


-- V$SESSION
define  OPTION_NAME=EXTRA_INFO
define OPTION_QUERY=V$SESSION
define OCOUNT=-942
col OCOUNT new_val OCOUNT noprint
select ltrim(rtrim(to_char(count(*)))) as OCOUNT
  FROM V$SESSION;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,count,'||
        SID          || ',' ||
        SERIAL#      || ',"'||
        USERNAME     ||'","'||
        COMMAND      ||'","'||
        STATUS       ||'","'||
        SERVER       ||'","'||
        SCHEMANAME   ||'","'||
        OSUSER       ||'","'||
        PROCESS      ||'","'||
        MACHINE      ||'","'||
        TERMINAL     ||'","'||
        PROGRAM      ||'","'||
        TYPE         ||'","'||
        MODULE       ||'","'||
        ACTION       ||'","'||
        CLIENT_INFO  ||'","'||
        LAST_CALL_ET ||'","'||
        LOGON_TIME   ||'",'
  FROM V$SESSION;

select '&&GREP_PREFIX.,&OPTION_NAME.,&OPTION_QUERY.,&&OCOUNT.,'||
        decode(&&OCOUNT., 0, 'count,', '"ORA-00942: table or view does not exist",')
  from dual where &&OCOUNT. in (-942, 0);


-- Check User Privileges, for troubleshooting
select '&&GREP_PREFIX.,USER_PRIVS,USER_SYS_PRIVS,,,'||
        USERNAME     || ',' ||
        PRIVILEGE    || ','
  FROM USER_SYS_PRIVS;

select '&&GREP_PREFIX.,USER_PRIVS,USER_ROLE_PRIVS,,,'||
        USERNAME     || ',' ||
        GRANTED_ROLE || ','
  FROM USER_ROLE_PRIVS;


PROMPT
PROMPT END OF SCRIPT
SPOOL OFF

EXIT

