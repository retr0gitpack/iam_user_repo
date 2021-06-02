#!/bin/bash

# This script will remove the IAM user from a particular AWS account

SCRIPT_NAME=$(basename $0)
usage () {
echo '
Usage: '"$SCRIPT_NAME"' "USERNAME" "AWS PROFILE NAME"

E.g.
'"$SCRIPT_NAME"' cb-varun some-random-aws-profile

Note: 
	- The username should not contain any special characters (except hyphen, -; tested)
	- The script follows the rule of AWS on deleting IAM User.
	- Test and use at your own risk, although I have tested this at my end without any issues.
'
}

if [ "$#" -ne 2 ]; then
	usage
else
	# Set the alias
	alias aws=''`which aws`' --profile '"$2"' --output text'
	shopt -s expand_aliases

	# User name is the argument to the script
	USER_NAME=test2

	# remove Access keys
	ACC_KEY=$(aws iam list-access-keys --user-name "$USER_NAME" --output text --query 'AccessKeyMetadata[*].AccessKeyId')
	if [ ! -z "$ACC_KEY" ]; then
		echo "$ACC_KEY" | while read -r KEY_LIST; do
			aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$KEY_LIST"
		done
	fi

	# remove certificates
	CERT_ID=$(aws iam list-signing-certificates --user-name "$USER_NAME" --output text --query 'Certificates[*].CertificateId')
	if [ ! -z "$CERT_ID" ]; then
		echo "$CERT_ID" | while read -r CERT_LIST; do
			aws iam delete-signing-certificate --user-name "$USER_NAME" --certificate-id "$CERT_LIST"
		done
	fi

	# remove login profile/password
	aws iam delete-login-profile --user-name "$USER_NAME"

	# remove MFA devices
	MFA_ID=$(aws iam list-mfa-devices --user-name "$USER_NAME" --query 'MFADevices[*].SerialNumber')
	if [ ! -z "$MFA_ID" ]; then
		echo "$MFA_ID" | while read -r MFA_LIST; do
			aws iam deactivate-mfa-device --user-name "$USER_NAME" --serial-number "$MFA_LIST"
		done
	fi

	# detach user policies
	USER_POLICY=$(aws iam list-attached-user-policies --user-name "$USER_NAME" --query 'AttachedPolicies[*].PolicyArn')
	if [ ! -z "$USER_POLICY" ]; then
		echo "$USER_POLICY" | while read -r POLICIES; do
			aws iam detach-user-policy --user-name "$USER_NAME" --policy-arn "$POLICIES"
		done
	fi

	# remove user from groups
	GRP_NAME=$(aws iam list-groups-for-user --user-name "$USER_NAME" --query 'Groups[*].GroupName' | tr -s '\t' '\n')
	if [ ! -z "$GRP_NAME" ]; then
		echo "$GRP_NAME" | while read -r GRP; do
			aws iam remove-user-from-group --user-name "$USER_NAME" --group-name "$GRP"
		done
	fi

	# delete the user
	aws iam delete-user --user-name "$USER_NAME"

	# unset the alias
	unalias aws
fi