#!/bin/bash

# Print title
printf "\n[[ Export GPG Key ]]\n"

# Disclaimer
echo ">> Disclaimer:"
echo ">> This script is solely intended for exporting GPG keys of a specified user."
echo ">> It is not liable or responsible for any consequences arising from the use or handling of the exported keys."

# Get inputs
read -p ">> User ID*: " user_id
read -p ">> Source Directory*: " source_dir
read -p ">> GPG Key Passphrase*: " -s gpg_passphrase
echo

# Check if the required inputs are not empty
if [ -z $user_id ] || [ -z $source_dir ] || [ -z $gpg_passphrase ]; then
	echo ">> One or more inputs are empty. Aborted."
	exit 1
fi

# Check if the user's GPG key exist
if ! gpg --list-key ${user_id} >/dev/null 2>&1; then
	echo ">> GPG key for '${user_id}' does not exist. Aborted."
	exit 1
fi

# Check if the source directory exists
if [ ! -d ${source_dir} ]; then
	echo ">> '${source_dir}' does not exist."
	echo ">> Attempting to create directory."
	mkdir -p ${source_dir}
else
	echo ">> '${source_dir}' directory found."
fi

# Verify passphrase
gpg --batch --pinentry-mode loopback --passphrase "${gpg_passphrase}" --local-user ${user_id} --export-secret-key >/dev/null 2>&1
exit_status=$?

if [ $exit_status -eq 0 ]; then
	echo ">> The passphrase is correct."
else
	echo ">> The passphrase is incorrect. Aborted."
	exit 1
fi

# Export keys
gpg --batch --pinentry-mode loopback --passphrase "${gpg_passphrase}" --export --armor --local-user "${user_id}" > ${source_dir}/public.asc
gpg --batch --pinentry-mode loopback --passphrase "${gpg_passphrase}" --export-secret-keys --local-user "${user_id}" > ${source_dir}/secret.key
gpg --batch --pinentry-mode loopback --passphrase "${gpg_passphrase}" --export-secret-subkeys --local-user "${user_id}" > ${source_dir}/secret_sub.key
gpg --batch --pinentry-mode loopback --passphrase "${gpg_passphrase}" --export-ownertrust > ${source_dir}/ownertrust.txt
echo ">> Done."

# Wait for user input to exit
read -n 1 -s -r -p ">> Press any key to exit."
echo
