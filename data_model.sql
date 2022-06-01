-- tested on postgresql version:
--SELECT version();
--PostgreSQL 12.6 on x86_64-pc-linux-musl, compiled by gcc (Alpine 10.2.1_pre1) 10.2.1 20201203, 64-bit

CREATE SCHEMA IF NOT EXISTS example;

CREATE TABLE IF NOT EXISTS example.tab_users
(
    id_user INTEGER CONSTRAINT pk_id_user PRIMARY KEY,
    user_name TEXT
);

CREATE TABLE IF NOT EXISTS example.tab1
(
    id_tab1  INTEGER CONSTRAINT pk_id_tab1 PRIMARY KEY,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab1_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab10
(
    id_tab10  INTEGER CONSTRAINT pk_id_tab10 PRIMARY KEY,
    id_tab1  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab10_idtab1 FOREIGN KEY (id_tab1)
        REFERENCES example.tab1 (id_tab1) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab10_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab11
(
    id_tab11  INTEGER CONSTRAINT pk_id_tab11 PRIMARY KEY,
    id_tab1  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab11_idtab1 FOREIGN KEY (id_tab1)
        REFERENCES example.tab1 (id_tab1) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab11_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);


CREATE TABLE IF NOT EXISTS example.tab12
(
    id_tab12  INTEGER CONSTRAINT pk_id_tab12 PRIMARY KEY,
    id_tab1  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab12_idtab1 FOREIGN KEY (id_tab1)
        REFERENCES example.tab1 (id_tab1) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab12_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);


CREATE TABLE IF NOT EXISTS example.tab20
(
    id_tab20  INTEGER CONSTRAINT pk_id_tab20 PRIMARY KEY,
    id_tab10  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab20_idtab10 FOREIGN KEY (id_tab10)
        REFERENCES example.tab10 (id_tab10) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab20_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab21
(
    id_tab21  INTEGER CONSTRAINT pk_id_tab21 PRIMARY KEY,
    id_tab10  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab21_idtab10 FOREIGN KEY (id_tab10)
        REFERENCES example.tab10 (id_tab10) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab21_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab22
(
    id_tab22  INTEGER CONSTRAINT pk_id_tab22 PRIMARY KEY,
    id_tab1   INTEGER,
    id_tab10  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab22_idtab1 FOREIGN KEY (id_tab1)
        REFERENCES example.tab1 (id_tab1) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab22_idtab10 FOREIGN KEY (id_tab10)
        REFERENCES example.tab10 (id_tab10) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab22_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab23
(
    id_tab23  INTEGER CONSTRAINT pk_id_tab23 PRIMARY KEY,
    id_tab12  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab23_idtab12 FOREIGN KEY (id_tab12)
        REFERENCES example.tab12 (id_tab12) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab23_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab30
(
    id_tab30  INTEGER CONSTRAINT pk_id_tab30 PRIMARY KEY,
    id_tab20  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab30_idtab20 FOREIGN KEY (id_tab20)
        REFERENCES example.tab20 (id_tab20) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab30_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS example.tab31
(
    id_tab31  INTEGER CONSTRAINT pk_id_tab31 PRIMARY KEY,
    id_tab21  INTEGER,
    id_tab22  INTEGER,
    id_last_modified_by_user INTEGER,
    CONSTRAINT fk_tab31_idtab21 FOREIGN KEY (id_tab21)
        REFERENCES example.tab21 (id_tab21) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab31_idtab22 FOREIGN KEY (id_tab22)
        REFERENCES example.tab22 (id_tab22) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_tab31_idlastmodifiedbyuser FOREIGN KEY (id_last_modified_by_user)
        REFERENCES example.tab_users (id_user) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);


