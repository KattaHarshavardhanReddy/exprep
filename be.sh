#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-log"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){

    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}


echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "disable old nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "enable new nodejs"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "install nodejs"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense
    VALIDATE $? "add user"
else
    echo -e "user added already ...$Y skipping$N"
fi
#useradd expense &>>$LOG_FILE_NAME
#VALIDATE $? "add user"

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "create app "

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "dwnld be "

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip file"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "install npm"

cp /home/ec2-user/exprep/be.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.katta.blog -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting Backend"

