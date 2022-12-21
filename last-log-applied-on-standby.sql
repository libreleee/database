select thread#, Max(sequence#) 
FROM v$archived_log
WHERE  applied = ‘YES’
GROUP  BY thread#; 