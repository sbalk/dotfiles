sudo cryptsetup --type luks open /dev/sda1 encrypted
sudo mount -t ext4 /dev/mapper/encrypted /media/usb
