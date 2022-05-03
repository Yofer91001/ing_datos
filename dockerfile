FROM postres

WORKDIR /

EXPOSE 5432 

RUN sudo su -postres; \i ./databas/db.sql; \q





