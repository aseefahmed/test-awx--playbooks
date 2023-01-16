sudo apt purge --auto-remove unattended-upgrades -y
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl mask apt-daily-upgrade.service
sudo systemctl disable apt-daily.timer
sudo systemctl mask apt-daily.service
sudo sed -e '/exec \/usr\/lib\/apt\/apt.systemd.daily/ s/^#*/#/' -i /etc/cron.daily/apt-compat
