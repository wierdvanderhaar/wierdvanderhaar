ALTER DISKGROUP data
  ADD TEMPLATE hot_datafile
ATTRIBUTES (UNPROTECTED FINE HOT );

CREATE TABLESPACE hot_stuff
 DATAFILE '+DATA(HOT_DATAFILE)' SIZE 256 M;
