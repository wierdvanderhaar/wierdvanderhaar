#! /bin/bash
export ECHT=$1
if [ ${ECHT} = Y ] 
then
echo "Je hebt ervoor gekozen om de server down te brengen met dit script! Je hebt 10 seconden om dit te cancellen met ctrl+c."
sleep 10
echo "Going down........." 
shutdown -h now
else
echo "Als je echt de server wilt down brengen met dit script zul je de parameter Y moeten meegeven" 
exit
fi
