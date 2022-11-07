FROM pm-v4-app:latest AS app

#
# container entrypoint
#
COPY ./container.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

#
# entrypoint
#
CMD ["/usr/local/bin/entrypoint"]
