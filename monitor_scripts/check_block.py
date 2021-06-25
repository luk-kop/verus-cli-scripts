#!/usr/bin/env python3
import subprocess
import sys
import os
from pathlib import Path
import logging
from logging.handlers import RotatingFileHandler
import json

import requests
from dotenv import dotenv_values


def send_mail(title:str, content:str, address:str):
    """
    Function sends notification msg to specified email address.
    """
    bash_cmd = [f'echo "{content}" | mail -s "{title}" {address}']
    subprocess.run(bash_cmd, shell=True)


def get_verus_dir_path():
    """
    Returns verus_cli dir path if exists.
    """
    path = Path.home().joinpath('verus-cli')
    if not path.exists() or not path.is_dir():
        logger.error(f'Directory {path} not exists!')
        sys.exit()
    return path.resolve()


def get_env_path():
    """
    Return .env file path if exists.
    """
    path = Path(__file__).resolve().parents[1].joinpath('.env')
    if not path.exists() or not path.is_file():
        logger.error(f'File {path} not exists!')
        sys.exit()
    return path


def create_log():
    """
    Creates rotating log for script.
    """
    verus_logs_dir = (Path.home().joinpath('verus-logs'))
    if not verus_logs_dir.exists():
        os.mkdir(verus_logs_dir)
    block_log_file = verus_logs_dir.joinpath('block.log').resolve()
    logger_custom = logging.getLogger("Verus Log")
    handler = RotatingFileHandler(block_log_file, maxBytes=10000, backupCount=5)
    formatter = logging.Formatter('%(asctime)s %(message)s')
    handler.setFormatter(formatter)
    logger_custom.addHandler(handler)
    logger_custom.setLevel(logging.INFO)
    return logger_custom


if __name__ == '__main__':
    # URL to VRSC Explorer API server.
    url_explorer_block_count = 'https://explorer.veruscoin.io/api/getblockcount'

    # Logging config
    logger = create_log()

    # Get .env file path.
    env_path = get_env_path()

    # Load data from .env file
    env_data = dotenv_values(env_path)
    email_address = env_data.get('EMAIL_TO_NOTIFY')
    email_notification = env_data.get('EMAIL_NOTIFICATION')
    if not email_address:
        logger.error('The EMAIL_TO_NOTIFY in .env is missing.')
        sys.exit()
    if not email_notification or not email_notification == 'on':
        logger.info(f'The email notification is turned off. Check EMAIL_NOTIFICATION value in .env.')
        sys.exit()

    # Get verus_cli dir path.
    verus_dir_path = get_verus_dir_path()

    # Check local wallet block count. Local data in JSON.
    try:
        result = subprocess.getoutput(f'{verus_dir_path.resolve()}/verus getmininginfo')
        result_dict = json.loads(result)
        wallet_block = result_dict['blocks']
    except (json.decoder.JSONDecodeError, KeyError, AttributeError):
        email_title = 'Local wallet problem'
        email_content = 'Script "check_block.py" can\'t get access to "verusd".'
        send_mail(email_title, email_content, email_address)
        logger.error(email_content)
        sys.exit()

    # Make an API call to VRSC Explorer.
    try:
        api_call = requests.get(url_explorer_block_count)
        api_call.raise_for_status()
        api_call_text = api_call.text
    except (requests.exceptions.ConnectionError, requests.exceptions.HTTPError):
        email_title = 'VRSC Explorer API connection issue'
        email_content = f'Script "check_block.py" can\'t connect with VRSC Explorer API.\n' \
                        f'API URL: {url_explorer_block_count}'
        send_mail(email_title, email_content, email_address)
        logger.error(f'Script "check_block.py" can\'t connect with VRSC Explorer API. '
                     f'API URL: {url_explorer_block_count}')
        sys.exit()

    # Send notification if API requested data is not integer (data is string not JSON)
    try:
        explorer_block = int(api_call_text)
    except ValueError:
        email_title = 'VRSC Explorer API connection issue'
        email_content = f'API response text is not integer.\nAPI Response: "{api_call_text}"'
        send_mail(email_title, email_content, email_address)
        logger.error(f'API response text is not integer. API Response: "{api_call_text}"')
        sys.exit()

    # Send notification if the difference between the values of the blocks height is greater than 10.
    if abs(explorer_block - wallet_block) > 10:
        email_title = 'Block height issue'
        email_content = f'The block height in the VPS wallet is different than on the VRSC Explorer!\n' \
                        f'\nBlock height - VPS wallet: {wallet_block}\nBlock height - VRSC Explorer: {explorer_block}'
        send_mail(email_title, email_content, email_address)
        logger.error(f'Block height issue. Explorer: {explorer_block}, local wallet: {wallet_block}')
        sys.exit()
