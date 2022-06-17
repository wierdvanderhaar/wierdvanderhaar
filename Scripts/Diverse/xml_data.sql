declare
   --
   type r_statement is record ( node_name    varchar2(30)
                              , sqlstatement clob );
   type t_statements is table of r_statement;
   tab_statements   t_statements;
   rec_statement    r_statement;
   --
   type r_mail_to is record ( type  varchar2(3)
                            , naam  varchar2(50)
                            , email varchar2(256) );
   type t_mail_to is table of r_mail_to;
   tab_mail_to      t_mail_to := t_mail_to();
   rec_mail_to      r_mail_to;
   --
   vClobXml         clob;
   crlf             CONSTANT CHAR(1) := CHR(10);
   tagLevel         number := 1;
   tagLevelAdd      number := 0;
   --
   smtp_host        varchar2(256);
   smtp_port        pls_integer ;
   smtp_domain      varchar2(256);
   l_sender         varchar2(100) := 'no-reply@bla.nl';
   --
   --
   procedure settings as
   begin
      --
      rec_mail_to.type  := 'TO';
      rec_mail_to.naam  := 'DBA CMDB';
      rec_mail_to.email := 'ludo.deheus@dba.nl';
      tab_mail_to.extend;
      tab_mail_to(tab_mail_to.count) := rec_mail_to;
      --
      rec_mail_to.type  := 'TO';
      rec_mail_to.naam  := 'DBA CMDB';
      rec_mail_to.email := 'cmdb@dba.nl';
      tab_mail_to.extend;
      tab_mail_to(tab_mail_to.count) := rec_mail_to;
      --
   end settings;
   --
   --
   procedure vul_statements as
      --
   begin
      --
      tab_statements := t_statements();
      --
      rec_statement.node_name := 'ALG';
      rec_statement.sqlstatement := 'select to_char(sysdate,''DD-MM-YYYY'') cdate, ''UPDATE_CMDB'' message_type,  mail_host, smtp_port, email_address from sysman.MGMT_NOTIFY_EMAIL_GATEWAY';
      tab_statements.extend;
      tab_statements(tab_statements.count) := rec_statement;
      --
      rec_statement.node_name := 'SRV';
      rec_statement.sqlstatement := 'select * from sysman.gc$target where target_type = ''host''';
      tab_statements.extend;
      tab_statements(tab_statements.count) := rec_statement;
      --
      rec_statement.node_name := 'DBS';
      rec_statement.sqlstatement := 'select * from sysman.cm$mgmt_db_dbninstanceinfo_ecm';
      tab_statements.extend;
      tab_statements(tab_statements.count) := rec_statement;
      --
   end vul_statements;
   --
   --
   function translate( p_str in varchar2 ) return varchar2
   as
      l_str varchar2(32000);
   begin
      l_str := p_str;
      l_str := replace(l_str,'<',     chr(38)||'lt;');
      l_str := replace(l_str,'>',     chr(38)||'gt;');
      l_str := replace(l_str,chr(38), chr(38)||'amp;');
      l_str := replace(l_str,chr(39), chr(38)||'apos;');
      l_str := replace(l_str,'"',     chr(38)||'quot;');
      return l_str;
   end translate;
   --
   --
   procedure write ( p_line in varchar2 ) as
      --
      vSpatie   varchar2(200);
      --
   begin
      --
      if (tagLevelAdd < 0) then
         tagLevel := tagLevel - 1;
      end if;
      --
      vSpatie := rpad('  ',(tagLevel-1)*2,' ');
      --
      dbms_lob.append(vClobXml, vSpatie||p_line||crlf);
      --
      if (tagLevelAdd > 0) then
         tagLevel := tagLevel + 1;
      end if;
      --
      tagLevelAdd := 0;
      --
   end write;
   --
   --
   function openTag ( p_tagname in varchar2
                    , p_subtag  in varchar2 default null
                    , p_content in varchar2 default null )
   return varchar2
   as
      --
      l_str   varchar2(32767)   := null;
      --
   begin
      tagLevelAdd := 1;
      --
      l_str := '<'||p_tagname;
      --
      if (p_subtag is not null) then
         l_str := l_str||' '||p_subtag||'="'||p_content||'"';
      end if;
      --
      l_str := l_str||'>';
      --
      return l_str;
   end openTag;
   --
   --
   function closeTag ( p_tagname in varchar2 )
   return varchar2
   as
   begin
      tagLevelAdd := -1;
      --
      return('</'||p_tagname||'>');
   end closeTag;
   --
   --
   function dataTag ( p_tagname     in     varchar2
                    , p_content     in     varchar2 default null
                    , p_stop_tag    in     boolean  default true )
   return varchar2
   as
      --
      l_str   varchar2(32767)   := null;
   begin
      --
      l_str := '<'||p_tagname;
      if not(p_stop_tag) then
         l_str := l_str||'>';
      elsif p_content is null then
         l_str := l_str||'/>';
      else
         l_str := l_str||'>'||translate(p_content)||'</'||p_tagname||'>';
      end if;
      return l_str;
   end dataTag;
   --
   --
   procedure init_xml as
   begin
      --
      vul_statements;
      --
      settings;
      --
      dbms_lob.createtemporary(vClobXml, true);
      dbms_lob.append(vClobXml, '<?xml version="1.0" encoding="ISO-8859-1"?>'||crlf);
      dbms_lob.append(vClobXml, '<!-- generated on '||to_char(sysdate,'DD-MM-YYYY HH24:MI')||' -->'||crlf);
   end init_xml;
   --
   --
   procedure create_xml_file as
      --
      l_cur     integer default dbms_sql.open_cursor;
      l_colcnt  number default 0;
      l_desc    dbms_sql.desc_tab;
      l_status  integer;
      l_colval  varchar2(4000);
      --
   begin
      --
      if ( tab_statements.count > 0 ) then
         --
         write(openTag('CMDB'));
         --
         for i in tab_statements.first .. tab_statements.last loop
            --
            write(openTag(tab_statements(i).node_name));
            --
            dbms_sql.parse(l_cur, tab_statements(i).sqlstatement, dbms_sql.native);
            dbms_sql.describe_columns(l_cur, l_colcnt, l_desc);
            --
            -- execute query
            l_status := dbms_sql.execute(l_cur);
            --
            for j in 1 .. l_colcnt loop
               dbms_sql.define_column(l_cur, j, l_colval, 4000);
            end loop;
            --
            while (dbms_sql.fetch_rows(l_cur) > 0) loop
               write(openTag('ROW'));
               for j in 1 .. l_colcnt loop
                  dbms_sql.column_value(l_cur, j, l_colval);
                  --dbms_output.put_line('l_colval['||l_colval||']');
                  --dbms_output.put_line('l_colcnt['||l_desc(j).col_name||']');
                  write(dataTag(l_desc(j).col_name, l_colval));
               end loop;
               write(closeTag('ROW'));
            end loop;
            --
            write(closeTag(tab_statements(i).node_name));
            --
         end loop;
         --
         write(closeTag('CMDB'));
      end if;
      --
   end create_xml_file;
   --
   --
   procedure mail_xml_file as
      --
      l_conn                 utl_smtp.connection;
      l_receiver_to          varchar2(4000);
      l_receiver_cc          varchar2(4000);
      l_receiver_bcc         varchar2(4000);
      --
   begin
      --
      --
      select mail_host
           , nvl(smtp_port, 25)
           , email_address
--           , nvl(email_name,email_address)||'<'||email_address||'>'
--           , smtp_pwd_salt
        into smtp_host
           , smtp_port
           , l_sender
      from sysman.MGMT_NOTIFY_EMAIL_GATEWAY;

      --
      --smtp_host  := 'mail.dba.nl';
	  --l_sender := 'servicedesk@dba.nl';
      --
      l_conn := utl_smtp.open_connection(smtp_host, smtp_port);
      utl_smtp.helo(l_conn, smtp_host);
      --
	  --
      utl_smtp.mail(l_conn, l_sender);
      --
      -- Specify recipient(s) of the email.
      for i in tab_mail_to.first .. tab_mail_to.last loop
         --
         utl_smtp.rcpt(l_conn, tab_mail_to(i).email);
         --
         case tab_mail_to(i).type
            when 'TO' then l_receiver_to := l_receiver_to || nvl(tab_mail_to(i).naam,tab_mail_to(i).email)||'<'||tab_mail_to(i).email||'>;';
            when 'CC' then l_receiver_cc := l_receiver_cc || nvl(tab_mail_to(i).naam,tab_mail_to(i).email)||'<'||tab_mail_to(i).email||'>;';
            else           l_receiver_bcc := l_receiver_bcc || nvl(tab_mail_to(i).naam,tab_mail_to(i).email)||'<'||tab_mail_to(i).email||'>;';
         end case;
         --
      end loop;
      --
      l_receiver_to := substr(l_receiver_to,1,length(l_receiver_to)-1);
      l_receiver_cc := substr(l_receiver_cc,1,length(l_receiver_cc)-1);
      l_receiver_bcc := substr(l_receiver_bcc,1,length(l_receiver_bcc)-1);
      --
      -- Start body of email
      utl_smtp.open_data(l_conn);
      --
      -- Set "From" MIME header
      utl_smtp.write_data(l_conn, 'From' || ': ' || l_sender || utl_tcp.CRLF);
      --
      -- Set "To" MIME header
      utl_smtp.write_data(l_conn, 'To' || ': ' || l_receiver_to || utl_tcp.CRLF);
      if ( l_receiver_cc is not null ) then
         utl_smtp.write_data(l_conn, 'Cc' || ': ' || l_receiver_cc || utl_tcp.CRLF);
      end if;
      if ( l_receiver_bcc is not null ) then
         utl_smtp.write_data(l_conn, 'Bcc' || ': ' || l_receiver_bcc || utl_tcp.CRLF);
      end if;
      --
      -- Set "Subject" MIME header
      utl_smtp.write_data(l_conn, 'Subject' || ': ' ||'CMDB update ('||to_char(sysdate,'DD-MM-YYYY')||')' || utl_tcp.CRLF);
      --
      -- Send an empty line to denotes end of MIME headers and
      -- beginning of message body.
      utl_smtp.write_data(l_conn, utl_tcp.CRLF);
      --
      utl_smtp.write_data(l_conn, vClobXml||utl_tcp.crlf);
      utl_smtp.write_data(l_conn, utl_tcp.crlf);
      --
      utl_smtp.close_data(l_conn);
      utl_smtp.Quit(l_conn);
      --
   end mail_xml_file;
   --
   --
begin
   --
   init_xml;
   --
   create_xml_file;
   --
   mail_xml_file;
   --
   --dbms_output.put_line(vClobXml);
   dbms_lob.freetemporary(vClobXml);
   --
end;
/

