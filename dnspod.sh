#!/bin/bash

RECORD_FILE="/tmp/_acme-challenge.${CERTBOT_DOMAIN}_${CERTBOT_VALIDATION}"

if ! command -v tccli >/dev/null; then
	echo "TCCLI is required: https://cloud.tencent.com/document/product/440" 1>&2
	exit 1
fi

if [ "$1" = "clean" ]; then
	echo "Delete record: _acme-challenge.${CERTBOT_DOMAIN} IN TXT ${CERTBOT_VALIDATION}"
	RECORD_ID=$(cat ${RECORD_FILE})
	if [ -n "${RECORD_ID}" ]; then
		tccli dnspod DeleteRecord --cli-unfold-argument \
			--Domain ${CERTBOT_DOMAIN} \
			--RecordId ${RECORD_ID} \
			--profile certbot \
			>/dev/null
	fi
	rm -f ${RECORD_FILE}
else
	echo "Create record: _acme-challenge.${CERTBOT_DOMAIN} IN TXT ${CERTBOT_VALIDATION}"
	RECORD_ID=$(tccli dnspod CreateRecord --cli-unfold-argument \
		--Domain ${CERTBOT_DOMAIN} \
		--SubDomain _acme-challenge \
		--RecordType TXT \
		--RecordLine 默认 \
		--Value ${CERTBOT_VALIDATION} \
		--profile certbot \
		| grep "RecordId" \
		| grep -Eo "[0-9]+")
	echo ${RECORD_ID} > ${RECORD_FILE}
	echo "Sleep 20 seconds..."
	sleep 20
fi
