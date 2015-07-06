-- stats.odbc.sql
--
-- This file creates a stats database for a web site.
-- It should be run whenever a new customer signs up.

create table Visit
(
    visit_id    BIGINT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    global_id   BIGINT NOT NULL,
    time        INTEGER NOT NULL,
    cookies     CHAR(3),
    flash       CHAR(3),
    java        CHAR(3),
    javascript  CHAR(3),
    browser     CHAR(4),
    region      CHAR(2),
    country     CHAR(2),
    language    CHAR(2),
    netspeed    NVARCHAR(10),
    latitude    INTEGER,
    longitude   INTEGER,
    time_zone   SMALLINT,
    color_bits  SMALLINT,
    resolution  NVARCHAR(10),
    op_sys      NVARCHAR(10),
    host_ip     NVARCHAR(15),
    host        NVARCHAR(255),
    city        NVARCHAR(255),
    campaign    NVARCHAR(255),
    referrer    NVARCHAR(255),
    search      NVARCHAR(255),
    user_agent  NVARCHAR(255)
)
GO
CREATE INDEX Visit_user_id on Visit (user_id ASC)
GO
CREATE INDEX Visit_global_id on Visit (global_id ASC)
GO
CREATE INDEX Visit_time on Visit (time ASC)
GO

create table Event
(
    event_id    BIGINT PRIMARY KEY,
    visit_id    BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    channel_id  SMALLINT NOT NULL DEFAULT 0,
    type_id     SMALLINT NOT NULL DEFAULT 0,
    refer_id    SMALLINT,
    msecs       INTEGER,
    time        INTEGER NOT NULL,
    name        NVARCHAR(255) NOT NULL,
    class       NVARCHAR(255),
    referrer    NVARCHAR(255),
    description NVARCHAR(255)
)
GO
CREATE INDEX Event_user_id on Event (user_id ASC)
GO
CREATE INDEX Event_visit_id on Event (visit_id ASC)
GO
CREATE INDEX Event_time on Event (time ASC)
GO

-- End of stats.odbc.sql --

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
