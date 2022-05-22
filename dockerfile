FROM postgres

WORKDIR ./

EXPOSE 5432 

RUN sudo su -postres; \i ./database/creation.sql;\c exval; ./settings.sql;  \q





