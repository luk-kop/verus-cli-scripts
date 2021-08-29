# Verus CLI scripts 

[![Python 3.8.5](https://img.shields.io/badge/python-3.8.5-blue.svg)](https://www.python.org/downloads/release/python-377/)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

> The **Verus CLI scripts** project provides scripts useful for status monitoring and basic management of your **Verus Coin (VRSC)** cryptocurrency wallet on **Linux OS**.


## Features
* Scripts in repository can be divided into two groups:
  * **state monitoring** scripts (new stake, block check etc., `monitor_script` directory)
  * **daily usage** scripts - for day-to-day use cases (check balance, make transaction etc., `daily_scripts` directory).
* The **state monitoring** scripts should be run at regular intervals on the machine running the VRSC wallet (with `crond` or `systemd` timer):
  * `check_new_stake.sh` - the script sends email notification to specified email address, if a new stake (reward) arrives, 
  * `check_block.py` - the script sends an e-mail, if the local VRSC wallet block count is not close to the number of blocks in [Verus explorer](https://explorer.verus.io/).
* The **daily usage scripts** can be used if necessary:
  * `balance.sh` - gets your current VRSC wallet balance.
  * `shield.sh` - moves rewards to private address (`PRIVATE_VRSC_ADDRESS`). Shielding is not required but useful for consolidating the rewards.
  * `unshield.sh` - moves coins from VRSC private address (z-address) to VRSC public address (R-address).
  * `getmininginfo.sh` - gets mining-related information.
  * `getwalletinfo.sh` - gets info about your wallet (immature & staking) balances.
* The email notification can be temporarily disabled by changing the env variable `EMAIL_NOTIFICATION` to `"off"` in the `.env` file  (useful during wallet upgrade or maintenance).
* Scripts get data from API of running `verud` daemon.
* The email address to be notified of a new stake is stored in `.env` file (`EMAIL_TO_NOTIFY`).
* The orphan stakes and new transactions (transferring cryptocurrency from/to wallet) are not counted.

## Getting Started

Below instructions will get you a copy of the project running on your local machine.

### Requirements
Python third party packages:
* [requests](https://docs.python-requests.org/en/master/)
* [python-dotenv](https://pypi.org/project/python-dotenv/)

Linux packages:
* [bc](https://www.gnu.org/software/bc/) (`apt install -y bc` or `yum install -y bc`)
* [mailutils](https://mailutils.org/) (`apt install -y mailutils` or `yum install -y mailx postfix`)
* [git](https://git-scm.com/download/linux) (`apt install -y git` or `yum install -y git`)
* [pip3](https://pip.pypa.io/en/stable/) (`apt install -y python3-pip` or `yum install -y python3-pip`)
* [jq](https://stedolan.github.io/jq/) (`apt install -y jq` or `yum install -y jq`)
> **Note**: With RHEL or CentOS distributions `jq` (JSON Processor) utility is available through EPEL Repository, so to install `jq` you need to first install EPEL Repository by using `yum install epel-release -y` command. 

Other prerequisites:
* The **Verus Coin (VRSC) CLI wallet** running on some Linux distribution. You can find appropriate wallet binaries on Verus Coin (VRSC) project website - [Verus wallet](https://verus.io/wallet/command-wallet).
* VRSC wallet binaries should be downloaded and extracted in user home directory (example after tarball extracted - `/home/username/verus-cli`)
* The `Postfix` service (part of `mailutils` package) should be configured as a Send-Only SMTP Server for email notifications.

## Build and run the application
1. Clone git repository to user home directory and enter `verus-cli-scripts` directory.
    ```bash
    $ cd ~
    $ git clone https://github.com/luk-kop/verus-cli-scripts.git
    $ cd verus-cli-scripts/
    ```
2. Run following commands in order to create virtual environment (`virtualenv`) and install the required packages (only necessary for `check_block.py` script).
    ```bash
    # create virtual environment with 'venv' name
    $ python3 -m venv venv
    # activate 'venv'
    $ source venv/bin/activate
    # install required Python packages
    (venv) $ pip install -r requirements.txt
    # deactivate virtual environment after packages installation
    (venv) $ deactivate
    ```

3. Before running the application you should create `.env` file in the root app directory (`verus-cli-scripts`). The best solution is to copy the existing example file `.env-example` and edit the necessary data.
    ```bash
    $ cp .env-example .env
    ```

4. The **state monitoring** scripts should be configured as **cronjobs**. An example configuration can be found below:
    ```bash
    $ crontab -e
    ```
    Add following lines to the `crontab` (please change your `username` accordingly):
    ```bash
    # crontab example:
    */15 * * * * /home/username/verus-cli-scripts/monitor_scripts/check_new_stake.sh
    */30 * * * * /home/username/verus-cli-scripts/venv/bin/python /home/username/verus-cli-scripts/monitor_scripts/check_block.py
    ```
5. To simplify the usage of the **daily usage scripts**, you can create symlinks (symbolic links) for particular scripts.
    ```bash
    $ mkdir -p ~/bin
    $ ln -s ~/verus-cli-scripts/daily_scripts/balance.sh ~/bin/vrsc-balance
    $ ln -s ~/verus-cli-scripts/daily_scripts/shield.sh ~/bin/vrsc-shield
    # and so on ...
    ```
    > **Note**: Remember to add `~/bin` directory to your `$PATH` variable (if it is not already added).