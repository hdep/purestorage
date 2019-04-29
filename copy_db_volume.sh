#!/bin/bash -x

ARRAY_URL=https://purestorage.domain.local/api/1.15
TOKEN=******
COOKIE=/tmp/cookie.$$
SRC_VOLUME=SRCVOL1
DST_VOLUME=SRCVOL2
SUFFIX=script-$$


#get the session
echo "Ouverture de la session"
RESULT=$(curl -X POST -k -H 'Content-Type: application/json' -i "${ARRAY_URL}/auth/session" --data "{\"api_token\":\""${TOKEN}\""}" -c  ${COOKIE} -s -o /dev/null -w "%{http_code}")

if [ "${RESULT}" -ne "200" ]; then
  echo "la reponse du serveur n'est pas 200 arret du script"
  exit 1
fi


# take a snapshot of source volume
echo "creation du snapshot"
RESULT=$(curl -X POST -k -H 'Content-Type: application/json' -i "${ARRAY_URL}/volume" -k -b ${COOKIE} --data "{
    \"snap\": true,
    \"source\":  [
    \"${SRC_VOLUME}\"
    ],
    \"suffix\": \"${SUFFIX}\"
}"  -s -o /dev/null -w "%{http_code}")

if [ "${RESULT}" -ne "200" ]; then
  echo "la reponse du serveur n'est pas 200 arret du script"
  exit 1
fi


# restore snapshot on a volume
echo "restauration du snapshot"
RESULT=$(curl -X POST -k -H 'Content-Type: application/json' -i "${ARRAY_URL}/volume/${DST_VOLUME}" -k -b ${COOKIE} --data "{
  \"source\": \"${SRC_VOLUME}.${SUFFIX}\",
  \"overwrite\": true
}"  -s -o /dev/null -w "%{http_code}")

if [ "${RESULT}" -ne "200" ]; then
  echo "la reponse du serveur n'est pas 200 arret du script"
  exit 1
fi

# delete snapshot
if [ -z "$SUFFIX" ]
then
      echo "\$SUFFIX is empty"
      exit 1
fi
echo "suppression du snapshot"
RESULT=$(curl -X DELETE -k -H 'Content-Type: application/json' -i "${ARRAY_URL}/volume/${SRC_VOLUME}.${SUFFIX}" -k -b ${COOKIE}  -s -o /dev/null -w "%{http_code}")
if [ "${RESULT}" -ne "200" ]; then
  echo "la reponse du serveur n'est pas 200 arret du script"
  exit 1
fi

# delete session file
rm ${COOKIE}
