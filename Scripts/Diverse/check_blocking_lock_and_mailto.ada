procedure VAN_PRC_BLOCKINGLOCK
is
  V_MSG varchar2(4000);
  V_LIVEENVIROMENT char(1);

  cursor C_LOCKS is
    select
      SID,
      INST_ID
    from
      GV$LOCK l
    where
      l.REQUEST = 0 and
      (l.ID1, l.ID2, l.TYPE) in (select
                                   ll.ID1,
                                   ll.ID2,
                                   ll.TYPE
                                 from
                                   GV$LOCK ll
                                 where
                                   ll.REQUEST > 0);

  procedure SENDEMAIL(P_EMAILADDRESS in varchar2,
                      P_BODY in varchar2,
                      P_SUBJECT in varchar2 := 'Locks detected on oracle',
                      P_SENDER in varchar2 := 'oracleserver@coolblue.nl') is
  begin

    insert into VAN_MAILQUEUE(
      MAILSUBJECT,
      MAILBODY,
      SENDER,
      EMAILSENDERNAME,
      RECIPIENT)
    values
      (P_SUBJECT,
       P_BODY,
       P_SENDER,
       'Coolblue',
       P_EMAILADDRESS);
  end;

begin
  select
    BOOLEANVALUE
  into
    V_LIVEENVIROMENT
  from
    VAN_SETTING
  where
    upper(SETTING) = 'LIVEENVIRONMENT';

  if V_LIVEENVIROMENT = 'Y' /*[VAN_CONST.BOOLEAN_TRUE]*/ then

    -- For all found locks
    for l in C_LOCKS loop

      select
        'Time: ' || to_char(sysdate, 'DD-MM-YYYY HH24:mi:SS') || CRLF ||
        'Server: ' || inst.INSTANCE_NAME ||  '::' || inst.HOST_NAME || CRLF ||
        'Sid: ' || ses.SID || CRLF ||
        'Pid: ' || pro.PID || CRLF ||
        'Spid: ' || pro.SPID || CRLF ||
        'Machine: ' || ses.MACHINE || CRLF ||
        'Username: ' || pro.USERNAME || CRLF ||
        'User: ' || ses.OSUSER ||CRLF ||
        'State: ' || ses.STATE || CRLF ||
        'Wait_time:  ' || ses.WAIT_TIME || CRLF ||
        'Wait_class: ' ||  ses.WAIT_CLASS as MSG
      into
        V_MSG
      from
        GV$SESSION ses
        inner join GV$PROCESS pro on pro.ADDR = ses.PADDR and
                                     pro.INST_ID = ses.INST_ID
        inner join GV$INSTANCE inst on inst.INST_ID = ses.INST_ID
      where
        ses.SID = l.SID and
        ses.INST_ID = l.INST_ID;

      -- Send warning email
      SENDEMAIL('oraclelock@coolblue.nl', V_MSG);

    end loop;

  end if;
end VAN_PRC_BLOCKINGLOCK;

