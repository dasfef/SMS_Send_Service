#!/bin/bash

###################### SENDING HAPPY BIRTH DAY SMS ######################
# DATE : 2024-03-26
# MADE : CHOI YEON WOONG
# targetDate=DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 7 DAY), '%m-%d');
#########################################################################

# SERVER INFORMATION
USER_ID=""
USER_KEY=""
SMS_SERVER=""
FROM_NUMBER=""

# DATABASE CONNECT & SELECT QUERY TO MAKE JSON FILES
MYSQL_PWD="PASSWORD" mysql -u {USER} -D pcas -se "SELECT JSON_OBJECT('MB_NICK', MB_NICK) FROM m_member WHERE DATE_FORMAT(CURDATE(), '%m-%d') = DATE_FORMAT(DATE_SUB(mb_limitdate, INTERVAL 7 DAY), '%m-%d');" | jq --slurp . > PERSON.json

# FIND PHONE NUMBERS(DEPT: IT전략팀)
MYSQL_PWD="PASSWORD" mysql -u {USER} -D pcas -se "SELECT JSON_OBJECT('MB_TEL', MB_TEL) FROM m_member WHERE MB_DEPT = 'IT전략팀' AND MB_DEL = 'N' AND MB_NICK != 'IT전략팀';" | jq --slurp . > PHONE_NUMBERS.json

# SETTING INFORMATION
BIRTH=`date -d "+7 days" "+%Y-%m-%d(%a요일)"`
PERSON=($(jq -r '[.[] | .MB_NICK] | join(",")' PERSON.json))
# PHONE_NUMBERS=($(jq -r '[.[] | .MB_TEL] | join(",")' PHONE_NUMBERS.json))
PHONE_NUMBERS=($(jq -r '[.[] | .MB_TEL | "\"\(.)\""] | join(",")' PHONE_NUMBERS.json))
echo "-- BIRTH 값: ${BIRTH}"
echo "-- PERSON 값: ${PERSON[@]}"
echo "-- PHONE_NUMBERS 값: ${PHONE_NUMBERS[@]}"
# echo "PERSON 배열크기: ${#PERSON[@]}"
# echo "PHONE_NUMBERS 배열크기: ${#PHONE_NUMBERS[@]}"

# SETTING FOR SENDING TEXT
NAME=$(echo "${PERSON[*]}" | sed 's/ /,/g')
SENDING_TEXT="[생일자알림]\nIT전략팀의 ${NAME}님이 \n${BIRTH} 생일입니다"
echo "-- TEXT 내용: $SENDING_TEXT"

# HOW TO JOIN WITH IFS(USELESS)
# PHONE_NUMBERS_JOIN=$(IFS=','; echo "${PHONE_NUMBERS[*]}")
# echo $PHONE_NUMBERS_JOIN
# echo "모든 인덱스: ${!PHONE_NUMBERS[@]}"

# SETTING PHONE_NUMBERS TO SMS API STRUCTURE
sms_tonum="["
for i in "${!PHONE_NUMBERS[@]}"; do			# GET INDEX BY ${![@]}
	if [ "$i" -ne 0 ]; then					# IF INDEX IS NOT 0
		sms_tonum+=","						# ADD COMMA(,)
	fi
	sms_tonum+="${PHONE_NUMBERS[$i]}"
done
sms_tonum+="]"

echo "-- sms_tonum: $sms_tonum"


# IF PERSON >= 1 >> REQUEST HTTP POST
if [ "${#PERSON[@]}" -ge 1 ]; then
	DATA="sms_usrid=${USER_ID}&sms_ackey=${USER_KEY}&sms_frnum=${FROM_NUMBER}&sms_tonum=&sms_text=${SENDING_TEXT}"
	# curl -X POST ${SMS_SERVER} 	-d 	"sms_usrid=${USER_ID}"\
								-d	"&sms_ackey=${USER_KEY}"\
								-d	"&sms_frnum=${FROM_NUMBER}"\
								-d 	"&sms_tonum=${sms_tonum}"\
								-d	"&sms_text=${SENDING_TEXT}" >> response.txt
	
	# RECORDING LOGS
	echo "" >> response.txt
	echo "$(date '+%Y-%m-%d %H:%M:%S')" >> response.txt
	# echo "" >> response.txt

	last_line=$(tail -n 3 response.txt | head -n 1)
	code_value=$(echo $last_line | jq -r '.Code')

	if [ "$code_value" == "OK" ]; then
		echo "전송완료" >> response.txt
	elif [[ $code_value == *"Error"* ]]; then
		echo "전송실패" >> response.txt
	else
		echo "응답 코드 확인 필요" >> response.txt
	fi

	echo "최종 전송 프로세스 완료"
else

	exit
fi

###### IF YOU WANT TO POST JSON TYPE ######
# for PHONE_NUMBER in ${PHONE_NUMBERS}; do
# 	curl -X POST ${SMS_SERVER} \
# 	-H "Content-Type: application/json" \
# 	-d "{
# 		\"sms_usrid\": \"${USER_ID}\",
# 		\"sms_ackey\": \"${USER_KEY}\",
# 		\"sms_frnum\": \"${FROM_NUMBER}\",
# 		\"sms_tonum\": \"${PHONE_NUMBER}\",
# 		\"sms_text\": \"IT전략팀의 ${PERSON} 님께서 7일 뒤 생일입니다\"
# 	}"
# done
###########################################
