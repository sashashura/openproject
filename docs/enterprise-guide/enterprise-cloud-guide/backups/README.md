---
sidebar_navigation:
  title: Backups
  priority: 710
description: Backups in the cloud edition.
keywords: backups
---

# Backups

Your Enterprise cloud data is backed up continuously and retained for 30 days.
Within those 30 days we can restore your data to any point in time with a precision of 5 minutes, in case you need us to.

## Download

You can yourself create backups of your OpenProject installation. Go to *Administration* and *Backup* to get started.

![administration-backup](administration-backup-2034314.png)

You will then need to create a backup token by clicking **+ Backup token**.

![create-backup-token](create-backup-token.png)

The system generates the token which you then fill in where requested in the field below.

![backup-code](backup-code.png)

After having **requested the backup**, you will receive an email notification with a link to download your backup. For this, you will need additional authentication (username and password as well as 2-Factor-Authentication if activated) to download the backup files.

In case you have trouble creating your backup, please [get in touch](mailto:support@openproject.com) with us. We can then provide a current or past backup (database + attachments) to you.

This way you can also get your data if you decide to stop using the Enterprise cloud edition.

## Pull a backup via APIv3

It is sometimes good to have backups on other locations (e.g. local vs cloud). You are able to pull a backup via the APIv3 in OpenProject.

*Preconditions:*

1. The Token must be already generated and stored in a secure keystore
2. The API Key must be known and stored in a secure keystore

You could use our [example bash script](./script/backup-via-apiv3.sh) and integrate it in your crond for running it daily.
