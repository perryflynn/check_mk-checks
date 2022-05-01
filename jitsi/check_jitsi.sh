#!/usr/bin/env bash

JSON=$(curl -s http://127.0.0.1:8080/colibri/stats)
JCODE=$?

VERSION=$(curl -s http://127.0.0.1:8080/about/version)
JVERSION=$?

service=jitsi-meet
scode=3
sname=Unknown
metrics="-"
detail="No more output"

if [ $JCODE -eq 0 ] && [ $JVERSION -eq 0 ]
then

    m_bitsdown=$(echo "$JSON" | jq -r .bit_rate_download)
    m_bitsup=$(echo "$JSON" | jq -r .bit_rate_upload)
    m_confer=$(echo "$JSON" | jq -r .conferences)
    m_partici=$(echo "$JSON" | jq -r .participants)
    m_threads=$(echo "$JSON" | jq -r .threads)
    m_videostr=$(echo "$JSON" | jq -r .endpoints_sending_video)

    scode=0
    sname=OK
    metrics="bitrate_download=$m_bitsdown|bitrate_upload=$m_bitsup|conference_count=$m_confer|participant_count=$m_partici|thread_count=$m_threads|videostream_count=$m_videostr"
    detail="Conferences: $m_confer; Participants: $m_partici; Video Streams: $m_videostr"

else
    scode=2
    sname=Critical
    detail="Connection to REST API failed"
fi

echo "$scode $service $metrics $sname: $detail"