FROM dart:2.17.3
WORKDIR /app/
COPY ./ .
RUN dart pub get
EXPOSE 8888
EXPOSE 8889
EXPOSE 8890
EXPOSE 8891
EXPOSE 8892
CMD ["dart", "run", "/app/bin/main.dart"]