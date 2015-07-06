# stats.sql
#
# This file creates a stats database for a web site.
# It should be run whenever a new customer signs up.

create table if not exists Stats
(
    the_date    DATE NOT NULL,
    channel_id  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    report_id   TINYINT UNSIGNED NOT NULL,
    field       TEXT NOT NULL,
    value       INTEGER UNSIGNED NOT NULL,

    KEY         Stats_the_date (the_date),
    KEY         Stats_channel_id (channel_id),
    KEY         Stats_report_id (report_id)
) MAX_ROWS = 4294967296;

create table if not exists Reports
(
    the_date    DATE NOT NULL,
    channel_id  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    report_id   TINYINT UNSIGNED NOT NULL,
    field       TEXT NOT NULL,
    first_times INTEGER UNSIGNED,
    users       INTEGER UNSIGNED,
    visits      INTEGER UNSIGNED,
    hits        INTEGER UNSIGNED,
    mails       INTEGER UNSIGNED,
    bounces     INTEGER UNSIGNED,
    suspect     INTEGER UNSIGNED,
    duration    INTEGER UNSIGNED,
    campaigns   INTEGER UNSIGNED,
    conversions INTEGER UNSIGNED,
    campaign_convs INTEGER UNSIGNED,
    campaign_goals INTEGER UNSIGNED,
    goals       INTEGER UNSIGNED,
    cost        INTEGER UNSIGNED,
    revenue     INTEGER UNSIGNED,

    KEY         Reports_the_date (the_date),
    KEY         Reports_channel_id (channel_id),
    KEY         Reports_report_id (report_id)
) MAX_ROWS = 4294967296;

create table if not exists User
(
    user_id     BIGINT UNSIGNED NOT NULL,
    visit_id    BIGINT UNSIGNED NOT NULL,
    global_id   BIGINT UNSIGNED NOT NULL,
    field       VARCHAR(100) NOT NULL,
    value       VARCHAR(255) NOT NULL,

    KEY         User_user_id (user_id),
    KEY         User_visit_id (visit_id)
) MAX_ROWS = 4294967296;

create table if not exists Visit
(
    visit_id    BIGINT UNSIGNED PRIMARY KEY,
    user_id     BIGINT UNSIGNED NOT NULL,
    global_id   BIGINT UNSIGNED NOT NULL,
    time        INTEGER UNSIGNED NOT NULL,
    duration    SMALLINT UNSIGNED,
    cookies     CHAR(3),
    flash       CHAR(3),
    java        CHAR(3),
    javascript  CHAR(3),
    browser     CHAR(4),
    region      CHAR(2),
    country     CHAR(2),
    language    CHAR(2),
    netspeed    ENUM('unknown', 'dialup', 'cabledsl', 'corporate'),
    latitude    MEDIUMINT,
    longitude   MEDIUMINT,
    time_zone   TINYINT,
    color_bits  TINYINT UNSIGNED,
    resolution  VARCHAR(10),
    op_sys      VARCHAR(10),
    host_ip     VARCHAR(15),
    host        VARCHAR(255),
    city        VARCHAR(255),
    campaign    VARCHAR(255),
    referrer    VARCHAR(255),
    search      VARCHAR(255),
    user_agent  VARCHAR(255),

    KEY         Visit_user_id (user_id),
    KEY         Visit_time (time),
    KEY         Visit_duration (duration)
) MAX_ROWS = 4294967296;

create table if not exists Event
(
    event_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    visit_id    BIGINT UNSIGNED NOT NULL,
    user_id     BIGINT UNSIGNED NOT NULL,
    channel_id  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    type_id     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    refer_id    SMALLINT UNSIGNED,
    msecs       INTEGER UNSIGNED,
    time        INTEGER UNSIGNED NOT NULL,
    name        VARCHAR(255) NOT NULL,
    class       VARCHAR(255),
    referrer    VARCHAR(255),
    description VARCHAR(255),

    KEY         Event_visit_id (visit_id),
    KEY         Event_user_id (user_id),
    KEY         Event_time (time)
) MAX_ROWS = 4294967296;

create table if not exists VisitTemp
(
    visit_id    BIGINT UNSIGNED PRIMARY KEY,
    user_id     BIGINT UNSIGNED NOT NULL,
    global_id   BIGINT UNSIGNED NOT NULL,
    time        INTEGER UNSIGNED NOT NULL,
    duration    SMALLINT UNSIGNED,
    cookies     CHAR(3),
    flash       CHAR(3),
    java        CHAR(3),
    javascript  CHAR(3),
    browser     CHAR(4),
    region      CHAR(2),
    country     CHAR(2),
    language    CHAR(2),
    netspeed    ENUM('unknown', 'dialup', 'cabledsl', 'corporate'),
    latitude    MEDIUMINT,
    longitude   MEDIUMINT,
    time_zone   TINYINT,
    color_bits  TINYINT UNSIGNED,
    resolution  VARCHAR(10),
    op_sys      VARCHAR(10),
    host_ip     VARCHAR(15),
    host        VARCHAR(255),
    city        VARCHAR(255),
    campaign    VARCHAR(255),
    referrer    VARCHAR(255),
    search      VARCHAR(255),
    user_agent  VARCHAR(255),

    KEY         Visit_user_id (user_id),
    KEY         Visit_time (time),
    KEY         Visit_duration (duration)
) MAX_ROWS = 4294967296;

create table if not exists EventTemp
(
    visit_id    BIGINT UNSIGNED NOT NULL,
    user_id     BIGINT UNSIGNED NOT NULL,
    channel_id  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    type_id     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    refer_id    SMALLINT UNSIGNED,
    msecs       INTEGER UNSIGNED,
    time        INTEGER UNSIGNED NOT NULL,
    name        VARCHAR(255) NOT NULL,
    class       VARCHAR(255),
    referrer    VARCHAR(255),
    description VARCHAR(255),

    KEY         Event_visit_id (visit_id),
    KEY         Event_user_id (user_id),
    KEY         Event_time (time)
) MAX_ROWS = 4294967296;

create table if not exists Traffic
(
    visit_id    BIGINT UNSIGNED PRIMARY KEY,
    user_id     BIGINT UNSIGNED NOT NULL,
    time        INTEGER UNSIGNED NOT NULL,
    hits        SMALLINT UNSIGNED NOT NULL,
    duration    SMALLINT UNSIGNED NOT NULL,
    sequence    TEXT NOT NULL,
    classes     TEXT NOT NULL,
    channels    VARCHAR(255) NOT NULL DEFAULT '',
    campaign    VARCHAR(255),
    commerce    VARCHAR(255),

    KEY         Traffic_user_id (user_id),
    KEY         Traffic_time (time)
) MAX_ROWS = 4294967296;

create table if not exists TrafficStats
(
    visit_id    BIGINT UNSIGNED NOT NULL,
    user_id     BIGINT UNSIGNED NOT NULL,
    time        INTEGER UNSIGNED NOT NULL,
    channel_id  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    duration    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    event0      TINYINT UNSIGNED DEFAULT 0,
    event1      TINYINT UNSIGNED DEFAULT 0,
    event2      TINYINT UNSIGNED DEFAULT 0,
    event3      TINYINT UNSIGNED DEFAULT 0,
    event4      TINYINT UNSIGNED DEFAULT 0,
    event5      TINYINT UNSIGNED DEFAULT 0,
    event6      TINYINT UNSIGNED DEFAULT 0,
    event7      TINYINT UNSIGNED DEFAULT 0,
    event8      TINYINT UNSIGNED DEFAULT 0,
    event9      TINYINT UNSIGNED DEFAULT 0,
    event10     TINYINT UNSIGNED DEFAULT 0,
    event11     TINYINT UNSIGNED DEFAULT 0,
    event12     TINYINT UNSIGNED DEFAULT 0,
    event13     TINYINT UNSIGNED DEFAULT 0,
    event14     TINYINT UNSIGNED DEFAULT 0,
    event15     TINYINT UNSIGNED DEFAULT 0,

    PRIMARY KEY TrafficStats_visit_channel (visit_id, channel_id),
    KEY         TrafficStats_user_id (user_id),
    KEY         TrafficStats_time (time),
    KEY         TrafficStats_channel_id (channel_id),
    KEY         TrafficStats_event0 (event0)
) MAX_ROWS = 4294967296;

create table if not exists AdClick
(
    ad_click_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    the_date    DATE NOT NULL,
    provider    CHAR(3) NOT NULL DEFAULT 'GAW',
    impressions INTEGER UNSIGNED NOT NULL DEFAULT 0,
    clicks      INTEGER UNSIGNED NOT NULL DEFAULT 0,
    ccy         CHAR(3) NOT NULL,
    cpc         INTEGER UNSIGNED NOT NULL DEFAULT 0,
    position    FLOAT UNSIGNED NOT NULL DEFAULT 0.0,
    campaign    VARCHAR(255) NOT NULL,
    adgroup     VARCHAR(255) NOT NULL,
    keyword     VARCHAR(255) NOT NULL,

    KEY         AdClick_the_date (the_date, provider)
) MAX_ROWS = 4294967296;

create table if not exists Page
(
    page_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    url         VARCHAR(255) NOT NULL,
    url_thumb   VARCHAR(255),
    last_seen   TIMESTAMP NOT NULL,
    days_seen   INTEGER UNSIGNED NOT NULL DEFAULT 0,
    failures    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    title       VARCHAR(255),
    keywords    TEXT,
    description TEXT,
    content     TEXT,

    KEY         Page_url (url(32)),
    KEY         Page_last_seen (last_seen)
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
