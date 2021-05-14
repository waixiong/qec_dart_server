FROM ubuntu

WORKDIR /server
ADD ./bin/server /server/bin/server
# ADD ./static /server/static
# ADD ./config /server/config

WORKDIR /server/bin
EXPOSE 8080

ENTRYPOINT ["./server"]
