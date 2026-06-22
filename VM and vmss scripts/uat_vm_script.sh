#!/bin/bash

HOST="xxx"
USER="xxx"
PASS="xxx"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER@$HOST"

