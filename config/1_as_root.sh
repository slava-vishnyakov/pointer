#!/bin/bash -e

source `dirname $0`/variables.sh

if ! id -u $RAILS_USER >/dev/null 2>&1; then
  echo "Create rails user: $RAILS_USER"
  useradd rails -d /home/$RAILS_USER -m -s /bin/bash
  usermod -a -G sudo $RAILS_USER
fi

SSH_DIR="/home/$RAILS_USER/.ssh"
AUTHORIZED_KEYS_FILE="$SSH_DIR/authorized_keys"

# def upload_public_key
if [[ ! -e $SSH_DIR ]]; then
  mkdir $SSH_DIR
  chown $RAILS_USER:$RAILS_USER $SSH_DIR
  chmod 0700 $SSH_DIR
fi

if [[ ! -e $AUTHORIZED_KEYS_FILE ]]; then
  touch $AUTHORIZED_KEYS_FILE
  chown $RAILS_USER:$RAILS_USER $AUTHORIZED_KEYS_FILE
  chmod 0600 $AUTHORIZED_KEYS_FILE
fi

echo "Uploading private key"
cat $PUBLIC_KEY >> $AUTHORIZED_KEYS_FILE

echo "Give sudo rights"
echo "$RAILS_USER ALL = NOPASSWD:ALL" >> /etc/sudoers
