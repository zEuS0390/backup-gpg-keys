#!/bin/bash

# Print title
printf "\n[[ Export GPG Key ]]\n"

# Disclaimer
echo ">> Disclaimer:"
echo ">> This script is solely intended for exporting GPG keys of a specified user."
echo ">> It is not liable or responsible for any consequences arising from the use or handling of the exported keys."

# Get inputs
read -p ">> User ID*: " user_id
read -p ">> Output Directory*: " output_dir
read -p ">> GPG Key Passphrase*: " -s gpg_passphrase
echo

# Check if the required inputs are not empty
if [ -z "$user_id" ] || [ -z "$output_dir" ] || [ -z $gpg_passphrase ]; then
	echo ">> One or more inputs are empty. Aborted."
	exit 1
fi

# Check if the user's GPG key exist
if ! gpg --list-key "${user_id}" >/dev/null 2>&1; then
	echo ">> GPG key for '${user_id}' does not exist. Aborted."
	exit 1
fi

# Check if the output directory exists
if [ ! -d "${output_dir}" ]; then
	echo ">> '${output_dir}' does not exist."
	echo ">> Attempting to create directory."
	mkdir -p "${output_dir}"
else
	echo ">> '${output_dir}' directory found."
fi

# Verify passphrase
exec 3<<<"${gpg_passphrase}"
gpg --batch --pinentry-mode loopback --passphrase-fd 3 --export-secret-key --local-user "${user_id}" >/dev/null 2>&1
exit_status=$?
exec 3<&-
if [ $exit_status -eq 0 ]; then
	echo ">> The passphrase is correct."
else
	echo ">> The passphrase is incorrect. Aborted."
    rm -rf ${output_dir}
	exit 1
fi

# Export keys
exec 3<<<"${gpg_passphrase}"
gpg --batch --pinentry-mode loopback --passphrase-fd 3 --export --armor --local-user "${user_id}" > ${output_dir}/public.asc
exit_status=$?
exec 3<&-
if [ $exit_status -ne 0 ]; then
	exit 1
fi

exec 3<<<"${gpg_passphrase}"
gpg --batch --pinentry-mode loopback --passphrase-fd 3 --export-secret-keys --local-user "${user_id}" > ${output_dir}/secret.gpg
exit_status=$?
exec 3<&-
if [ $exit_status -ne 0 ]; then
	exit 1
fi

exec 3<<<"${gpg_passphrase}"
gpg --batch --pinentry-mode loopback --passphrase-fd 3 --export-secret-subkeys --local-user "${user_id}" > ${output_dir}/secret_sub.gpg
exit_status=$?
exec 3<&-
if [ $exit_status -ne 0 ]; then
	exit 1
fi

echo ">> Done."

# Wait for user input to exit
read -n 1 -s -r -p ">> Press any key to exit."
echo

# Clean up
unset gpg_passphrase

