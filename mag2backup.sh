#!/usr/bin/bash

# Remote FTP Variables
ftp_server='<server_address>'
ftp_username='<server_username>'
ftp_password='<server_password>'
ftp_port='21'
ftp_directory='<server_path>'

# Magento install Variables
mag_path='<path_to_magento_root>'
mag_backups=$mag_path'/var/backups'

# Days backup to keep
backup_days=7

# Path to PHP
php='/usr/local/php70/bin/php-cli -d set_time_limit=3600 -d memory_limit=2048M'

# DO NOT EDIT
weekday=$(date +"%u")

if [[ -d "$mag_backups" ]]; then
rm -r $mag_backups/*
fi

if [[ $weekday -eq 1 ]]; then
$php $mag_path/bin/magento setup:backup --code --media --db
else
$php $mag_path/bin/magento setup:backup --db
fi

ncftpput -R -u $ftp_username -p $ftp_password $ftp_server $ftp_directory $mag_backups/*

old_files=$(ncftpls -u $ftp_username -p $ftp_password -F -g ftp://$ftp_server$ftp_directory)

oldIFS="$IFS"
IFS='
'
IFS=${IFS:0:1} # this is useful to format your code with tabs
lines=($oldfiles)
IFS="$oldIFS"
for line in "${lines[@]}"; do
  nline=${line%_*}
  filedate=${nline%_*}
  lastweek=`date -d "- $backup_days days" +%s`
  if [[ $filedate < $lastweek ]]; then
    old_backups=$old_backups$line" "
  fi
done

ncftp -u $ftp_username -p $ftp_password ftp://$ftp_server << EOF
cd $ftp_directory
rm $old_backups
quit
EOF

if [[ -d "$mag_backups" ]]; then
rm -r $mag_backups/*
fi
