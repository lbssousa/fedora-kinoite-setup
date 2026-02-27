#!/usr/bin/env bash

print_banner() {
  echo ""
  echo -e "\033[1;34m"
  cat << 'EOF'
  _____ _ _                _     _
 / ____(_) |              | |   | |
| (___  _| |_   _____ _ __| |__ | |_   _  ___
 \___ \| | \ \ / / _ \ '__| '_ \| | | | |/ _ \
 ____) | | |\ V /  __/ |  | |_) | | |_| |  __/
|_____/|_|_| \_/ \___|_|  |_.__/|_|\__,_|\___|

  ____       _
 / ___|  ___| |_ _   _ _ __
 \___ \ / _ \ __| | | | '_ \
  ___) |  __/ |_| |_| | |_) |
 |____/ \___|\__|\__,_| .__/
                       |_|
EOF
  echo -e "\033[0m"
  echo "  Fedora Silverblue automated desktop setup"
  echo "  https://github.com/johnelliott/silverblue-setup"
  echo ""
}
