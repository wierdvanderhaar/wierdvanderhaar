-- Copyright 2018 Tanel Poder. All rights reserved. More info at http://tanelpoder.com
-- Licensed under the Apache License, Version 2.0. See LICENSE.txt for terms & conditions.

COL sql_text FOR A200 WORD_WRAP

SELECT
    *
FROM
    dba_hist_sqltext
WHERE
    sql_id = '&1'
/
