-- Copyright 2018 Tanel Poder. All rights reserved. More info at http://tanelpoder.com
-- Licensed under the Apache License, Version 2.0. See LICENSE.txt for terms & conditions.

select
    name 
from
    system_privilege_map
where
    lower(name) like lower('%&1%')
/

