#!/bin/bash
passenger-config restart-app $(pwd)
sudo service nginx restart
