-- Deze functie kan worden gebruikt om te testen of een document vanuit een Oracle drectory kan worden geopend.
-- aanroepen getclobdocument(<documentnaam>
CREATE OR REPLACE FUNCTION CODANL.getClobDocument
      (filename in varchar2,
        charset  in varchar2 default NULL)
      return clob deterministic
    is
      file       bfile := bfilename ('OMEGA_DIR', filename);
      charContent CLOB := ' ';
      targetfile  bfile;
      lang_ctx    number := DBMS_LOB.default_lang_ctx;
     charset_id  number := 0;
     src_offset  number := 1;
     dst_offset  number := 1;
     warning       number;
   begin
     if charset is not null then
        charset_id := NLS_CHARSET_ID(charset);
     end if;
      targetFile := file;
      IF DBMS_LOB.ISOPEN (targetFile) <> 0
     THEN DBMS_LOB.CLOSE (targetfile);
     END IF;
      DBMS_LOB.fileopen(targetFile,DBMS_LOB.file_readonly);
      DBMS_LOB.LOADCLOBFROMFILE(charContent,
                    targetFile,
                    DBMS_LOB.getLength(targetFile),
                    src_offset,
                    dst_offset,
                    charset_id,
                    lang_ctx,
                    warning);
   
     DBMS_LOB.fileclose(targetFile);
      return charContent;
    end getClobDocument;
/