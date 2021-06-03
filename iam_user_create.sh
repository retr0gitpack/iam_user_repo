#!/bin/bash

user=test2

pass=Omrontest!@

policy=arn:aws:iam::aws:policy/AmazonS3FullAccess

group=Restricted_Group

echo "User: $user"

aws iam create-user --user-name $user

aws iam attach-user-policy --user-name $user --policy-arn $policy

aws iam add-user-to-group --user-name $user --group-name $group

sleep 10

aws iam update-login-profile --user-name $user --password $pass --password-reset-required