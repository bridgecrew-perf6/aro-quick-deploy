#!/bin/bash
subscription_id=$1

az ad sp create-for-rbac \
-n "MyApp" \
--role Contributor \
--scopes /subscriptions/$subscription_id