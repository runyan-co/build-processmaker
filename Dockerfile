FROM pm-v4-app:latest AS app

#
# container entrypoint
#
COPY ./container.sh /usr/local/bin/entrypoint
RUN chmod 755 /usr/local/bin/entrypoint

#
# entrypoint
#
CMD ["/usr/local/bin/entrypoint"]
