# site.sql
#
# This file creates a site database of web sites being monitored.
# It should be run once, when the statistics server is installed.

create table if not exists Site
(
    site_id         INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reseller_id     INTEGER UNSIGNED NOT NULL,
    url             VARCHAR(255) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,
    product_code    CHAR(1),
    level_code      CHAR(1),
    country_code    CHAR(2),
    status          CHAR(1) NOT NULL DEFAULT 'T',
    time_zone       TINYINT NOT NULL DEFAULT 0,
    report_time     INTEGER UNSIGNED DEFAULT 0,
    comp_server     VARCHAR(255),
    data_server     VARCHAR(255),
    campaign_pages  MEDIUMTEXT,
    commerce_pages  MEDIUMTEXT,
    host_ip_filter  MEDIUMTEXT,
    host_filter     MEDIUMTEXT,
    comments        MEDIUMTEXT,

    KEY             Site_reseller_id (reseller_id),
    KEY             Site_url (url)
) MAX_ROWS = 4294967296;

create table if not exists SiteChannel
(
    site_channel_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id         INTEGER UNSIGNED NOT NULL,
    channel_id      TINYINT UNSIGNED NOT NULL,
    parent_id       TINYINT UNSIGNED NOT NULL DEFAULT 0,
    name            VARCHAR(255) NOT NULL,
    urls            MEDIUMTEXT NOT NULL DEFAULT '',
    titles          MEDIUMTEXT NOT NULL DEFAULT '',

    KEY             SiteChannel_site_id (site_id)
) MAX_ROWS = 4294967296;

create table if not exists SiteConfig
(
    site_config_id  INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id         INTEGER UNSIGNED NOT NULL,
    channel_id      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    report_id       TINYINT UNSIGNED NOT NULL,
    field           VARCHAR(255) NOT NULL,
    value           MEDIUMTEXT NOT NULL DEFAULT '',

    KEY             SiteConfig_site_id (site_id)
) MAX_ROWS = 4294967296;

create table if not exists SiteStats
(
    site_stats_id   INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id         INTEGER UNSIGNED NOT NULL,
    channel_id      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    the_date        DATE NOT NULL,
    period          ENUM('day', 'week', 'month', 'year') NOT NULL,
    users           INTEGER UNSIGNED NOT NULL DEFAULT 0,
    visits          INTEGER UNSIGNED NOT NULL DEFAULT 0,
    hits            INTEGER UNSIGNED NOT NULL DEFAULT 0,
    duration        INTEGER UNSIGNED NOT NULL DEFAULT 0,
    first_times     INTEGER UNSIGNED NOT NULL DEFAULT 0,
    first_times_duration    INTEGER UNSIGNED NOT NULL DEFAULT 0,
    cookies         INTEGER UNSIGNED NOT NULL DEFAULT 0,
    flash           INTEGER UNSIGNED NOT NULL DEFAULT 0,
    java            INTEGER UNSIGNED NOT NULL DEFAULT 0,
    javascript      INTEGER UNSIGNED NOT NULL DEFAULT 0,
    spider_visits   INTEGER UNSIGNED NOT NULL DEFAULT 0,

    KEY             SiteStats_site_id (site_id),
    KEY             SiteStats_the_date (the_date)
) MAX_ROWS = 4294967296;

create table if not exists Account
(
    account_id      INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reseller_id     INTEGER UNSIGNED NOT NULL,
    parent_id       INTEGER UNSIGNED NOT NULL DEFAULT 0,
    status          CHAR(1) NOT NULL DEFAULT 'A',
    start_date      DATE NOT NULL,
    end_date        DATE,
    realname        VARCHAR(255) NOT NULL,
    username        VARCHAR(255) NOT NULL,
    password        VARCHAR(255) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    referrer        MEDIUMTEXT,
    comments        MEDIUMTEXT,

    KEY             Account_reseller_id (reseller_id),
    KEY             Account_parent_id (parent_id),
    KEY             Account_username (username)
) MAX_ROWS = 4294967296;

create table if not exists SiteAccount
(
    site_account_id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    site_id         INTEGER UNSIGNED NOT NULL,
    channel_id      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    account_id      INTEGER UNSIGNED NOT NULL,
    can_read        ENUM('yes','no') NOT NULL DEFAULT 'yes',
    can_write       ENUM('yes','no') NOT NULL DEFAULT 'yes',
    get_reports     VARCHAR(255) NOT NULL DEFAULT '1, 0',
    get_periods     VARCHAR(255) NOT NULL DEFAULT 'week, month',
    status          CHAR(1) NOT NULL DEFAULT 'A',

    KEY             SiteAccount_site_id (site_id),
    KEY             SiteAccount_channel_id (channel_id),
    KEY             SiteAccount_account_id (account_id)
) MAX_ROWS = 4294967296;

create table if not exists GridJob
(
    grid_job_id     INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    priority        TINYINT UNSIGNED NOT NULL DEFAULT 100,
    command         VARCHAR(255) NOT NULL,
    result          TEXT,
    submit_time     INTEGER UNSIGNED DEFAULT 0,
    start_time      INTEGER UNSIGNED DEFAULT 0,
    finish_time     INTEGER UNSIGNED DEFAULT 0,
    comp_server     VARCHAR(255),
    job_server      VARCHAR(255),
    status          CHAR(1) NOT NULL DEFAULT 'A'
) MAX_ROWS = 4294967296;

create table if not exists WhoIs
(
    who_is_id       INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    timestamp       TIMESTAMP NOT NULL,
    domain          VARCHAR(255) NOT NULL,
    url_thumb       VARCHAR(255),
    details         TEXT,
    status          CHAR(1) NOT NULL DEFAULT 'A',

    KEY             WhoIs_domain (domain)
) MAX_ROWS = 4294967296;

create table if not exists APIToken
(
    api_token_id    INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id      INTEGER UNSIGNED NOT NULL,
    token_text      VARCHAR(255) NOT NULL,
    call_count      INTEGER UNSIGNED NOT NULL DEFAULT 0,
    call_limit      INTEGER UNSIGNED NOT NULL DEFAULT 0,
    start_date      DATE,
    end_date        DATE,
    status          CHAR(1) NOT NULL DEFAULT 'A',

    KEY             APIToken_account_id (account_id),
    KEY             APIToken_token_text (token_text)
) MAX_ROWS = 4294967296;

create table if not exists Reseller
(
    reseller_id     INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id      INTEGER UNSIGNED NOT NULL,
    contact         VARCHAR(255) NOT NULL,
    company         VARCHAR(255) NOT NULL,
    street1         VARCHAR(255) NOT NULL,
    street2         VARCHAR(255),
    city            VARCHAR(40) NOT NULL,
    country         VARCHAR(40) NOT NULL,
    zip_code        VARCHAR(40),
    tel_number      VARCHAR(40),
    fax_number      VARCHAR(40),
    vat_number      VARCHAR(40),
    url             VARCHAR(40) NOT NULL,
    email           VARCHAR(40) NOT NULL,
    brand           VARCHAR(40) NOT NULL,

    KEY             Reseller_account_id (account_id)
) MAX_ROWS = 4294967296;

/**************************************************************
Copyright (c) 2015 Legendum Ltd (UK)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
**************************************************************/
