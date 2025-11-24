[ ] 1) mac-dev-playbook
    - config.yml regenerated (your script run)
    - git status clean, pushed to origin master

[ ] 2) chezmoi
    - chezmoi source-path: git status clean
    - all changes committed and pushed

[ ] 3) SSH keys
    - Encrypted backup created:
      tar czf ssh-backup.tar.gz .ssh
      gpg -c ssh-backup.tar.gz
      rm ssh-backup.tar.gz
    - ssh-backup.tar.gz.gpg stored in Bitwarden / Nextcloud

[ ] 4) Nextcloud
    - Nextcloud client working
    - ~/Nextcloud/Documents fully synced
    - ~/Documents -> symlink to ~/Nextcloud/Documents
    - No secrets (like ~/.ssh) inside ~/Nextcloud

[ ] 5) Important app data
    - Parallels: all .pvm files copied somewhere safe
    - RustDesk: config backed up (export string or RustDesk2.toml)
    - Libation (and similar): library plus any DB you care about backed up

[ ] 6) Other personal data
    - Anything important outside Documents (projects, code, media, etc.) is:
      - in Git, OR
      - in Nextcloud, OR
      - in another backup

[ ] 7) Access after reinstall
    - Bitwarden login plus 2FA ready
    - Apple ID / email / GitHub 2FA not locked behind only this Mac

[ ] 8) Before wiping the old Mac (Geerling-style)
    - Sign out of Adobe Creative Cloud / Panic Sync / deauthorize Apple Music
    - Make sure any new fonts, Motion/FCP plugins, Sequel Ace favorites, etc.
      are merged into your Nextcloud/config backup
    - Follow Apple’s official “prepare Mac for sale or trade-in” erase guide
      (the HT212749 page Jeff links in his tutorial)
